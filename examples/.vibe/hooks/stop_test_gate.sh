#!/bin/bash
# Stop Test Gate Hook
# Called by Stop hook when Claude Code stops. If the Coding Agent is at a
# coding step (4_test_writing, 5_implementation, 6_refactoring), run tests.
# On failure: exit 2 (blocks stop, sends agent back to work)
# On success or non-coding context: exit 0 (allow stop)

set -uo pipefail

# ──────────────────────────────────────────────
# 1. Infinite loop prevention
# ──────────────────────────────────────────────
FLAG_FILE="/tmp/vibeflow_stop_gate_active"

if [ -f "$FLAG_FILE" ]; then
    exit 0
fi

touch "$FLAG_FILE"
trap 'rm -f "$FLAG_FILE"' EXIT

# ──────────────────────────────────────────────
# 2. Read state
# ──────────────────────────────────────────────
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.vibe/state.yaml"

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
    # 7. Success: exit 0
    # ──────────────────────────────────────────
    exit 0
else
    # ──────────────────────────────────────────
    # 6. Failure: print message and exit 2
    # ──────────────────────────────────────────
    echo "テストが通っていません。修正してください。"
    echo ""
    echo "$TEST_OUTPUT" | tail -50
    exit 2
fi
