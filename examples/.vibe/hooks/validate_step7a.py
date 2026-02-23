#!/usr/bin/env python3
"""
VibeFlow Step 7a Guard Hook
Blocks `gh pr create` until QA checkpoint is approved.
Used as a PreToolUse hook (matcher: Bash) to enforce the human checkpoint.
Exit code 2 blocks the tool call (Claude Code specification).
"""

import json
import os
import re
import subprocess
import sys

# Valid issue format: optional # followed by digits only
ISSUE_RE = re.compile(r"^#?\d+$")
CHECKPOINT_CONTENT_RE = re.compile(r"^(auto-approved:qa:auto|approved)$", re.MULTILINE)


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


def validate_checkpoint_content(path: str) -> bool:
    """Validate that checkpoint file has expected content (not empty/arbitrary)."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read().strip()
            return bool(CHECKPOINT_CONTENT_RE.search(content))
    except Exception:
        return False


def checkpoint_exists(root: str, issue: str) -> bool:
    """Check if a valid QA checkpoint file exists for the given issue."""
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
        if os.path.isfile(p) and validate_checkpoint_content(p):
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

    # Only guard gh pr create commands
    if "gh pr create" not in command:
        sys.exit(0)

    root = project_root()
    state_path = os.path.join(root, ".vibe", "state.yaml")
    issue = read_yaml_value(state_path, "current_issue")

    # No current issue - not in a dev cycle, pass through
    if not issue or issue == "null":
        sys.exit(0)

    # Invalid issue format - block (fail-closed)
    if not is_valid_issue(issue):
        block(root=root, msg=
            f"[VibeFlow Step7a Guard]\n"
            f"不正な Issue 番号フォーマット: '{issue}'\n"
            f"state.yaml の current_issue は '#数字' または '数字' 形式である必要があります。\n"
        )

    # Check if checkpoint already exists
    if checkpoint_exists(root, issue):
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
        f"  1) QA テスト結果をユーザーに報告して停止\n"
        f"  2) ユーザーが手動確認・承認\n"
        f"  3) .vibe/checkpoints/{issue}-qa-approved を作成\n"
        f"  4) その後 gh pr create を実行可能\n\n"
        f"または Issue に qa:auto ラベルを付与すると自動承認されます。\n"
    )


if __name__ == "__main__":
    main()
