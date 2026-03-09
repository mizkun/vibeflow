#!/bin/bash
# VibeFlow Codex Implementation Script
# Executes a development task using Codex in a git worktree.
#
# Usage:
#   codex_impl.sh --packet <path>    Run implementation from handoff packet
#   codex_impl.sh --help             Show this help
#
# Environment:
#   VIBEFLOW_CODEX_CMD       Codex command (default: codex)
#   VIBEFLOW_PROJECT_DIR     Project directory (default: .)
#   VIBEFLOW_FRAMEWORK_DIR   Framework directory (default: auto-detect)
#
# Flow:
#   1. Load and validate handoff packet
#   2. Create git worktree for isolation
#   3. Build instruction context from AGENTS.md
#   4. Execute Codex in worktree
#   5. Validate diff (allowed_paths, forbidden_paths, max_files_changed)
#   6. Run validation commands
#   7. Report results (NO auto-merge)

set -euo pipefail

# --- Configuration ---
CODEX_CMD="${VIBEFLOW_CODEX_CMD:-codex}"
PROJECT_DIR="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK_DIR="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Usage ---
usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Run a development task using Codex in an isolated git worktree."
    echo "Uses AGENTS.md as the instruction layer for Codex."
    echo ""
    echo "Options:"
    echo "  --packet <path>    Handoff packet JSON file (required)"
    echo "  --help             Show this help"
    echo ""
    echo "Environment variables:"
    echo "  VIBEFLOW_CODEX_CMD       Codex command (default: codex)"
    echo "  VIBEFLOW_PROJECT_DIR     Project directory (default: .)"
    echo "  VIBEFLOW_FRAMEWORK_DIR   Framework directory"
    echo ""
    echo "Safety:"
    echo "  - Runs in isolated git worktree (no direct changes to main)"
    echo "  - Validates diff against allowed_paths/forbidden_paths/max_files_changed"
    echo "  - NO auto-merge — results stay on feature branch"
    exit 0
}

# --- Argument parsing ---
PACKET_PATH=""

if [ $# -eq 0 ]; then
    echo "Usage: $(basename "$0") --packet <path>"
    echo "Run '$(basename "$0") --help' for details."
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --packet)
            PACKET_PATH="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$PACKET_PATH" ]; then
    log_error "Packet path required: --packet <path>"
    exit 1
fi

if [ ! -f "$PACKET_PATH" ]; then
    log_error "Packet file not found: $PACKET_PATH"
    exit 1
fi

# --- Load packet ---
log_info "Loading handoff packet: ${PACKET_PATH}"

PACKET_DATA=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import load_and_validate_packet

packet = load_and_validate_packet('${PACKET_PATH}')
print(json.dumps(packet))
" 2>&1)

if [ $? -ne 0 ]; then
    log_error "Failed to load packet: ${PACKET_DATA}"
    exit 1
fi

TASK_ID=$(echo "$PACKET_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['task_id'])")
log_info "Task: ${TASK_ID}"

# --- Generate branch name ---
BRANCH_NAME=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import make_branch_name
print(make_branch_name('${TASK_ID}'))
")

log_info "Branch: ${BRANCH_NAME}"

# --- Create worktree ---
WORKTREE_DIR="${PROJECT_DIR}/.vibe/worktrees/${TASK_ID}"
mkdir -p "$(dirname "$WORKTREE_DIR")"

cd "$PROJECT_DIR"

# Create branch and worktree
git branch "$BRANCH_NAME" 2>/dev/null || true
git worktree add "$WORKTREE_DIR" "$BRANCH_NAME" 2>/dev/null || {
    log_error "Failed to create worktree at ${WORKTREE_DIR}"
    exit 1
}

log_info "Worktree created: ${WORKTREE_DIR}"

# --- Find AGENTS.md (instruction layer) ---
AGENTS_MD=""
if [ -f "${PROJECT_DIR}/AGENTS.md" ]; then
    AGENTS_MD="${PROJECT_DIR}/AGENTS.md"
elif [ -f "${FRAMEWORK_DIR}/examples/AGENTS.md" ]; then
    AGENTS_MD="${FRAMEWORK_DIR}/examples/AGENTS.md"
fi

# --- Build instruction context ---
INSTRUCTION_CONTEXT=""
if [ -n "$AGENTS_MD" ]; then
    log_info "Using AGENTS.md as instruction layer: ${AGENTS_MD}"
    INSTRUCTION_CONTEXT="$(cat "$AGENTS_MD")

---

"
else
    log_info "No AGENTS.md found (no instruction layer)"
fi

# --- Read must_read files ---
MUST_READ_CONTENT=""
MUST_READ=$(echo "$PACKET_DATA" | python3 -c "
import sys, json
packet = json.load(sys.stdin)
for f in packet.get('must_read', []):
    print(f)
" 2>/dev/null || true)

if [ -n "$MUST_READ" ]; then
    while IFS= read -r must_file; do
        if [ -f "${WORKTREE_DIR}/${must_file}" ]; then
            MUST_READ_CONTENT="${MUST_READ_CONTENT}
--- ${must_file} ---
$(cat "${WORKTREE_DIR}/${must_file}")
"
        fi
    done <<< "$MUST_READ"
fi

# --- Build implementation prompt ---
GOAL=$(echo "$PACKET_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['goal'])")

IMPL_PROMPT="${INSTRUCTION_CONTEXT}Implement the following task:

Goal: ${GOAL}

${MUST_READ_CONTENT}

Work in the current directory. Make changes only to files within the allowed paths.
Commit your changes when done."

# --- Execute Codex ---
log_info "Running implementation with: ${CODEX_CMD}"

cd "$WORKTREE_DIR"

CODEX_EXIT=0
if [ -n "$AGENTS_MD" ]; then
    $CODEX_CMD --instructions "$AGENTS_MD" "$IMPL_PROMPT" 2>/dev/null || \
    $CODEX_CMD "$IMPL_PROMPT" 2>/dev/null || CODEX_EXIT=$?
else
    $CODEX_CMD "$IMPL_PROMPT" 2>/dev/null || CODEX_EXIT=$?
fi

if [ "$CODEX_EXIT" -ne 0 ]; then
    log_error "Codex execution failed (exit ${CODEX_EXIT})"
    exit 1
fi

# --- Validate diff ---
log_info "Validating changes"

# Collect all changed files: committed (vs initial), staged, and unstaged
CHANGED_FILES=$(
    {
        git diff --name-only HEAD~1 2>/dev/null || true
        git diff --name-only --cached 2>/dev/null || true
        git diff --name-only 2>/dev/null || true
        git ls-files --others --exclude-standard 2>/dev/null || true
    } | sort -u
)

if [ -n "$CHANGED_FILES" ]; then
    VALIDATION_RESULT=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import validate_diff

changed = '''${CHANGED_FILES}'''.strip().split('\n')
packet = json.loads('''${PACKET_DATA}''')
constraints = packet.get('constraints', {})
errors = validate_diff(changed, constraints)
if errors:
    for e in errors:
        print(f'ERROR: {e}')
else:
    print('OK')
" 2>/dev/null)

    if [ "$VALIDATION_RESULT" != "OK" ]; then
        log_error "Diff validation failed:"
        echo "$VALIDATION_RESULT"
        exit 1
    else
        log_ok "Diff validation passed"
    fi
fi

# --- Run validation commands ---
VALIDATION_CMDS=$(echo "$PACKET_DATA" | python3 -c "
import sys, json
packet = json.load(sys.stdin)
for cmd in packet.get('validation', {}).get('required_commands', []):
    print(cmd)
" 2>/dev/null || true)

if [ -n "$VALIDATION_CMDS" ]; then
    log_info "Running validation commands"
    CMD_ERRORS=$(python3 -c "
import sys, json
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_impl import run_validation

packet = json.loads('''${PACKET_DATA}''')
commands = packet.get('validation', {}).get('required_commands', [])
errors = run_validation(commands, cwd='${WORKTREE_DIR}')
if errors:
    for e in errors:
        print(f'ERROR: {e}')
else:
    print('OK')
" 2>/dev/null)

    if [ "$CMD_ERRORS" != "OK" ]; then
        log_error "Validation commands failed:"
        echo "$CMD_ERRORS"
        exit 1
    else
        log_ok "All validation commands passed"
    fi
fi

# --- Report results ---
log_info "Implementation complete (no auto-merge)"
log_info "Branch: ${BRANCH_NAME}"
log_info "Worktree: ${WORKTREE_DIR}"
log_ok "Review the changes and merge manually when ready"
