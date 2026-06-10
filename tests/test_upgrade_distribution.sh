#!/bin/bash

# Tests that upgrade does not resurrect deprecated commands, and that a
# current-release baseline exists so a manifest-less project classifies.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "upgrade — deprecated commands are not distributed"

test_deprecated_commands_removed() {
    for dead in next next-v2-extension; do
        assert_file_not_exists "${FRAMEWORK_DIR}/lib/commands/${dead}.md" \
            "deprecated command ${dead}.md must not be shipped (upgrade glob would resurrect it)" || return 1
    done
    return 0
}
run_test "deprecated command files are gone" test_deprecated_commands_removed

test_source_map_excludes_deprecated() {
    local result
    result=$(python3 -c "
import sys
sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.upgrade import build_source_map
m = build_source_map('${FRAMEWORK_DIR}')
dead = [k for k in m if k.endswith('/next.md') or k.endswith('/next-v2-extension.md')]
print('DEAD' if dead else 'OK')
")
    assert_equals "OK" "$result" "upgrade source map must not include deprecated commands"
}
run_test "upgrade source map excludes deprecated commands" test_source_map_excludes_deprecated

# ──────────────────────────────────────────────
describe "baselines — current release is covered"

test_v6_baseline_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/baselines/v6.0.0.json" \
        "a v6.0.0 baseline must exist so manifest-less v6 projects classify"
}
run_test "v6.0.0 baseline exists" test_v6_baseline_exists

test_v6_baseline_matches_a_stable_file() {
    local result
    result=$(python3 -c "
import hashlib, json, os
b = json.load(open('${FRAMEWORK_DIR}/core/baselines/v6.0.0.json'))['files']
p = '.vibe/hooks/validate_access.py'
src = os.path.join('${FRAMEWORK_DIR}', 'examples', p)
actual = hashlib.sha256(open(src,'rb').read()).hexdigest()
print('OK' if b.get(p, {}).get('sha256') == actual else 'MISMATCH')
")
    assert_equals "OK" "$result" "the v6.0.0 baseline must record the current generated hashes"
}
run_test "v6.0.0 baseline matches current generated files" test_v6_baseline_matches_a_stable_file

test_make_baseline_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/scripts/make_baseline.py" \
        "a make_baseline helper must exist for future releases"
}
run_test "make_baseline.py exists" test_make_baseline_script_exists

print_summary
