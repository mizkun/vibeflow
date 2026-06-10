#!/usr/bin/env python3
from __future__ import annotations
"""
VibeFlow Structured Spec Verification Engine (v6)

Static verification of the structured spec (Story / Contract) against the repo.
Catches the failure mode v6 exists to fix: spec that has silently drifted away
from the code it describes.

Checks performed:
- Structure   — required fields present, id matches filename, invariants well-formed
- References  — contract.story / story.depends_on resolve to existing stories
- Drift       — source_files / source_ref / test / producers / consumers paths exist
- Stats       — counts invariants and how many are still pending (untested)

Running the invariant tests themselves (verified vs failing) is a dynamic concern
handled by the HealthCheck / PR-gate layer; this engine reports which tests exist.
"""

import ast
import json
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None


# Canonical definitions live in core/schema/spec.yaml — these constants
# must mirror it. Sync is enforced by tests/test_spec_schema_consistency.sh.
STORY_REQUIRED = ["id", "one_liner", "invariants", "source_files"]
CONTRACT_REQUIRED = ["id", "schema_ref", "producers", "consumers", "story"]
INVARIANT_REQUIRED = ["id", "text"]


def load_spec(spec_dir: str) -> dict:
    """Load every Story and Contract file under spec_dir.

    Returns {"stories": {stem: data}, "contracts": {stem: data},
             "parse_errors": [str]}.
    """
    base = Path(spec_dir)
    result = {"stories": {}, "contracts": {}, "parse_errors": []}

    for kind, subdir in (("stories", "stories"), ("contracts", "contracts")):
        d = base / subdir
        if not d.is_dir():
            continue
        for path in sorted(d.glob("*.yaml")):
            try:
                data = yaml.safe_load(path.read_text(encoding="utf-8"))
            except Exception as exc:  # noqa: BLE001 — surface any parse failure
                result["parse_errors"].append(f"{path.name}: parse error: {exc}")
                continue
            if not isinstance(data, dict):
                result["parse_errors"].append(
                    f"{path.name}: top-level content is not a mapping"
                )
                continue
            result[kind][path.stem] = data
    return result


def _path_exists(repo_root: str, rel: str) -> bool:
    return (Path(repo_root) / rel).exists()


# Marker files that don't count as "implementation exists"
_PLACEHOLDER_NAMES = {".gitkeep", ".keep", ".DS_Store"}


def _dir_is_empty_placeholder(repo_root: str, rel: str) -> bool:
    """True if rel is a directory containing no real files (recursively).

    A Story whose source_files point at an empty directory is a
    placeholder for unimplemented work — it must not pass as As-Is
    spec. The check is recursive so a parent-directory reference with
    nested implementation files is not a false positive.
    """
    p = Path(repo_root) / rel
    if not p.is_dir():
        return False
    for child in p.rglob("*"):
        if child.is_file() and child.name not in _PLACEHOLDER_NAMES:
            return False
    return True


def _source_ref_file(ref: str) -> str:
    """Strip an optional ':symbol' suffix from a source_ref, returning the path."""
    return ref.split(":", 1)[0] if ":" in ref else ref


def _symbol_defined(repo_root: str, file: str, symbol: str) -> bool:
    """Best-effort: True if `symbol` is *defined* in a Python file.

    Only real definitions count — a merely imported name does NOT, since a
    source_ref must point at where the invariant is actually upheld, not at a
    file that re-imports it (that would mask symbol drift).
    Returns True (no false positive) for non-Python or unparseable files."""
    if not file.endswith(".py"):
        return True
    try:
        tree = ast.parse((Path(repo_root) / file).read_text(encoding="utf-8"))
    except Exception:
        return True
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            if node.name == symbol:
                return True
        elif isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id == symbol:
                    return True
        elif isinstance(node, ast.AnnAssign):
            if isinstance(node.target, ast.Name) and node.target.id == symbol:
                return True
    return False


def _field_missing(data: dict, field: str) -> bool:
    """A field is missing if absent, None, or a blank string.
    An empty list is NOT missing (e.g. invariants: [] is valid)."""
    if field not in data:
        return True
    value = data[field]
    if value is None:
        return True
    return isinstance(value, str) and value.strip() == ""


def _resolve_schema_ref(repo_root: str, ref: str) -> bool:
    """Best-effort check that a Contract schema_ref points at a real file.
    Heuristic — used for warnings only, never errors.
      Python  pneuma_core.models.character.Character -> pneuma_core/models/character.py
      TS      src/models/character.ts#Character      -> src/models/character.ts
    """
    if "#" in ref:  # TS form: path#Type
        return _path_exists(repo_root, ref.split("#", 1)[0])
    parts = ref.split(".")
    # Drop trailing CapitalCase components (the type/symbol name).
    while len(parts) > 1 and parts[-1][:1].isupper():
        parts.pop()
    module = "/".join(parts)
    for prefix in ("", "src/"):
        if _path_exists(repo_root, prefix + module + ".py"):
            return True
        if _path_exists(repo_root, prefix + module + "/__init__.py"):
            return True
    return False


def verify(spec_dir: str, repo_root: str) -> dict:
    """Run all static checks. Returns a structured report dict."""
    errors: list[str] = []
    warnings: list[str] = []

    if yaml is None:
        return {
            "ok": False,
            "errors": ["PyYAML is not installed (pip install pyyaml)"],
            "warnings": [],
            "stats": {},
        }

    if not Path(spec_dir).is_dir():
        return {
            "ok": False,
            "errors": [f"spec directory not found: {spec_dir}"],
            "warnings": [],
            "stats": {},
        }

    spec = load_spec(spec_dir)
    errors.extend(spec["parse_errors"])
    stories = spec["stories"]
    contracts = spec["contracts"]

    inv_total = 0
    inv_pending = 0
    # Pending invariants are the convergence backlog: each one is a gap
    # in the "modifications don't break it" guarantee. Listed so the
    # healthcheck can propose reinforcement issues without re-parsing.
    pending_invariants: list = []

    # ---- Stories ----
    for stem, data in stories.items():
        for field in STORY_REQUIRED:
            if _field_missing(data, field):
                errors.append(f"story '{stem}': missing required field '{field}'")

        sid = data.get("id")
        if isinstance(sid, str) and sid.strip() and sid != stem:
            errors.append(
                f"story file '{stem}.yaml': id '{sid}' "
                f"does not match filename '{stem}'"
            )

        invariants = data.get("invariants")
        if invariants is not None and not isinstance(invariants, list):
            errors.append(f"story '{stem}': invariants must be a list")
        else:
            for inv in invariants or []:
                if not isinstance(inv, dict):
                    errors.append(f"story '{stem}': invariant entry is not a mapping")
                    continue
                inv_total += 1
                for field in INVARIANT_REQUIRED:
                    if _field_missing(inv, field):
                        errors.append(
                            f"story '{stem}' invariant '{inv.get('id', '?')}': "
                            f"missing required field '{field}'"
                        )
                test = inv.get("test")
                if test and not isinstance(test, str):
                    errors.append(
                        f"story '{stem}' invariant '{inv.get('id', '?')}': "
                        f"test must be a string path"
                    )
                    inv_pending += 1
                    pending_invariants.append({
                        "story": stem,
                        "id": inv.get("id", "?"),
                        "text": str(inv.get("text", "")).strip(),
                    })
                elif test:
                    if not _path_exists(repo_root, test):
                        errors.append(
                            f"story '{stem}' invariant '{inv.get('id', '?')}': "
                            f"test path not found: {test}"
                        )
                else:
                    inv_pending += 1
                    pending_invariants.append({
                        "story": stem,
                        "id": inv.get("id", "?"),
                        "text": str(inv.get("text", "")).strip(),
                    })
                src_ref = inv.get("source_ref")
                if src_ref and not isinstance(src_ref, str):
                    errors.append(
                        f"story '{stem}' invariant '{inv.get('id', '?')}': "
                        f"source_ref must be a string path"
                    )
                elif src_ref:
                    ref_file = _source_ref_file(src_ref)
                    if not _path_exists(repo_root, ref_file):
                        errors.append(
                            f"story '{stem}' invariant '{inv.get('id', '?')}': "
                            f"source_ref path not found: {src_ref}"
                        )
                    elif ":" in src_ref:
                        symbol = src_ref.split(":", 1)[1].strip()
                        if symbol and not _symbol_defined(repo_root, ref_file, symbol):
                            errors.append(
                                f"story '{stem}' invariant '{inv.get('id', '?')}': "
                                f"source_ref symbol '{symbol}' not found in {ref_file}"
                            )

        src_files = data.get("source_files")
        if src_files is not None and not isinstance(src_files, list):
            errors.append(f"story '{stem}': source_files must be a list")
        else:
            for src in src_files or []:
                if not isinstance(src, str):
                    errors.append(
                        f"story '{stem}': source_files entry must be a string path"
                    )
                elif not _path_exists(repo_root, src):
                    errors.append(
                        f"story '{stem}': source_files path not found: {src}"
                    )
                elif _dir_is_empty_placeholder(repo_root, src):
                    errors.append(
                        f"story '{stem}': source_files path is an "
                        f"empty directory (placeholder?): {src}"
                    )

        deps = data.get("depends_on")
        if deps is not None and not isinstance(deps, list):
            errors.append(f"story '{stem}': depends_on must be a list")
        else:
            for dep in deps or []:
                if not isinstance(dep, str):
                    errors.append(
                        f"story '{stem}': depends_on entry must be a string"
                    )
                elif dep not in stories:
                    errors.append(
                        f"story '{stem}': depends_on '{dep}' "
                        f"does not reference an existing story"
                    )

    # ---- Contracts ----
    for stem, data in contracts.items():
        for field in CONTRACT_REQUIRED:
            if _field_missing(data, field):
                errors.append(f"contract '{stem}': missing required field '{field}'")

        cid = data.get("id")
        if isinstance(cid, str) and cid.strip() and cid != stem:
            errors.append(
                f"contract file '{stem}.yaml': id '{cid}' "
                f"does not match filename '{stem}'"
            )

        story_ref = data.get("story")
        if story_ref is not None and not isinstance(story_ref, str):
            errors.append(f"contract '{stem}': story must be a string")
        elif story_ref is not None and story_ref not in stories:
            errors.append(
                f"contract '{stem}': story '{story_ref}' "
                f"does not reference an existing story"
            )

        for role in ("producers", "consumers"):
            value = data.get(role)
            if value is not None and not isinstance(value, list):
                errors.append(f"contract '{stem}': {role} must be a list")
                continue
            for src in value or []:
                if not isinstance(src, str):
                    errors.append(
                        f"contract '{stem}': {role} entry must be a string path"
                    )
                elif not _path_exists(repo_root, src):
                    errors.append(
                        f"contract '{stem}': {role} path not found: {src}"
                    )
                elif _dir_is_empty_placeholder(repo_root, src):
                    errors.append(
                        f"contract '{stem}': {role} path is an "
                        f"empty directory (placeholder?): {src}"
                    )

        ref = data.get("schema_ref")
        if isinstance(ref, str) and ref.strip() and not _resolve_schema_ref(repo_root, ref):
            warnings.append(
                f"contract '{stem}': schema_ref '{ref}' could not be resolved "
                f"to a file (possible drift, or non-standard layout)"
            )

    if not stories and not contracts:
        warnings.append(f"no spec files found under {spec_dir}")

    stats = {
        "stories": len(stories),
        "contracts": len(contracts),
        "invariants_total": inv_total,
        "invariants_pending": inv_pending,
        "invariants_with_test": inv_total - inv_pending,
        "pending_invariants": pending_invariants,
    }

    return {
        "ok": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "stats": stats,
    }


# ──────────────────────────────────────────────
# Dynamic verification: run invariant tests (--run-tests)
# ──────────────────────────────────────────────

# Per-test timeout (seconds)
INVARIANT_TEST_TIMEOUT = 120


def _runner_cmd(test_path: str) -> list | None:
    """Pick a test runner command for a single test path.

    Returns None when no runner can be determined."""
    if test_path.endswith(".py"):
        return [sys.executable, "-m", "pytest", "-q", test_path]
    if test_path.endswith(".sh"):
        return ["bash", test_path]
    if test_path.endswith((".ts", ".tsx", ".js", ".jsx", ".mjs")):
        return ["npx", "vitest", "run", test_path]
    return None


def run_invariant_tests(spec_dir: str, repo_root: str) -> list:
    """Execute each invariant's test and compute its status.

    This is the layer the schema promises ('test 有り・失敗 → 違反'):
    - test passes        → verified
    - test fails/timeout → violated
    - no test declared   → pending
    - runner problems (no runner, path missing, pytest collected 0
      tests) → error — the unique failure mode a full-suite run can
      never surface (a test path the runner silently doesn't collect).

    Returns a list of {id, story, test, status, detail} dicts.
    """
    spec = load_spec(spec_dir)
    invariants: list = []
    by_test: dict = {}

    for stem, data in spec["stories"].items():
        if not isinstance(data, dict):
            continue
        for inv in data.get("invariants") or []:
            if not isinstance(inv, dict):
                continue
            test = inv.get("test")
            entry = {
                "id": inv.get("id", "?"),
                "story": stem,
                "test": test if isinstance(test, str) and test else None,
                "status": "pending",
                "detail": "",
            }
            invariants.append(entry)
            if entry["test"]:
                by_test.setdefault(entry["test"], []).append(entry)

    for test_path, entries in by_test.items():
        if not (Path(repo_root) / test_path).exists():
            status, detail = "error", f"test path not found: {test_path}"
        else:
            cmd = _runner_cmd(test_path)
            if cmd is None:
                status, detail = "error", f"no test runner for: {test_path}"
            else:
                try:
                    r = subprocess.run(
                        cmd, cwd=repo_root, capture_output=True, text=True,
                        timeout=INVARIANT_TEST_TIMEOUT,
                    )
                    if r.returncode == 0:
                        status, detail = "verified", ""
                    elif test_path.endswith(".py") and r.returncode == 5:
                        # pytest exit 5 = no tests collected — the path
                        # exists but the runner sees nothing in it.
                        status, detail = "error", "no tests collected"
                    else:
                        tail = (r.stdout + r.stderr).strip()[-500:]
                        status, detail = "violated", tail
                except subprocess.TimeoutExpired:
                    status, detail = "violated", "test timed out"
                except FileNotFoundError as exc:
                    status, detail = "error", f"runner unavailable: {exc}"
        for e in entries:
            e["status"], e["detail"] = status, detail

    return invariants


def format_report(report: dict, spec_dir: str) -> str:
    """Render a verify() report as human-readable text."""
    s = report.get("stats", {})
    lines = [f"Spec Verification — {spec_dir}"]
    if s:
        lines.append(f"  stories: {s['stories']}, contracts: {s['contracts']}")
        lines.append(
            f"  invariants: {s['invariants_total']} total, "
            f"{s['invariants_pending']} pending, "
            f"{s['invariants_with_test']} with test"
        )
    invariants = report.get("invariants")
    if invariants is not None:
        verified = sum(1 for i in invariants if i["status"] == "verified")
        violated = [i for i in invariants if i["status"] == "violated"]
        errored = [i for i in invariants if i["status"] == "error"]
        pending = sum(1 for i in invariants if i["status"] == "pending")
        lines.append(
            f"  invariant tests: {verified} verified, "
            f"{len(violated)} violated, {len(errored)} error, "
            f"{pending} pending"
        )
        for i in violated:
            lines.append(f"    VIOLATED {i['story']}/{i['id']}: {i['test']}")
        for i in errored:
            lines.append(f"    ERROR    {i['story']}/{i['id']}: {i['detail']}")
    errors = report.get("errors", [])
    warnings = report.get("warnings", [])
    lines.append(f"  ERRORS ({len(errors)}):")
    for e in errors:
        lines.append(f"    - {e}")
    lines.append(f"  WARNINGS ({len(warnings)}):")
    for w in warnings:
        lines.append(f"    - {w}")
    lines.append(f"  RESULT: {'PASS' if report.get('ok') else 'FAIL'}")
    return "\n".join(lines)


def _default_repo_root(spec_dir: str) -> str:
    """Derive repo root from a spec dir of the form <root>/.vibe/spec."""
    p = Path(spec_dir).resolve()
    if p.name == "spec" and p.parent.name == ".vibe":
        return str(p.parent.parent)
    return str(Path.cwd())


def main(argv: list[str]) -> int:
    flags = {a for a in argv if a.startswith("--")}
    args = [a for a in argv if not a.startswith("--")]
    as_json = "--json" in flags
    run_tests = "--run-tests" in flags

    if not args:
        sys.stderr.write(
            "usage: spec_verify.py <spec_dir> [repo_root] [--json] [--run-tests]\n"
        )
        return 2

    spec_dir = args[0]
    repo_root = args[1] if len(args) > 1 else _default_repo_root(spec_dir)

    report = verify(spec_dir, repo_root)

    if run_tests and report.get("stats"):
        invariants = run_invariant_tests(spec_dir, repo_root)
        report["invariants"] = invariants
        violated = sum(1 for i in invariants if i["status"] == "violated")
        errored = sum(1 for i in invariants if i["status"] == "error")
        report["stats"]["invariants_violated"] = violated
        report["stats"]["invariants_verified"] = sum(
            1 for i in invariants if i["status"] == "verified"
        )
        report["stats"]["invariants_error"] = errored
        if violated or errored:
            report["ok"] = False

    if as_json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(format_report(report, spec_dir))

    return 0 if report.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
