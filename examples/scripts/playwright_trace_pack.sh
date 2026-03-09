#!/bin/bash
# VibeFlow Playwright Trace & Artifact Packer
# Collects trace files, screenshots, and reports into a single archive.
#
# Usage:
#   playwright_trace_pack.sh [options]
#   playwright_trace_pack.sh --help
#
# Options:
#   --output <path>   Output archive path (default: .vibe/artifacts/pw-<timestamp>.tar.gz)
#   --help            Show this help
#
# Collects:
#   - test-results/    (trace files, screenshots, videos)
#   - playwright-report/ (HTML report)

set -euo pipefail

PROJECT_DIR="${VIBEFLOW_PROJECT_DIR:-.}"

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
    echo "Pack Playwright trace, screenshot, and report artifacts."
    echo ""
    echo "Options:"
    echo "  --output <path>   Output archive (default: .vibe/artifacts/pw-<timestamp>.tar.gz)"
    echo "  --help            Show this help"
    echo ""
    echo "Collects from:"
    echo "  test-results/       trace files, screenshots, videos"
    echo "  playwright-report/  HTML report"
    exit 0
}

OUTPUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --output) OUTPUT="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

cd "$PROJECT_DIR"

# Default output path
if [ -z "$OUTPUT" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    OUTPUT=".vibe/artifacts/pw-${TIMESTAMP}.tar.gz"
fi

mkdir -p "$(dirname "$OUTPUT")"

# Collect artifact directories
DIRS_TO_PACK=()

if [ -d "test-results" ]; then
    DIRS_TO_PACK+=("test-results")
    log_info "Including: test-results/ (trace, screenshot, video)"
fi

if [ -d "playwright-report" ]; then
    DIRS_TO_PACK+=("playwright-report")
    log_info "Including: playwright-report/ (HTML report)"
fi

if [ ${#DIRS_TO_PACK[@]} -eq 0 ]; then
    log_error "No Playwright artifacts found"
    log_info "Run tests first: npx playwright test --trace on"
    exit 1
fi

# Create archive
tar -czf "$OUTPUT" "${DIRS_TO_PACK[@]}"

log_ok "Artifacts packed: ${OUTPUT}"
log_info "Contents: ${DIRS_TO_PACK[*]}"
