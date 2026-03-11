#!/usr/bin/env python3
from __future__ import annotations
"""
VibeFlow Doctor — Manifest-aware integrity checker.
Verifies generated files, cross-schema consistency, and version drift.

Usage:
    python3 core/doctor.py --project-dir . --schema-dir core/schema
    python3 core/doctor.py --project-dir . --schema-dir core/schema --json
    python3 core/doctor.py --project-dir . --schema-dir core/schema --strict

Exit codes:
    Normal mode:  0 = OK/WARN, 1 = ERROR
    --strict:     0 = OK only, 1 = WARN or ERROR
"""

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml is required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

# For partial files: extract managed section content
MARKER_RE = re.compile(
    r"<!-- VF:BEGIN (\w+) -->\n(.*?)<!-- VF:END \1 -->",
    re.DOTALL,
)


class Check:
    """A single doctor check result."""

    def __init__(self, name: str, level: str, message: str):
        self.name = name
        self.level = level  # "ok", "warn", "error"
        self.message = message

    def to_dict(self) -> dict:
        return {"name": self.name, "level": self.level, "message": self.message}


def _hash_file(path: Path) -> str:
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def _hash_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def check_manifest_exists(project_dir: Path) -> list[Check]:
    """Check that generated-manifest.json exists."""
    manifest_path = project_dir / ".vibe" / "generated-manifest.json"
    if not manifest_path.exists():
        return [Check("manifest_missing", "warn",
                       "generated-manifest.json not found. Run vibeflow generate to enable integrity checks.")]
    return [Check("manifest_exists", "ok", "generated-manifest.json found")]


def check_file_integrity(project_dir: Path, manifest: dict) -> list[Check]:
    """Verify SHA256 hashes of all tracked files."""
    checks = []
    files = manifest.get("files", {})

    for rel_path, entry in files.items():
        abs_path = project_dir / rel_path
        if not abs_path.exists():
            checks.append(Check(
                "file_missing", "error",
                f"{rel_path}: tracked in manifest but file is missing"
            ))
            continue

        file_type = entry.get("type", "full")

        if file_type == "partial" and "section_hashes" in entry:
            # For partial files, check managed sections
            content = abs_path.read_text()
            current_sections = {}
            for match in MARKER_RE.finditer(content):
                current_sections[match.group(1)] = match.group(2)

            # Check each recorded section
            for section_name, recorded_hash in entry["section_hashes"].items():
                if section_name not in current_sections:
                    checks.append(Check(
                        "section_missing", "warn",
                        f"{rel_path}: managed section '{section_name}' is missing "
                        f"(VF:BEGIN/VF:END markers removed)"
                    ))
                    continue
                current_hash = _hash_bytes(current_sections[section_name].encode())
                if current_hash != recorded_hash:
                    checks.append(Check(
                        "section_modified", "warn",
                        f"{rel_path}: managed section '{section_name}' has been modified"
                    ))
        else:
            # Full file hash check
            current_hash = _hash_file(abs_path)
            recorded_hash = entry.get("sha256", "")
            if current_hash != recorded_hash:
                checks.append(Check(
                    "hash_mismatch", "error",
                    f"{rel_path}: file has been modified (hash mismatch)"
                ))

    if not checks:
        checks.append(Check("file_integrity", "ok", "all tracked files match manifest"))

    return checks


def check_version_drift(project_dir: Path, manifest: dict, framework_dir: Path | None = None) -> list[Check]:
    """Check if manifest generator_version matches current framework VERSION."""
    manifest_version = manifest.get("generator_version", "unknown")

    # Try to read current VERSION
    current_version = "unknown"
    if framework_dir:
        version_file = framework_dir / "VERSION"
        if version_file.exists():
            current_version = version_file.read_text().strip()

    # Also check project .vibe/version
    project_version_file = project_dir / ".vibe" / "version"
    if project_version_file.exists():
        current_version = project_version_file.read_text().strip()

    if manifest_version == "unknown" or current_version == "unknown":
        return []

    if manifest_version != current_version:
        return [Check(
            "version_drift", "warn",
            f"manifest version {manifest_version} != current version {current_version}. "
            f"Run vibeflow generate to update."
        )]

    return [Check("version_match", "ok",
                  f"generator version {manifest_version} matches")]


def check_cross_schema(schema_dir: Path) -> list[Check]:
    """Cross-file schema validation."""
    checks = []

    # Load schemas
    schemas = {}
    for name in ("policy", "workflow", "roles"):
        fpath = schema_dir / f"{name}.yaml"
        if not fpath.exists():
            checks.append(Check(f"cross_missing_{name}", "error",
                                f"Schema file missing: {fpath.name}"))
            continue
        with open(fpath) as f:
            schemas[name] = yaml.safe_load(f)

    if len(schemas) < 3:
        return checks

    # Check workflow roles ↔ policy/roles
    policy_roles = set(schemas["policy"].get("roles", {}).keys())
    roles_roles = set(schemas["roles"].get("roles", {}).keys())

    for wtype, wdef in schemas["workflow"].get("workflows", {}).items():
        for step in wdef.get("steps", []):
            role = step.get("role", "")
            step_id = step.get("id", "?")
            if role not in policy_roles:
                checks.append(Check(
                    "cross_role_policy", "error",
                    f"workflow.{wtype}.{step_id}: role '{role}' not in policy.yaml"
                ))
            if role not in roles_roles:
                checks.append(Check(
                    "cross_role_roles", "error",
                    f"workflow.{wtype}.{step_id}: role '{role}' not in roles.yaml"
                ))

    # Policy ↔ roles consistency
    missing_in_roles = policy_roles - roles_roles
    missing_in_policy = roles_roles - policy_roles
    if missing_in_roles:
        checks.append(Check("cross_policy_roles", "error",
                            f"In policy.yaml but not roles.yaml: {missing_in_roles}"))
    if missing_in_policy:
        checks.append(Check("cross_roles_policy", "error",
                            f"In roles.yaml but not policy.yaml: {missing_in_policy}"))

    if not checks:
        checks.append(Check("cross_schema", "ok", "cross-schema validation passed"))

    return checks


def check_labels_workflow(schema_dir: Path) -> list[Check]:
    """Check issue_labels.yaml workflow labels match workflow.yaml workflow names."""
    checks = []

    labels_file = schema_dir / "issue_labels.yaml"
    workflow_file = schema_dir / "workflow.yaml"

    if not labels_file.exists() or not workflow_file.exists():
        return []

    with open(labels_file) as f:
        labels_data = yaml.safe_load(f)
    with open(workflow_file) as f:
        workflow_data = yaml.safe_load(f)

    # Get workflow names from workflow.yaml
    workflow_names = set(workflow_data.get("workflows", {}).keys())

    # Get workflow label values from issue_labels.yaml
    categories = labels_data.get("categories", {})
    workflow_cat = categories.get("workflow", {})
    workflow_labels = workflow_cat.get("labels", [])

    for label in workflow_labels:
        label_name = label.get("name", "")
        # Extract workflow name from "workflow:standard" → "standard"
        if ":" in label_name:
            wf_name = label_name.split(":", 1)[1]
            if wf_name not in workflow_names:
                checks.append(Check(
                    "labels_workflow_mismatch", "warn",
                    f"Label '{label_name}' references workflow '{wf_name}' "
                    f"not defined in workflow.yaml (available: {workflow_names})"
                ))

    if not checks:
        checks.append(Check("labels_workflow", "ok",
                            "all workflow labels match workflow.yaml definitions"))

    return checks


def run_doctor(project_dir: str, schema_dir: str,
               framework_dir: str | None = None) -> list[Check]:
    """Run all doctor checks and return results."""
    project = Path(project_dir)
    schema = Path(schema_dir)
    framework = Path(framework_dir) if framework_dir else None

    all_checks = []

    # 1. Manifest existence
    manifest_checks = check_manifest_exists(project)
    all_checks.extend(manifest_checks)

    # If manifest missing, skip file-level checks
    has_manifest = any(c.name == "manifest_exists" for c in manifest_checks)

    if has_manifest:
        manifest_path = project / ".vibe" / "generated-manifest.json"
        with open(manifest_path) as f:
            manifest = json.load(f)

        # 2. File integrity
        all_checks.extend(check_file_integrity(project, manifest))

        # 3. Version drift
        all_checks.extend(check_version_drift(project, manifest, framework))

    # 4. Cross-schema validation
    all_checks.extend(check_cross_schema(schema))

    # 5. Labels ↔ workflow consistency
    all_checks.extend(check_labels_workflow(schema))

    return all_checks


def main() -> None:
    parser = argparse.ArgumentParser(description="VibeFlow Doctor — integrity checker")
    parser.add_argument("--project-dir", required=True, help="Project root directory")
    parser.add_argument("--schema-dir", required=True, help="Path to schema directory")
    parser.add_argument("--framework-dir", default=None, help="VibeFlow framework directory")
    parser.add_argument("--json", action="store_true", dest="json_output",
                        help="Output results as JSON")
    parser.add_argument("--strict", action="store_true",
                        help="Treat warnings as errors (exit 1 on warn)")
    args = parser.parse_args()

    checks = run_doctor(args.project_dir, args.schema_dir, args.framework_dir)

    has_errors = any(c.level == "error" for c in checks)
    has_warnings = any(c.level == "warn" for c in checks)

    if args.json_output:
        output = {
            "checks": [c.to_dict() for c in checks],
            "summary": {
                "ok": sum(1 for c in checks if c.level == "ok"),
                "warn": sum(1 for c in checks if c.level == "warn"),
                "error": sum(1 for c in checks if c.level == "error"),
            }
        }
        print(json.dumps(output, indent=2))
    else:
        # Human-readable output
        print("VibeFlow Doctor")
        print("───────────────")
        for c in checks:
            icon = {"ok": "✓", "warn": "⚠", "error": "✗"}.get(c.level, "?")
            print(f"  {icon} [{c.name}] {c.message}")
        print("───────────────")

        ok_count = sum(1 for c in checks if c.level == "ok")
        warn_count = sum(1 for c in checks if c.level == "warn")
        error_count = sum(1 for c in checks if c.level == "error")
        print(f"  {ok_count} ok, {warn_count} warn, {error_count} error")

    # Exit code
    if has_errors:
        sys.exit(1)
    if has_warnings and args.strict:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
