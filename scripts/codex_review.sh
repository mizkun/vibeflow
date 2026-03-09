#!/bin/bash
# VibeFlow Codex Review Script
# Runs a structured code review using Codex (or compatible tool).
#
# Usage:
#   codex_review.sh --pr <number>              Review a PR by number
#   codex_review.sh --diff <file>              Review a diff file
#   codex_review.sh --help                     Show this help
#
# Environment:
#   VIBEFLOW_CODEX_CMD      Codex command (default: codex)
#   VIBEFLOW_PROJECT_DIR    Project directory (default: .)
#   VIBEFLOW_FRAMEWORK_DIR  Framework directory (default: auto-detect)
#
# Output:
#   Structured JSON review saved to .vibe/reviews/

set -euo pipefail

# --- Configuration ---
CODEX_CMD="${VIBEFLOW_CODEX_CMD:-codex}"
PROJECT_DIR="${VIBEFLOW_PROJECT_DIR:-.}"
FRAMEWORK_DIR="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
OUTPUT_DIR=""
INPUT_MODE=""
INPUT_VALUE=""

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
    echo "Run a structured code review using Codex."
    echo "Uses AGENTS.md as the instruction layer for Codex."
    echo ""
    echo "Input (one required):"
    echo "  --pr <number>        Review a GitHub PR by number"
    echo "  --diff <file>        Review a diff file"
    echo ""
    echo "Options:"
    echo "  --output-dir <dir>   Output directory (default: .vibe/reviews/)"
    echo "  --help               Show this help"
    echo ""
    echo "Environment variables:"
    echo "  VIBEFLOW_CODEX_CMD       Codex command (default: codex)"
    echo "  VIBEFLOW_PROJECT_DIR     Project directory (default: .)"
    echo "  VIBEFLOW_FRAMEWORK_DIR   Framework directory"
    echo ""
    echo "Output:"
    echo "  Structured JSON review in .vibe/reviews/"
    echo "  Schema: { identifier, findings[], summary, passed }"
    exit 0
}

# --- Argument parsing ---
if [ $# -eq 0 ]; then
    echo "Usage: $(basename "$0") --pr <number> | --diff <file>"
    echo "Run '$(basename "$0") --help' for details."
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --pr)
            INPUT_MODE="pr"
            INPUT_VALUE="$2"
            shift 2
            ;;
        --diff)
            INPUT_MODE="diff"
            INPUT_VALUE="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
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

# --- Validate input ---
if [ -z "$INPUT_MODE" ]; then
    log_error "Input required: --pr <number> or --diff <file>"
    exit 1
fi

# Set default output dir
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="${PROJECT_DIR}/.vibe/reviews"
fi
mkdir -p "$OUTPUT_DIR"

# --- Determine identifier ---
IDENTIFIER=""
DIFF_CONTENT=""

if [ "$INPUT_MODE" = "pr" ]; then
    IDENTIFIER="pr-${INPUT_VALUE}"
    log_info "Reviewing PR #${INPUT_VALUE}"

    # Get PR diff
    if command -v gh &>/dev/null; then
        DIFF_CONTENT=$(gh pr diff "$INPUT_VALUE" 2>/dev/null || echo "")
    fi

    if [ -z "$DIFF_CONTENT" ]; then
        log_error "Could not fetch PR #${INPUT_VALUE} diff"
        exit 1
    fi

elif [ "$INPUT_MODE" = "diff" ]; then
    if [ ! -f "$INPUT_VALUE" ]; then
        log_error "Diff file not found: $INPUT_VALUE"
        exit 1
    fi
    IDENTIFIER="diff-$(basename "$INPUT_VALUE" .diff)"
    DIFF_CONTENT=$(cat "$INPUT_VALUE")
    log_info "Reviewing diff file: $INPUT_VALUE"
fi

# --- Find AGENTS.md ---
AGENTS_MD=""
if [ -f "${PROJECT_DIR}/AGENTS.md" ]; then
    AGENTS_MD="${PROJECT_DIR}/AGENTS.md"
elif [ -f "${FRAMEWORK_DIR}/examples/AGENTS.md" ]; then
    AGENTS_MD="${FRAMEWORK_DIR}/examples/AGENTS.md"
fi

if [ -n "$AGENTS_MD" ]; then
    log_info "Using instruction layer: $(basename "$AGENTS_MD")"
fi

# --- Build review prompt ---
REVIEW_PROMPT="Review the following code changes. For each issue found, output in this exact format:

## Review Summary
<summary of findings>

### Finding N
- File: <file path>
- Line: <line number>
- Severity: <error|warning|info>
- Issue: <description>
- Suggestion: <how to fix>

If no issues are found, output:
## Review Summary
No issues found.

Code changes to review:
${DIFF_CONTENT}"

# --- Execute Codex review ---
log_info "Running review with: ${CODEX_CMD}"

RAW_OUTPUT=""
if [ -n "$AGENTS_MD" ]; then
    RAW_OUTPUT=$($CODEX_CMD "$REVIEW_PROMPT" 2>/dev/null || echo "## Review Summary
Review execution failed.")
else
    RAW_OUTPUT=$($CODEX_CMD "$REVIEW_PROMPT" 2>/dev/null || echo "## Review Summary
Review execution failed.")
fi

# --- Parse and save results ---
log_info "Parsing review results"

REVIEW_FILE=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.runtime.codex_review import parse_review, save_review

raw_output = sys.stdin.read()
review = parse_review(raw_output, identifier='${IDENTIFIER}')
path = save_review('${OUTPUT_DIR}', review)
print(path)
" <<< "$RAW_OUTPUT" 2>/dev/null)

if [ -n "$REVIEW_FILE" ] && [ -f "$REVIEW_FILE" ]; then
    log_ok "Review saved: ${REVIEW_FILE}"

    # Show summary
    python3 -c "
import json
with open('${REVIEW_FILE}') as f:
    r = json.load(f)
passed = '✓ PASSED' if r['passed'] else '✗ FAILED'
print(f'  Result: {passed}')
print(f'  Findings: {r[\"finding_count\"]}')
if r['summary']:
    print(f'  Summary: {r[\"summary\"][:100]}')
" 2>/dev/null || true
else
    log_error "Failed to save review results"
    exit 1
fi
