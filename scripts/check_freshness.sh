#!/bin/bash
set -euo pipefail

# VibeFlow Freshness Check
# Verifies that generated files in examples/ match what generators would produce.
# Used by CI to detect schema/template changes without corresponding generate.
#
# Usage:
#   scripts/check_freshness.sh
#
# Exit codes:
#   0 = all generated files are fresh
#   1 = stale files detected (need vibeflow generate)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$(dirname "$SCRIPT_DIR")"

echo "VibeFlow Freshness Check"
echo "────────────────────────"

# Run generate --diff against examples/
output=$(python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
    --schema-dir "${FRAMEWORK_DIR}/core/schema" \
    --project-dir "${FRAMEWORK_DIR}/examples" \
    --framework-dir "${FRAMEWORK_DIR}" \
    --diff 2>&1)

echo "$output"
echo "────────────────────────"

# Check for modifications
if echo "$output" | grep -q "~ .* (modified)"; then
    echo ""
    echo "ERROR: Generated files are stale."
    echo "Run 'vibeflow generate' in the examples/ directory to update:"
    echo ""
    echo "  python3 core/generators/generate_all.py \\"
    echo "    --schema-dir core/schema \\"
    echo "    --project-dir examples \\"
    echo "    --framework-dir ."
    echo ""
    exit 1
fi

if echo "$output" | grep -q "+ .* (new)"; then
    echo ""
    echo "ERROR: New generated files are missing from examples/."
    echo "Run 'vibeflow generate' to create them."
    echo ""
    exit 1
fi

echo ""
echo "All generated files are fresh."
exit 0
