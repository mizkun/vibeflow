#!/bin/bash
# VibeFlow Write Guard Hook
# Blocks writes to plans/ directory.
# Infrastructure Manager role is allowed to modify hooks.
# Exit code 2 blocks the tool call (Claude Code specification).

python3 -c '
import json, os, sys

def read_current_role(state_path):
    try:
        with open(state_path, "r", encoding="utf-8") as f:
            for line in f:
                s = line.strip()
                if s.startswith("current_role:"):
                    return s.split(":", 1)[1].strip().strip("\"").strip("'\''")
    except FileNotFoundError:
        pass
    return ""

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}

    if tool_name not in ("Write", "Edit", "MultiEdit"):
        sys.exit(0)

    file_path = tool_input.get("file_path") or tool_input.get("path") or ""
    if not file_path:
        sys.exit(0)

    root = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    rel = os.path.relpath(file_path, root) if os.path.isabs(file_path) else file_path
    rel = rel.lstrip("./")

    # Block writes to plans/ directory
    if rel.startswith("plans/") or rel == "plans":
        print("[VibeFlow WriteGuard] plans/ への書き込みはブロックされました。計画は plan.md に記載してください。", file=sys.stderr)
        sys.exit(2)

    # Infrastructure Manager exception: allow hook file edits
    state_path = os.path.join(root, ".vibe", "state.yaml")
    role = read_current_role(state_path)
    if role == "Infrastructure Manager":
        # Allow .vibe/hooks and validate-write paths for Infra role
        if rel.startswith(".vibe/hooks") or "validate-write" in rel or "validate_write" in rel:
            sys.exit(0)

    sys.exit(0)

main()
' <<< "$(cat /dev/stdin)"
