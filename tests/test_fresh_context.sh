#!/bin/bash

# Tests Issue-level fresh context: execute-issue's coding part is
# delegated (Agent tool sub-agent / headless), and the wrapper used for
# the headless path doesn't deadlock when the child writes a lot to
# stderr (the unread-PIPE bug — both stdout and stderr were PIPEd and
# only stdout was ever read, so a chatty worker fills the stderr buffer
# and blocks forever).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "execute-issue — coding part is delegated (fresh context)"

test_skill_delegates_coding() {
    local skill="${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-execute-issue/SKILL.md"
    assert_file_contains "$skill" "サブエージェント\|Agent tool\|headless\|claude -p" \
        "Step 4-6 must be delegated to a sub-agent / headless run, not run inline" || return 1
    assert_file_contains "$skill" "コンテキスト" \
        "the skill should explain the context-isolation rationale" || return 1
}
run_test "skill delegates the coding part" test_skill_delegates_coding

# ──────────────────────────────────────────────
describe "wrapper — no deadlock on a chatty stderr"

test_no_stderr_deadlock() {
    command -v timeout >/dev/null 2>&1 || command -v gtimeout >/dev/null 2>&1 || return 0
    local TO; TO="$(command -v timeout || command -v gtimeout)"

    # Fake claude: write 200KB to stderr, then valid JSON to stdout.
    # With both pipes PIPEd and only stdout read, the child blocks at
    # ~64KB of stderr and the wrapper hangs until timeout.
    local fake="${TEST_DIR}/fakeclaude"
    cat > "$fake" << 'SH'
#!/bin/bash
yes "noise line to fill the stderr pipe buffer well past 64KB ........" | head -3000 >&2
echo '{"type":"result","subtype":"success","result":"done"}'
SH
    chmod +x "$fake"

    local out
    out=$("$TO" 30 python3 -c "
import sys, time
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.claude_code_wrapper import ClaudeCodeWrapper
w = ClaudeCodeWrapper(claude_cmd='${fake}')
h = w.dispatch('do it', work_dir='${TEST_DIR}', session_dir='${TEST_DIR}/.vibe/sessions')
# wait for completion
for _ in range(100):
    h = w.poll(h)
    if h['status'] in ('completed','failed','timeout'):
        break
    time.sleep(0.1)
r = w.collect(h)
print(h['status'], r['parsed'].get('status'))
" 2>/dev/null) || {
        fail "wrapper deadlocked on a chatty stderr (timed out)"
        return 1
    }
    echo "$out" | grep -q "completed success" || {
        fail "wrapper must complete and parse the JSON despite heavy stderr, got: '$out'"
        return 1
    }
}
run_test "wrapper survives a chatty stderr without deadlock" test_no_stderr_deadlock

print_summary
