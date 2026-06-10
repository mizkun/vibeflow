#!/bin/bash

# Tests for runtime module deployment.
#
# core/runtime/*.py is copied FLAT into project .vibe/runtime/ (by
# setup and upgrade). Every module must therefore be importable by bare
# name from a flat directory, and `vibeflow generate` must deploy and
# manifest-track the runtime so drift in the判定 modules is detectable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

test_all_modules_import_flat() {
    local flat="${TEST_DIR}/flat"
    mkdir -p "$flat"
    cp "${FRAMEWORK_DIR}/core/runtime/"*.py "$flat/"
    rm -f "$flat/__init__.py"

    local result
    result=$(python3 -c "
import importlib, os, sys
sys.path.insert(0, '$flat')
failures = []
for f in sorted(os.listdir('$flat')):
    if not f.endswith('.py') or f == '__init__.py':
        continue
    mod = f[:-3]
    try:
        importlib.import_module(mod)
    except Exception as e:
        failures.append(f'{mod}: {type(e).__name__}: {e}')
if failures:
    print('FLAT IMPORT FAILURES:')
    for line in failures:
        print('  ' + line)
else:
    print('OK')
")
    if [ "$result" != "OK" ]; then
        fail "modules must import from a flat .vibe/runtime/ layout: $result"
        return 1
    fi
    return 0
}

test_no_docstring_trapped_future_imports() {
    local result
    result=$(python3 -c "
import ast, glob
bad = []
for f in sorted(glob.glob('${FRAMEWORK_DIR}/core/runtime/*.py')):
    src = open(f).read()
    if 'from __future__' not in src:
        continue
    tree = ast.parse(src)
    real = any(isinstance(n, ast.ImportFrom) and n.module == '__future__'
               for n in ast.walk(tree))
    if not real:
        bad.append(f.split('/')[-1])
if bad:
    print('TRAPPED (no-op inside docstring): ' + ', '.join(bad))
else:
    print('OK')
")
    if [ "$result" != "OK" ]; then
        fail "future imports must be real statements, not docstring text: $result"
        return 1
    fi
    return 0
}

test_generate_deploys_runtime() {
    local proj="${TEST_DIR}/proj"
    mkdir -p "$proj/.vibe"
    cd "$proj"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$proj" \
        --framework-dir "${FRAMEWORK_DIR}" > /dev/null 2>&1

    assert_file_exists "$proj/.vibe/runtime/qa_judge.py" \
        "generate must deploy core/runtime into .vibe/runtime/" || return 1
    assert_file_exists "$proj/.vibe/runtime/ui_task.py" \
        "generate must deploy ui_task.py" || return 1
    assert_file_contains "$proj/.vibe/generated-manifest.json" \
        ".vibe/runtime/qa_judge.py" \
        "deployed runtime modules must be manifest-tracked" || return 1
}

test_generate_check_detects_runtime_drift() {
    local proj="${TEST_DIR}/proj2"
    mkdir -p "$proj/.vibe"
    cd "$proj"

    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$proj" \
        --framework-dir "${FRAMEWORK_DIR}" > /dev/null 2>&1

    # Tamper with a deployed judgment module
    echo "# drifted" >> "$proj/.vibe/runtime/qa_judge.py"

    set +e
    python3 "${FRAMEWORK_DIR}/core/generators/generate_all.py" \
        --schema-dir "${FRAMEWORK_DIR}/core/schema" \
        --project-dir "$proj" \
        --framework-dir "${FRAMEWORK_DIR}" \
        --check > /dev/null 2>&1
    local code=$?
    set -e

    assert_equals "1" "$code" "--check must detect drifted runtime modules"
}

describe "Runtime deployment — flat import contract"
run_test "all runtime modules import from a flat directory" test_all_modules_import_flat
run_test "no future imports trapped inside docstrings" test_no_docstring_trapped_future_imports

describe "Runtime deployment — generate target"
run_test "generate deploys .vibe/runtime/ and tracks it in the manifest" test_generate_deploys_runtime
run_test "generate --check detects runtime drift" test_generate_check_detects_runtime_drift

print_summary
