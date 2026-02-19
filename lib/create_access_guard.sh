#!/bin/bash

# Vibe Coding Framework - Access Guard Hook Creation
# This script creates the validate_access.py hook for role-based access control

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create the access guard hook
create_access_guard() {
    section "アクセスガードフックを作成中"
    
    local hook_file=".vibe/hooks/validate_access.py"
    
    info "validate_access.py を作成中..."
    
    # Create the Python script using heredoc to avoid shell expansion issues
    cat > "$hook_file" << 'PYTHON_SCRIPT'
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
    # Iris - project docs, context management, state
    "Iris": [
        "vision.md",
        "spec.md",
        "plan.md",
        ".vibe/context/*",
        ".vibe/references/*",
        ".vibe/archive/*",
        ".vibe/state.yaml",
    ],
    "Product Manager": [
        "plan.md",
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
PYTHON_SCRIPT

    if [ $? -eq 0 ]; then
        # Make the script executable
        chmod +x "$hook_file"
        success "アクセスガードフックを作成しました: $hook_file"
        return 0
    else
        error "アクセスガードフックの作成に失敗しました"
        return 1
    fi
}

# Function to create the write guard hook
create_write_guard() {
    section "書き込みガードフックを作成中"

    local hook_file=".vibe/hooks/validate_write.sh"

    info "validate_write.sh を作成中..."

    cat > "$hook_file" << 'BASH_SCRIPT'
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
                    return s.split(":", 1)[1].strip().strip("\"").strip("'"'"'")
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
BASH_SCRIPT

    if [ $? -eq 0 ]; then
        chmod +x "$hook_file"
        success "書き込みガードフックを作成しました: $hook_file"
        return 0
    else
        error "書き込みガードフックの作成に失敗しました"
        return 1
    fi
}

# Function to verify access guard installation
verify_access_guard() {
    local hook_file=".vibe/hooks/validate_access.py"
    
    if [ ! -f "$hook_file" ]; then
        error "アクセスガードフックが見つかりません: $hook_file"
        return 1
    fi
    
    if [ ! -x "$hook_file" ]; then
        error "アクセスガードフックに実行権限がありません: $hook_file"
        return 1
    fi
    
    # Verify Python syntax
    if python3 -m py_compile "$hook_file" 2>/dev/null; then
        success "アクセスガードフックの構文チェックが完了しました"
        return 0
    else
        warning "アクセスガードフックの構文に問題がある可能性があります"
        return 1
    fi
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_access_guard
fi

