#!/bin/bash
# VibeFlow Playwright Report Viewer
# Opens the Playwright HTML report in the default browser.
#
# Usage:
#   playwright_open_report.sh [report-dir]
#
# Default report directory: playwright-report/

set -euo pipefail

PROJECT_DIR="${VIBEFLOW_PROJECT_DIR:-.}"
REPORT_DIR="${1:-${PROJECT_DIR}/playwright-report}"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ ! -d "$REPORT_DIR" ]; then
    log_error "Report directory not found: ${REPORT_DIR}"
    log_info "Run tests first: npx playwright test"
    exit 1
fi

log_info "Opening Playwright report: ${REPORT_DIR}"

cd "$PROJECT_DIR"
npx playwright show-report "$REPORT_DIR" 2>/dev/null &

log_ok "Report server started. Press Ctrl+C to stop."
wait
