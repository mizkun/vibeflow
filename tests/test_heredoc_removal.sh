#!/bin/bash

# VibeFlow Test: Issue 0-2 — heredoc 廃止（コピーベース生成への統一）
# lib/create_access_guard.sh and lib/create_claude_settings.sh must NOT use
# heredocs to write file contents. They should copy from examples/ instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
# Static analysis: no heredocs that write file contents
# ──────────────────────────────────────────────

describe "create_access_guard.sh has no content-writing heredocs"

test_no_heredoc_in_create_access_guard() {
    # Should NOT contain 'cat >' or 'cat >>' followed by heredoc patterns writing hook file contents
    if grep -qE 'cat\s*>\s*"\$hook_file"\s*<<' "${FRAMEWORK_DIR}/lib/create_access_guard.sh"; then
        fail "create_access_guard.sh still contains heredoc file generation (cat > \"\$hook_file\" <<)"
        return 1
    fi
}
run_test "create_access_guard.sh does not use heredocs for file content" test_no_heredoc_in_create_access_guard

describe "create_claude_settings.sh has no content-writing heredocs for notification hooks"

test_no_heredoc_in_notification_hooks() {
    # The create_notification_hooks function should not use 'cat >' heredocs
    # We check for 'cat >' patterns that write to hook script variables
    if grep -qE 'cat\s*>\s*"\$(task_complete|waiting_input|checkpoint_alert)"\s*<<' "${FRAMEWORK_DIR}/lib/create_claude_settings.sh"; then
        fail "create_claude_settings.sh still contains heredoc file generation in create_notification_hooks"
        return 1
    fi
}
run_test "create_claude_settings.sh does not use heredocs for notification hooks" test_no_heredoc_in_notification_hooks

# ──────────────────────────────────────────────
# Functional: generated files match examples/
# ──────────────────────────────────────────────

describe "create_access_guard() produces files matching examples/"

test_create_access_guard_matches_example() {
    mkdir -p .vibe/hooks
    source "${FRAMEWORK_DIR}/lib/create_access_guard.sh"
    create_access_guard >/dev/null 2>&1

    diff -q ".vibe/hooks/validate_access.py" "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_access.py" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        fail "validate_access.py does not match examples/"
        return 1
    fi
}
run_test "create_access_guard() output matches examples/validate_access.py" test_create_access_guard_matches_example

test_create_write_guard_matches_example() {
    mkdir -p .vibe/hooks
    source "${FRAMEWORK_DIR}/lib/create_access_guard.sh"
    create_write_guard >/dev/null 2>&1

    diff -q ".vibe/hooks/validate_write.sh" "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_write.sh" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        fail "validate_write.sh does not match examples/"
        return 1
    fi
}
run_test "create_write_guard() output matches examples/validate_write.sh" test_create_write_guard_matches_example

test_create_step7a_guard_matches_example() {
    mkdir -p .vibe/hooks .vibe/checkpoints
    source "${FRAMEWORK_DIR}/lib/create_access_guard.sh"
    create_step7a_guard >/dev/null 2>&1

    diff -q ".vibe/hooks/validate_step7a.py" "${FRAMEWORK_DIR}/examples/.vibe/hooks/validate_step7a.py" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        fail "validate_step7a.py does not match examples/"
        return 1
    fi
}
run_test "create_step7a_guard() output matches examples/validate_step7a.py" test_create_step7a_guard_matches_example

describe "create_notification_hooks() produces files matching examples/"

test_notification_hooks_match_examples() {
    mkdir -p .vibe/hooks .vibe/templates
    source "${FRAMEWORK_DIR}/lib/create_claude_settings.sh"
    create_notification_hooks >/dev/null 2>&1

    local failed=0

    for hook in task_complete.sh waiting_input.sh checkpoint_alert.sh; do
        diff -q ".vibe/hooks/$hook" "${FRAMEWORK_DIR}/examples/.vibe/hooks/$hook" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            fail "$hook does not match examples/"
            failed=1
        fi
    done

    return $failed
}
run_test "create_notification_hooks() output matches examples/ hooks" test_notification_hooks_match_examples

# ──────────────────────────────────────────────
# Verify chmod +x is applied
# ──────────────────────────────────────────────

describe "Generated files are executable"

test_access_guard_executable() {
    mkdir -p .vibe/hooks
    source "${FRAMEWORK_DIR}/lib/create_access_guard.sh"
    create_access_guard >/dev/null 2>&1

    if [ ! -x ".vibe/hooks/validate_access.py" ]; then
        fail "validate_access.py should be executable"
        return 1
    fi
}
run_test "validate_access.py is executable after creation" test_access_guard_executable

test_notification_hooks_executable() {
    mkdir -p .vibe/hooks .vibe/templates
    source "${FRAMEWORK_DIR}/lib/create_claude_settings.sh"
    create_notification_hooks >/dev/null 2>&1

    local failed=0
    for hook in task_complete.sh waiting_input.sh checkpoint_alert.sh; do
        if [ ! -x ".vibe/hooks/$hook" ]; then
            fail "$hook should be executable"
            failed=1
        fi
    done
    return $failed
}
run_test "notification hooks are executable after creation" test_notification_hooks_executable

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────

print_summary
