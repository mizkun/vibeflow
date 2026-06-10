#!/bin/bash
# Stop Test Gate Hook
# Called by Stop hook when Claude Code stops. If the Coding Agent is at a
# coding step (4_test_writing, 5_implementation, 6_refactoring), run tests.
# On failure: exit 2 (blocks stop, sends agent back to work)
# On success or non-coding context: exit 0 (allow stop)

set -uo pipefail

# ──────────────────────────────────────────────
# 1. Loop prevention
# ──────────────────────────────────────────────
# Primary: Claude Code sets stop_hook_active=true in the hook input JSON
# when the stop was already blocked once this turn — never block again.
STDIN_JSON=""
if [ ! -t 0 ]; then
    STDIN_JSON=$(cat 2>/dev/null || true)
fi
if [ -n "$STDIN_JSON" ]; then
    STOP_HOOK_ACTIVE=$(printf '%s' "$STDIN_JSON" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print("true" if data.get("stop_hook_active") else "false")
except Exception:
    print("false")
' 2>/dev/null || echo "false")
    if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
        exit 0
    fi
fi

# Secondary safety valve: count consecutive blocked stops per project.
# Reset on test success; after MAX_BLOCKS, pass through and tell the
# agent to escalate instead of looping forever on permanently red tests.
PROJECT_HASH=$(echo "${CLAUDE_PROJECT_DIR:-.}" | (md5sum 2>/dev/null || md5 2>/dev/null) | cut -c1-8)
COUNTER_FILE="/tmp/vibeflow_stop_gate_${PROJECT_HASH}"
MAX_BLOCKS=3

# ──────────────────────────────────────────────
# 2. Read state (session-based first, legacy fallback)
# ──────────────────────────────────────────────
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE=""

# session-based state (authoritative)
if [ -n "${VIBEFLOW_SESSION:-}" ]; then
    SESSION_FILE="${PROJECT_ROOT}/.vibe/sessions/${VIBEFLOW_SESSION}.yaml"
    if [ -f "$SESSION_FILE" ]; then
        STATE_FILE="$SESSION_FILE"
    fi
fi

# Legacy fallback: .vibe/state.yaml
if [ -z "$STATE_FILE" ]; then
    STATE_FILE="${PROJECT_ROOT}/.vibe/state.yaml"
fi

if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

CURRENT_ROLE=$(grep -E "^current_role:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/current_role:[[:space:]]*//' | tr -d '"' | tr -d "'" || true)
CURRENT_STEP=$(grep -E "^current_step:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/current_step:[[:space:]]*//' | tr -d '"' | tr -d "'" || true)

# If we can't parse, don't block
if [ -z "$CURRENT_ROLE" ] || [ -z "$CURRENT_STEP" ]; then
    exit 0
fi

# ──────────────────────────────────────────────
# 3. Only gate coding steps
# ──────────────────────────────────────────────
ROLE_LOWER=$(echo "$CURRENT_ROLE" | tr '[:upper:]' '[:lower:]')

case "$ROLE_LOWER" in
    *coding\ agent*|*coding_agent*) ;;
    *) exit 0 ;;
esac

case "$CURRENT_STEP" in
    4_test_writing|5_implementation|6_refactoring) ;;
    *) exit 0 ;;
esac

# ──────────────────────────────────────────────
# 4. Detect test runner
# ──────────────────────────────────────────────
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TEST_CMD=""

if [ -f "${PROJECT_DIR}/package.json" ]; then
    # Check for "test" script in package.json
    if grep -q '"test"' "${PROJECT_DIR}/package.json" 2>/dev/null; then
        TEST_CMD="npm test"
    fi
elif [ -f "${PROJECT_DIR}/pytest.ini" ]; then
    TEST_CMD="pytest"
elif [ -f "${PROJECT_DIR}/pyproject.toml" ] && grep -q '\[tool\.pytest' "${PROJECT_DIR}/pyproject.toml" 2>/dev/null; then
    TEST_CMD="pytest"
elif [ -f "${PROJECT_DIR}/Makefile" ] && grep -qE '^test:' "${PROJECT_DIR}/Makefile" 2>/dev/null; then
    TEST_CMD="make test"
elif [ -f "${PROJECT_DIR}/tests/run_tests.sh" ]; then
    TEST_CMD="bash tests/run_tests.sh"
fi

if [ -z "$TEST_CMD" ]; then
    exit 0
fi

# ──────────────────────────────────────────────
# 5. Run tests
# ──────────────────────────────────────────────
TEST_OUTPUT=$(cd "$PROJECT_DIR" && $TEST_CMD 2>&1) && TEST_RC=0 || TEST_RC=$?

if [ "$TEST_RC" -eq 0 ]; then
    # ──────────────────────────────────────────
    # 6. Success: reset block counter and allow stop
    # ──────────────────────────────────────────
    rm -f "$COUNTER_FILE"
    exit 0
fi

# ──────────────────────────────────────────────
# 7. Failure: block (exit 2) up to MAX_BLOCKS consecutive times
# ──────────────────────────────────────────────
BLOCKS=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
case "$BLOCKS" in
    ''|*[!0-9]*) BLOCKS=0 ;;
esac

if [ "$BLOCKS" -ge "$MAX_BLOCKS" ]; then
    rm -f "$COUNTER_FILE"
    echo "stop_test_gate: テストが ${MAX_BLOCKS} 回連続で失敗したため停止を許可します。これ以上の自動リトライは行わず、needs_human として人間にエスカレーションしてください。" >&2
    exit 0
fi

echo $((BLOCKS + 1)) > "$COUNTER_FILE"

# exit 2 feeds stderr back to Claude — the message must go there.
{
    echo "テストが通っていません。修正してください。(blocked stop $((BLOCKS + 1))/${MAX_BLOCKS})"
    echo ""
    echo "$TEST_OUTPUT" | tail -50
} >&2
exit 2
