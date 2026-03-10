#!/bin/bash
# chmod +x postwrite_lint.sh
# PostToolUse lint hook — runs linters/formatters after Write/Edit/MultiEdit
# Claude Code passes JSON with tool_name and tool_input on stdin.
# Output goes to stdout as feedback to the agent.
# Always exits 0 (informational only, never blocks).

set -o pipefail

# ──────────────────────────────────────────────
# 1. Read JSON from stdin and extract file_path
# ──────────────────────────────────────────────
INPUT="$(cat 2>/dev/null || true)"

if [ -z "$INPUT" ]; then
    exit 0
fi

# Try python3 first, then jq, then give up
FILE_PATH=""
if command -v python3 &>/dev/null; then
    FILE_PATH="$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    fp = d.get('tool_input', {}).get('file_path', '')
    print(fp)
except Exception:
    pass
" 2>/dev/null || true)"
elif command -v jq &>/dev/null; then
    FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
fi

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# ──────────────────────────────────────────────
# 2. Resolve to absolute path within project
# ──────────────────────────────────────────────
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# If the path is relative, resolve against project dir
case "$FILE_PATH" in
    /*) ABSOLUTE_PATH="$FILE_PATH" ;;
    *)  ABSOLUTE_PATH="${PROJECT_DIR}/${FILE_PATH}" ;;
esac

if [ ! -f "$ABSOLUTE_PATH" ]; then
    exit 0
fi

# ──────────────────────────────────────────────
# 3. Determine extension and run linter
# ──────────────────────────────────────────────
EXT="${FILE_PATH##*.}"

run_js_lint() {
    local file="$1"
    if command -v npx &>/dev/null; then
        # Use --no-install to avoid downloading packages on every edit
        if npx --no-install oxlint --version &>/dev/null 2>&1; then
            npx --no-install oxlint "$file" 2>&1 || true
            return
        fi
        if npx --no-install biome --version &>/dev/null 2>&1; then
            npx --no-install biome check "$file" 2>&1 || true
            return
        fi
        if npx --no-install eslint --version &>/dev/null 2>&1; then
            npx --no-install eslint "$file" 2>&1 || true
            return
        fi
    fi
}

run_py_lint() {
    local file="$1"
    if command -v ruff &>/dev/null; then
        ruff check --fix "$file" 2>&1 || true
        ruff format "$file" 2>&1 || true
        return
    fi
}

run_go_lint() {
    local file="$1"
    local dir
    dir="$(dirname "$file")"
    if command -v golangci-lint &>/dev/null; then
        golangci-lint run "$dir/..." 2>&1 || true
        return
    fi
}

run_rs_lint() {
    local file="$1"
    if command -v cargo &>/dev/null; then
        cargo clippy 2>&1 || true
        return
    fi
}

case "$EXT" in
    ts|tsx|js|jsx)
        run_js_lint "$ABSOLUTE_PATH"
        ;;
    py)
        run_py_lint "$ABSOLUTE_PATH"
        ;;
    go)
        run_go_lint "$ABSOLUTE_PATH"
        ;;
    rs)
        run_rs_lint "$ABSOLUTE_PATH"
        ;;
    *)
        # Unknown extension — do nothing
        ;;
esac

exit 0
