#!/bin/bash
# VibeFlow Playwright Smoke Test
# Runs a minimal Playwright test suite as a quick UI health check.
#
# Usage:
#   playwright_smoke.sh [options]
#   playwright_smoke.sh --help
#
# Options:
#   --headed        Run in headed mode (visible browser)
#   --project <p>   Playwright project to run (default: chromium)
#   --help          Show this help

set -euo pipefail

PROJECT_DIR="${VIBEFLOW_PROJECT_DIR:-.}"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Run Playwright smoke tests for quick UI health check."
    echo ""
    echo "Options:"
    echo "  --headed        Run in headed mode (visible browser)"
    echo "  --project <p>   Playwright project (default: chromium)"
    echo "  --help          Show this help"
    exit 0
}

HEADED=""
PW_PROJECT="chromium"

while [[ $# -gt 0 ]]; do
    case $1 in
        --headed) HEADED="--headed"; shift ;;
        --project) PW_PROJECT="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

# --- Pre-checks ---
cd "$PROJECT_DIR"

if ! command -v npx &>/dev/null; then
    log_error "npx not found. Install Node.js first."
    exit 1
fi

if [ ! -f "playwright.config.js" ] && [ ! -f "playwright.config.ts" ]; then
    log_error "No playwright.config found in ${PROJECT_DIR}"
    log_info "Run 'npx playwright install' and create a config first."
    exit 1
fi

# --- Run smoke tests ---
log_info "Running Playwright smoke tests (project: ${PW_PROJECT})"

npx playwright test \
    --project="$PW_PROJECT" \
    --reporter=list \
    $HEADED \
    2>&1

EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
    log_ok "Smoke tests passed"
else
    log_error "Smoke tests failed (exit ${EXIT_CODE})"
    log_info "Run 'npx playwright show-report' to see details"
    exit "$EXIT_CODE"
fi
