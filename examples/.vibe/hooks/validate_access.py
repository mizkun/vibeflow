#!/usr/bin/env python3
"""
VibeFlow Access Guard Hook
Validates file access permissions based on current role in .vibe/state.yaml.
Used as a PreToolUse hook to block unauthorized file edits.
Exit code 2 blocks the tool call (Claude Code specification).
"""

import fnmatch
import json
import os
import sys

# ---------------------------
# Role-based edit permissions
# ---------------------------
# NOTE:
# - Keep this minimal - it's a safety guard, not a comprehensive ACL.
# - If in doubt, fix the role in state.yaml before editing, don't expand permissions.

ROLE_EDIT_ALLOW = {
    "Product Manager": [
        "plan.md",
        "spec.md",
        "vision.md",
        "issues/*",
        ".vibe/discussions/*",
        ".vibe/state.yaml",
    ],
    "Engineer": [
        "src/*",
        "tests/*",
        "**/*.test.*",
        "**/__tests__/*",
        ".vibe/state.yaml",
        ".vibe/test-results.log",
    ],
    "QA Engineer": [
        ".vibe/qa-reports/*",
        ".vibe/test-results.log",
        ".vibe/state.yaml",
    ],
    # Discussion Partner - discussions, state, and vision/spec/plan (for /conclude reflection)
    "Discussion Partner": [
        ".vibe/discussions/*",
        ".vibe/state.yaml",
        "vision.md",
        "spec.md",
        "plan.md",
    ],
    # Infrastructure Manager - hooks and state
    "Infrastructure Manager": [
        ".vibe/hooks/*",
        "validate-write*",
        "validate_write*",
        ".vibe/state.yaml",
    ],
    # Human checkpoint - only state updates allowed
    "Human": [
        ".vibe/state.yaml",
    ],
}

# Files that are always allowed regardless of role
ALWAYS_ALLOW = [".vibe/state.yaml"]


def project_root() -> str:
    """Get project root from CLAUDE_PROJECT_DIR or current directory."""
    return os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()


def read_current_role(state_path: str) -> str:
    """Read current_role from state.yaml."""
    try:
        with open(state_path, "r", encoding="utf-8") as f:
            for line in f:
                s = line.strip()
                if s.startswith("current_role:"):
                    return s.split(":", 1)[1].strip().strip('"').strip("'")
    except FileNotFoundError:
        return ""
    return ""


def match_any(path: str, patterns: list) -> bool:
    """Check if path matches any of the given glob patterns."""
    p = path.lstrip("./")
    for pat in patterns:
        if fnmatch.fnmatch(p, pat):
            return True
        # Also try matching with ** prefix for nested paths
        if fnmatch.fnmatch(p, f"**/{pat}"):
            return True
    return False


def get_target_paths(tool_name: str, tool_input: dict) -> list:
    """Extract target file paths from tool input."""
    # Claude Code hook input varies by tool, pick up common keys
    if tool_name in ("Write", "Edit", "MultiEdit", "Read"):
        p = tool_input.get("file_path") or tool_input.get("path") or ""
        return [p] if p else []
    
    # Fallback for batch operations
    paths = []
    for k in ("file_paths", "paths"):
        v = tool_input.get(k)
        if isinstance(v, list):
            paths.extend([str(x) for x in v])
    return paths


def block(msg: str) -> None:
    """Print error message and exit with code 2 to block tool call."""
    print(msg, file=sys.stderr)
    # exit code 2: blocks PreToolUse tool call (Claude Code specification)
    sys.exit(2)


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        # If hook input is broken, don't stop development - pass through
        sys.exit(0)

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}

    # Only guard write operations (blocking Read would be inconvenient)
    if tool_name not in ("Write", "Edit", "MultiEdit"):
        sys.exit(0)

    root = project_root()
    state_path = os.path.join(root, ".vibe", "state.yaml")
    role = read_current_role(state_path) or ""
    allow = ROLE_EDIT_ALLOW.get(role, [])

    targets = get_target_paths(tool_name, tool_input)

    for t in targets:
        # Skip if path couldn't be extracted (edge cases)
        if not t:
            continue
        
        if match_any(t, ALWAYS_ALLOW):
            continue
        
        if not match_any(t, allow):
            block(
                f"[VibeFlow AccessGuard]\n"
                f"current_role='{role}' では '{t}' を編集できません。\n"
                f"許可パターン: {allow}\n\n"
                f"対処:\n"
                f"  1) `.vibe/state.yaml` の current_role を正しいロールに遷移してから\n"
                f"  2) そのロールのステップで編集してください。\n"
            )

    sys.exit(0)


if __name__ == "__main__":
    main()

