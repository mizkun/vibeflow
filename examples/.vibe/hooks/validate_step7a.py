#!/usr/bin/env python3
"""
VibeFlow Step 7a Guard Hook
Blocks `gh pr create` until QA checkpoint is approved.
Used as a PreToolUse hook (matcher: Bash) to enforce the human checkpoint.
Exit code 2 blocks the tool call (Claude Code specification).

v6 Spec Gate: a PR that changes the structured spec (.vibe/spec/ Story/Contract)
must go through the Human Checkpoint. qa:auto auto-pass CANNOT bypass it —
only an explicit human "approved" checkpoint lets a spec-changing PR through.
"""

import json
import os
import re
import subprocess
import sys

# Valid issue format: optional # followed by digits only
ISSUE_RE = re.compile(r"^#?\d+$")
CHECKPOINT_CONTENT_RE = re.compile(r"^(auto-approved:qa:auto|approved)$", re.MULTILINE)
# Human-only checkpoint: explicit PO approval, not a qa:auto auto-pass
HUMAN_CHECKPOINT_RE = re.compile(r"^approved$", re.MULTILINE)

# A change under this path forces the Human Checkpoint (qa:auto cannot bypass)
SPEC_PATH_PREFIX = ".vibe/spec/"

# Reverse Spec Gate: paths that count as "code" — changing them without a
# spec change requires the Issue to declare "spec 変更なし".
CODE_PATH_PREFIXES = ("src/", "tests/", "test/", "lib/", "app/")

# A *filled-in* declaration line. The raw Issue-template placeholder
# (対象 Story / Contract: [`...` / spec 変更なし（コードのみ）]) contains
# brackets and must NOT count — [^\[\]\n]* rejects any bracket on the line.
SPEC_NONE_DECL_RE = re.compile(
    r"対象\s*Story\s*/\s*Contract\s*[:：]\s*[^\[\]\n]*spec\s*変更なし"
)


def project_root() -> str:
    """Get project root from CLAUDE_PROJECT_DIR or current directory."""
    return os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()


def read_yaml_value(state_path: str, key: str) -> str:
    """Read a top-level value from state.yaml (simple line parser)."""
    try:
        with open(state_path, "r", encoding="utf-8") as f:
            for line in f:
                s = line.strip()
                if s.startswith(f"{key}:"):
                    val = s.split(":", 1)[1].strip().strip('"').strip("'")
                    return val
    except FileNotFoundError:
        pass
    return ""


def is_valid_issue(issue: str) -> bool:
    """Validate issue format: optional # prefix followed by digits only."""
    return bool(ISSUE_RE.match(issue))


def normalize_issue(issue: str) -> str:
    """Normalize issue identifier by stripping # prefix."""
    return issue.lstrip("#").strip()


def validate_checkpoint_content(path: str, human_only: bool = False) -> bool:
    """Validate that checkpoint file has expected content (not empty/arbitrary).
    human_only=True accepts only an explicit human "approved" (rejects qa:auto)."""
    pattern = HUMAN_CHECKPOINT_RE if human_only else CHECKPOINT_CONTENT_RE
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read().strip()
            return bool(pattern.search(content))
    except Exception:
        return False


def checkpoint_exists(root: str, issue: str, human_only: bool = False) -> bool:
    """Check if a valid QA checkpoint file exists for the given issue.
    human_only=True requires an explicit human "approved" checkpoint."""
    if not is_valid_issue(issue):
        return False
    normalized = normalize_issue(issue)
    if not normalized:
        return False
    checkpoint_dir = os.path.join(root, ".vibe", "checkpoints")
    # Check both with and without # prefix
    candidates = [
        os.path.join(checkpoint_dir, f"{issue}-qa-approved"),
        os.path.join(checkpoint_dir, f"#{normalized}-qa-approved"),
        os.path.join(checkpoint_dir, f"{normalized}-qa-approved"),
    ]
    for p in candidates:
        # Guard against path traversal: resolved path must stay inside checkpoints/
        real_p = os.path.realpath(p)
        real_dir = os.path.realpath(checkpoint_dir)
        if not real_p.startswith(real_dir + os.sep) and real_p != real_dir:
            continue
        if os.path.isfile(p) and validate_checkpoint_content(p, human_only=human_only):
            return True
    return False


def packet_exists(root: str, issue: str) -> bool:
    """True if the checkpoint packet (what the PO actually reviewed)
    exists for the issue. A human 'approved' checkpoint without its
    packet is a rubber stamp — the approval recorded nothing about what
    was approved."""
    if not is_valid_issue(issue):
        return False
    normalized = normalize_issue(issue)
    if not normalized:
        return False
    checkpoint_dir = os.path.join(root, ".vibe", "checkpoints")
    candidates = [
        os.path.join(checkpoint_dir, f"{issue}-packet.md"),
        os.path.join(checkpoint_dir, f"#{normalized}-packet.md"),
        os.path.join(checkpoint_dir, f"{normalized}-packet.md"),
    ]
    for p in candidates:
        real_p = os.path.realpath(p)
        real_dir = os.path.realpath(checkpoint_dir)
        if not real_p.startswith(real_dir + os.sep) and real_p != real_dir:
            continue
        if os.path.isfile(p) and os.path.getsize(p) > 0:
            return True
    return False


def _ref_exists(root: str, ref: str) -> bool:
    """True if `ref` resolves in the repo at `root`."""
    try:
        r = subprocess.run(
            ["git", "-C", root, "rev-parse", "--verify", "--quiet", ref],
            capture_output=True, text=True, timeout=5,
        )
        return r.returncode == 0
    except Exception:
        return False


def _base_branch(root: str, command: str = "") -> str:
    """Determine the PR base branch for diffing. Empty string if undetermined.

    Priority: explicit `--base` in the gh pr create command, then origin/HEAD,
    then common base branches (local and remote)."""
    # 1. Explicit --base in the gh pr create command. Try the local branch
    #    first, then the remote-tracking ref — in a fresh clone the PR base
    #    often exists only as origin/<base>, and the explicit --base must win.
    m = re.search(r"--base[=\s]+([^\s'\"]+)", command or "")
    if m:
        base = m.group(1)
        if _ref_exists(root, base):
            return base
        if _ref_exists(root, "origin/" + base):
            return "origin/" + base
    # 2. origin/HEAD symbolic ref (the remote's default branch)
    try:
        r = subprocess.run(
            ["git", "-C", root, "symbolic-ref", "--short", "refs/remotes/origin/HEAD"],
            capture_output=True, text=True, timeout=5,
        )
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()
    except Exception:
        pass
    # 3. Common base branches — local first, then remote-tracking
    for b in ("main", "master", "origin/main", "origin/master"):
        if _ref_exists(root, b):
            return b
    return ""


def spec_changed(root: str, command: str = "") -> bool:
    """True if the current branch's commits change the structured spec
    (.vibe/spec/) relative to the PR base branch.

    Fail-closed throughout: when a base branch IS known but the diff cannot
    be computed, return True. When no base branch resolves at all, the diff
    cannot be run — if the project uses structured spec (a .vibe/spec/
    directory exists) we cannot prove the PR is spec-free, so return True
    (fail closed). A repo with no .vibe/spec/ cannot have a spec change."""
    base = _base_branch(root, command)
    if not base:
        return os.path.isdir(os.path.join(root, ".vibe", "spec"))
    try:
        r = subprocess.run(
            ["git", "-C", root, "diff", "--name-status", f"{base}...HEAD"],
            capture_output=True, text=True, timeout=5,
        )
    except Exception:
        return True  # base known but diff failed — fail closed
    if r.returncode != 0:
        return True  # fail closed
    for line in r.stdout.splitlines():
        # --name-status emits "STATUS\tpath" (or "Rxxx\told\tnew" for renames);
        # scanning every path column catches moves into AND out of .vibe/spec/.
        for path in line.split("\t")[1:]:
            if path.strip().startswith(SPEC_PATH_PREFIX):
                return True
    return False


def code_changed(root: str, command: str = "") -> bool:
    """True if the current branch's commits change code paths
    (src/tests/lib/app) relative to the PR base branch.

    On diff failure this returns False — but spec_changed() already
    fails closed in those situations, so the stricter spec path
    dominates."""
    base = _base_branch(root, command)
    if not base:
        return False
    try:
        r = subprocess.run(
            ["git", "-C", root, "diff", "--name-status", f"{base}...HEAD"],
            capture_output=True, text=True, timeout=5,
        )
    except Exception:
        return False
    if r.returncode != 0:
        return False
    for line in r.stdout.splitlines():
        for path in line.split("\t")[1:]:
            p = path.strip()
            if any(p.startswith(prefix) for prefix in CODE_PATH_PREFIXES):
                return True
    return False


def issue_declares_no_spec_change(issue: str) -> bool:
    """True if the Issue body contains a *filled-in* 'spec 変更なし'
    declaration in its '## Spec 変更' section.
    Returns False on any failure (fail-closed, like check_qa_auto_label)."""
    if not is_valid_issue(issue):
        return False
    normalized = normalize_issue(issue)
    if not normalized:
        return False
    try:
        result = subprocess.run(
            ["gh", "issue", "view", normalized, "--json", "body", "--jq", ".body"],
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0:
            return bool(SPEC_NONE_DECL_RE.search(result.stdout))
    except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
        pass
    return False


# Test files whose weakening counts as reward hacking
_TEST_PATH_RE = re.compile(
    r"(^|/)(tests?)/|\.test\.|\.spec\.|(^|/)__tests__/"
)
# A test-case definition (JS/TS it()/test(), python def test_)
_TEST_DEF_RE = re.compile(r"\b(?:it|test)\s*\(|def\s+test_\w+")
# A skip/only marker that silences a test
_SKIP_RE = re.compile(
    r"\.skip\b|\.only\b|\bxit\b|\bxdescribe\b|it\.todo\b|"
    r"@pytest\.mark\.skip|@unittest\.skip"
)


def tests_weakened(root: str, command: str = "") -> bool:
    """True if the branch deletes test files, drops test cases, or adds
    skip markers relative to the PR base. Reward-hacking the gate by
    editing the tests it relies on (SpecBench/ImpossibleBench).

    Fail-closed: if a base resolves but the diff cannot be computed,
    return True."""
    base = _base_branch(root, command)
    if not base:
        return False  # no base → cannot diff; spec gate handles its own fail-closed
    # 1) deleted test files
    try:
        ns = subprocess.run(
            ["git", "-C", root, "diff", "--name-status", f"{base}...HEAD"],
            capture_output=True, text=True, timeout=5,
        )
    except Exception:
        return True
    if ns.returncode != 0:
        return True
    for line in ns.stdout.splitlines():
        cols = line.split("\t")
        status = cols[0]
        for path in cols[1:]:
            if _TEST_PATH_RE.search(path) and status.startswith("D"):
                return True
    # 2) per-line diff of test files: net test-case drop or added skips
    try:
        diff = subprocess.run(
            ["git", "-C", root, "diff", f"{base}...HEAD", "--unified=0"],
            capture_output=True, text=True, timeout=5,
        )
    except Exception:
        return True
    if diff.returncode != 0:
        return True

    in_test_file = False
    def_added = def_removed = skip_added = skip_removed = 0
    for line in diff.stdout.splitlines():
        if line.startswith("diff --git"):
            in_test_file = bool(_TEST_PATH_RE.search(line))
            continue
        if not in_test_file or line.startswith(("+++", "---")):
            continue
        if line.startswith("+"):
            def_added += len(_TEST_DEF_RE.findall(line))
            skip_added += len(_SKIP_RE.findall(line))
        elif line.startswith("-"):
            def_removed += len(_TEST_DEF_RE.findall(line))
            skip_removed += len(_SKIP_RE.findall(line))

    if def_removed > def_added:
        return True
    if skip_added > skip_removed:
        return True
    return False


def check_qa_auto_label(issue: str) -> bool:
    """Check if the issue has qa:auto label via gh CLI.
    Returns False on any failure (fail-closed)."""
    if not is_valid_issue(issue):
        return False
    normalized = normalize_issue(issue)
    if not normalized:
        return False
    try:
        result = subprocess.run(
            ["gh", "issue", "view", normalized, "--json", "labels", "--jq", '.labels[].name'],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            labels = result.stdout.strip().split("\n")
            return "qa:auto" in labels
    except (subprocess.TimeoutExpired, FileNotFoundError, Exception):
        pass
    # On failure, fall back to blocking (safe side)
    return False


def auto_create_checkpoint(root: str, issue: str) -> None:
    """Auto-create QA checkpoint for qa:auto issues."""
    if not is_valid_issue(issue):
        return
    checkpoint_dir = os.path.join(root, ".vibe", "checkpoints")
    os.makedirs(checkpoint_dir, exist_ok=True)
    checkpoint_path = os.path.join(checkpoint_dir, f"{issue}-qa-approved")
    with open(checkpoint_path, "w") as f:
        f.write("auto-approved:qa:auto\n")


def play_checkpoint_alert(root: str) -> None:
    """Play checkpoint notification sound to get user's attention."""
    alert_script = os.path.join(root, ".vibe", "hooks", "checkpoint_alert.sh")
    if os.path.isfile(alert_script):
        try:
            subprocess.Popen(
                ["bash", alert_script],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
        except Exception:
            pass


def block(msg: str, root: str = "") -> None:
    """Print error message, play alert, and exit with code 2 to block tool call."""
    if root:
        play_checkpoint_alert(root)
    print(msg, file=sys.stderr)
    sys.exit(2)


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        # Broken input - don't block development
        sys.exit(0)

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}

    # Only guard Bash tool calls
    if tool_name != "Bash":
        sys.exit(0)

    command = tool_input.get("command", "")

    # Only guard gh pr create commands. Normalize away shell quotes, escapes
    # and whitespace so obfuscated spellings (g'h' pr create, gh\ pr create,
    # tabs/newlines) still match. This is a guardrail for a cooperative agent,
    # not an adversarial sandbox — eval / aliases / variables cannot be matched
    # from the command string and are deliberately out of scope.
    stripped = re.sub(r"['\"\\]", "", command)
    if not re.search(r"\bgh\s+pr\s+create\b", stripped):
        sys.exit(0)

    root = project_root()
    state_path = os.path.join(root, ".vibe", "state.yaml")
    issue = read_yaml_value(state_path, "current_issue")

    # v6 Spec Gate (keystone): detect spec changes up front, so that missing
    # or invalid issue state can never let a spec-changing PR slip past.
    spec = spec_changed(root, command)

    # No current issue. A non-spec PR passes (not in a tracked dev cycle).
    # A spec-changing PR is blocked — spec changes must be Issue-tracked and
    # human-approved (fail-closed).
    if not issue or issue == "null":
        if spec:
            block(root=root, msg=
                f"[VibeFlow Step7a Guard — Spec Gate]\n"
                f"この PR は構造化 spec (.vibe/spec/) を変更していますが、"
                f"current_issue が未設定です。\n"
                f"spec 変更は Issue に紐づけ、Human Checkpoint を通す必要があります。\n"
                f".vibe/state.yaml の current_issue を設定してから進めてください。\n"
            )
        sys.exit(0)

    # Invalid issue format - block (fail-closed)
    if not is_valid_issue(issue):
        block(root=root, msg=
            f"[VibeFlow Step7a Guard]\n"
            f"不正な Issue 番号フォーマット: '{issue}'\n"
            f"state.yaml の current_issue は '#数字' または '数字' 形式である必要があります。\n"
        )

    # v6 Spec Gate: a PR that changes the structured spec must go through the
    # Human Checkpoint. qa:auto auto-pass cannot bypass it — only an explicit
    # human "approved" checkpoint lets a spec-changing PR through.
    if spec:
        if checkpoint_exists(root, issue, human_only=True):
            if packet_exists(root, issue):
                sys.exit(0)
            block(root=root, msg=
                f"[VibeFlow Step7a Guard — Checkpoint Packet]\n"
                f"Issue {issue} に人間承認はありますが、承認の根拠となる\n"
                f"Checkpoint Packet (.vibe/checkpoints/{issue}-packet.md) が\n"
                f"ありません。PO が何を見て承認したかを記録するため、\n"
                f"Step 7a で packet（AC チェックリスト・spec 差分要約・証拠・\n"
                f"スコープ外変更）を作成してから提示・承認してください。\n"
            )
        block(root=root, msg=
            f"[VibeFlow Step7a Guard — Spec Gate]\n"
            f"この PR は構造化 spec (.vibe/spec/ の Story/Contract) を変更しています。\n"
            f"spec 変更を含む PR は qa:auto で自動承認できません。"
            f"必ず Human Checkpoint を通します。\n\n"
            f"承認フロー:\n"
            f"  1) Checkpoint Packet（spec 差分要約を含む）を PO に提示して停止\n"
            f"  2) PO が自分の端末で `vibeflow approve {issue}` を実行（TTY 必須）\n"
            f"  3) その後 gh pr create を実行可能\n"
            f"  ※ エージェントが checkpoint を自作することはできません\n"
        )

    # v6 Reverse Spec Gate: code changed but spec untouched. The most
    # common drift direction (code moves on, spec rots) needs an explicit
    # decision: either update the To-Be spec, or fill in the Issue's
    # 'spec 変更なし' declaration (bug class (i): code violates a correct
    # spec). A human 'approved' checkpoint also counts — the PO has seen it.
    # Only active in projects that use the structured spec.
    if (not spec
            and os.path.isdir(os.path.join(root, ".vibe", "spec"))
            and code_changed(root, command)
            and not checkpoint_exists(root, issue, human_only=True)
            and not issue_declares_no_spec_change(issue)):
        block(root=root, msg=
            f"[VibeFlow Step7a Guard — Reverse Spec Gate]\n"
            f"この PR はコード（src/tests/lib/app）を変更していますが、"
            f"構造化 spec (.vibe/spec/) を変更しておらず、\n"
            f"Issue {issue} に記入済みの「spec 変更なし」宣言も見つかりません。\n\n"
            f"対応（どちらか）:\n"
            f"  1) この変更が仕様に触れるなら: .vibe/spec/ の Story/Contract を\n"
            f"     To-Be に更新してコミットする（Step 3.5）\n"
            f"  2) 仕様に触れない変更（バグ分類 (i) 等）なら: Issue 本文の\n"
            f"     「## Spec 変更」欄に『対象 Story / Contract: spec 変更なし'\n"
            f"     （コードのみ）』と記入する（テンプレートの角括弧は外すこと）\n"
        )

    # TestGuard: weakening the tests the gate relies on (deleting files,
    # dropping cases, adding skips) requires explicit human approval —
    # qa:auto cannot rubber-stamp it.
    if tests_weakened(root, command) and not checkpoint_exists(root, issue, human_only=True):
        block(root=root, msg=
            f"[VibeFlow Step7a Guard — TestGuard]\n"
            f"この PR は既存テストを弱体化しています"
            f"（削除 / テストケースの純減 / skip 追加）。\n"
            f"テストを骨抜きにしてゲートを通すことは禁止です。\n\n"
            f"対応:\n"
            f"  1) テストを戻し、コードを直して GREEN にする、または\n"
            f"  2) テスト削除が正当なら PO に提示し、Human Checkpoint"
            f"（{issue}-qa-approved + packet）の承認を得る\n"
        )

    # Check if checkpoint already exists. A *human* approval also needs
    # its packet (what the PO reviewed); qa:auto auto-approvals don't.
    if checkpoint_exists(root, issue):
        if (checkpoint_exists(root, issue, human_only=True)
                and not packet_exists(root, issue)):
            block(root=root, msg=
                f"[VibeFlow Step7a Guard — Checkpoint Packet]\n"
                f"Issue {issue} に人間承認はありますが、承認の根拠となる\n"
                f"Checkpoint Packet (.vibe/checkpoints/{issue}-packet.md) が\n"
                f"ありません。Step 7a で packet を作成してから提示・承認して\n"
                f"ください。\n"
            )
        sys.exit(0)

    # Check if issue has qa:auto label
    if check_qa_auto_label(issue):
        auto_create_checkpoint(root, issue)
        sys.exit(0)

    # Block: no checkpoint and not qa:auto
    block(root=root, msg=
        f"[VibeFlow Step7a Guard]\n"
        f"PR 作成がブロックされました。\n"
        f"Issue {issue} の QA チェックポイント（Step 7a）が未承認です。\n\n"
        f"承認フロー:\n"
        f"  1) QA テスト結果（Checkpoint Packet）を PO に報告して停止\n"
        f"  2) PO が自分の端末で `vibeflow approve {issue}` を実行（TTY 必須）\n"
        f"  3) その後 gh pr create を実行可能\n\n"
        f"または Issue に qa:auto ラベルを付与すると自動承認されます。\n"
        f"※ エージェントが checkpoint を自作することはできません\n"
    )


if __name__ == "__main__":
    main()
