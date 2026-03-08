#!/bin/bash

# VibeFlow Test: Issue 1-8 — generated-manifest.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Manifest — module exists"

test_manifest_module_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/generators/manifest.py" \
        "core/generators/manifest.py must exist"
}
run_test "manifest.py exists" test_manifest_module_exists

# ──────────────────────────────────────────────
describe "Manifest — creation and update"

test_manifest_created_after_generation() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"

    # Generate a file and record in manifest
    echo "test content" > "${outdir}/test_file.py"
    python3 -c "
import sys; sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.generators.manifest import Manifest
m = Manifest('${outdir}')
m.record('test_file.py', 'core/schema/policy.yaml')
m.save()
" 2>&1 || {
        fail "Manifest record+save should succeed"
        return 1
    }

    assert_file_exists "${outdir}/.vibe/generated-manifest.json" \
        "generated-manifest.json should be created"
}
run_test "Manifest created after recording a file" test_manifest_created_after_generation

test_manifest_contains_file_entry() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"

    echo "test content" > "${outdir}/test_file.py"
    python3 -c "
import sys; sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.generators.manifest import Manifest
m = Manifest('${outdir}')
m.record('test_file.py', 'core/schema/policy.yaml')
m.save()
"

    assert_file_contains "${outdir}/.vibe/generated-manifest.json" "test_file.py" \
        "Manifest should contain the recorded file path"
    assert_file_contains "${outdir}/.vibe/generated-manifest.json" "sha256" \
        "Manifest should contain sha256 hash"
    assert_file_contains "${outdir}/.vibe/generated-manifest.json" "policy.yaml" \
        "Manifest should contain source schema reference"
}
run_test "Manifest entry has path, sha256, source" test_manifest_contains_file_entry

test_manifest_has_generator_version() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"

    echo "test content" > "${outdir}/test_file.py"
    python3 -c "
import sys; sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.generators.manifest import Manifest
m = Manifest('${outdir}', generator_version='2.0.0')
m.record('test_file.py', 'core/schema/policy.yaml')
m.save()
"

    assert_file_contains "${outdir}/.vibe/generated-manifest.json" "generator_version" \
        "Manifest should contain generator_version"
    assert_file_contains "${outdir}/.vibe/generated-manifest.json" "2.0.0" \
        "Manifest should contain the specified version"
}
run_test "Manifest records generator_version" test_manifest_has_generator_version

test_manifest_has_schema_hash() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"

    echo "test content" > "${outdir}/test_file.py"
    python3 -c "
import sys; sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.generators.manifest import Manifest
m = Manifest('${outdir}')
m.record('test_file.py', '${FRAMEWORK_DIR}/core/schema/policy.yaml')
m.save()
"

    assert_file_contains "${outdir}/.vibe/generated-manifest.json" "schema_hash" \
        "Manifest should contain schema_hash for provenance"
}
run_test "Manifest records schema_hash" test_manifest_has_schema_hash

test_manifest_file_type() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"

    echo "test content" > "${outdir}/test_file.py"
    python3 -c "
import sys; sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.generators.manifest import Manifest
m = Manifest('${outdir}')
m.record('test_file.py', 'core/schema/policy.yaml', file_type='full')
m.save()
"

    assert_file_contains "${outdir}/.vibe/generated-manifest.json" '"type": "full"' \
        "Manifest should record file type"
}
run_test "Manifest records file type (full)" test_manifest_file_type

# ──────────────────────────────────────────────
describe "Manifest — classification"

test_manifest_stock_managed() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"

    echo "original content" > "${outdir}/hook.py"
    python3 -c "
import sys; sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.generators.manifest import Manifest
m = Manifest('${outdir}')
m.record('hook.py', 'core/schema/policy.yaml')
m.save()
status = m.classify('hook.py')
assert status == 'stock-managed', f'Expected stock-managed, got {status}'
" 2>&1 || {
        fail "Unmodified file should be classified as stock-managed"
        return 1
    }
}
run_test "Unmodified file classified as stock-managed" test_manifest_stock_managed

test_manifest_customized() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"

    echo "original content" > "${outdir}/hook.py"
    python3 -c "
import sys; sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.generators.manifest import Manifest
m = Manifest('${outdir}')
m.record('hook.py', 'core/schema/policy.yaml')
m.save()
" 2>/dev/null

    # Modify the file after recording
    echo "modified content" > "${outdir}/hook.py"
    python3 -c "
import sys; sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.generators.manifest import Manifest
m = Manifest('${outdir}')
status = m.classify('hook.py')
assert status == 'customized', f'Expected customized, got {status}'
" 2>&1 || {
        fail "Modified file should be classified as customized"
        return 1
    }
}
run_test "Modified file classified as customized" test_manifest_customized

test_manifest_unknown() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"

    echo "some file" > "${outdir}/unknown.py"
    python3 -c "
import sys; sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.generators.manifest import Manifest
m = Manifest('${outdir}')
status = m.classify('unknown.py')
assert status == 'unknown', f'Expected unknown, got {status}'
" 2>&1 || {
        fail "File not in manifest should be classified as unknown"
        return 1
    }
}
run_test "File not in manifest classified as unknown" test_manifest_unknown

# ──────────────────────────────────────────────
describe "Manifest — partial file support"

test_manifest_partial_file() {
    local outdir="${TEST_DIR}/project"
    mkdir -p "$outdir"

    cat > "${outdir}/CLAUDE.md" << 'EOF'
# Project

<!-- VF:BEGIN roles -->
Generated roles content here
<!-- VF:END roles -->

Hand-written section
EOF

    python3 -c "
import sys; sys.path.insert(0, '${FRAMEWORK_DIR}')
from core.generators.manifest import Manifest
m = Manifest('${outdir}')
m.record('CLAUDE.md', 'core/schema/roles.yaml', file_type='partial', managed_sections=['roles'])
m.save()
" 2>&1 || {
        fail "Partial file recording should succeed"
        return 1
    }

    assert_file_contains "${outdir}/.vibe/generated-manifest.json" '"type": "partial"' \
        "Manifest should record partial file type"
    assert_file_contains "${outdir}/.vibe/generated-manifest.json" "managed_sections" \
        "Manifest should record managed_sections"
    assert_file_contains "${outdir}/.vibe/generated-manifest.json" "section_hashes" \
        "Manifest should record section_hashes"
}
run_test "Partial file recording with section hashes" test_manifest_partial_file

# ──────────────────────────────────────────────
print_summary
