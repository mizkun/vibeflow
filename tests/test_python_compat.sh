#!/bin/bash

# VibeFlow Test: Python 3.9 compatibility (Issue #74)
# Ensures all Python files use `from __future__ import annotations`

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Python 3.9 compat — future annotations"

test_all_py_files_have_future_annotations() {
    local missing=()
    while IFS= read -r pyfile; do
        # Skip __init__.py (often empty)
        if [[ "$(basename "$pyfile")" == "__init__.py" ]]; then
            continue
        fi
        # Skip empty files
        if [[ ! -s "$pyfile" ]]; then
            continue
        fi
        if ! grep -q "from __future__ import annotations" "$pyfile"; then
            missing+=("$pyfile")
        fi
    done < <(find "${FRAMEWORK_DIR}/core" -name "*.py" -type f)

    if [[ ${#missing[@]} -gt 0 ]]; then
        local relative_paths=()
        for f in "${missing[@]}"; do
            relative_paths+=("${f#${FRAMEWORK_DIR}/}")
        done
        fail "Missing 'from __future__ import annotations' in: ${relative_paths[*]}"
        return 1
    fi
    return 0
}
run_test "All core/*.py files have 'from __future__ import annotations'" test_all_py_files_have_future_annotations

test_no_bare_union_types_without_future() {
    # Double-check: find files with X | None pattern that lack the import
    local bad_files=()
    while IFS= read -r pyfile; do
        if [[ "$(basename "$pyfile")" == "__init__.py" ]]; then
            continue
        fi
        # Check if file uses union type syntax in annotations
        if grep -Pq ':\s*\w+\s*\|\s*None' "$pyfile" 2>/dev/null || \
           grep -Pq '->\s*\w+\s*\|\s*None' "$pyfile" 2>/dev/null; then
            if ! grep -q "from __future__ import annotations" "$pyfile"; then
                bad_files+=("${pyfile#${FRAMEWORK_DIR}/}")
            fi
        fi
    done < <(find "${FRAMEWORK_DIR}/core" -name "*.py" -type f)

    if [[ ${#bad_files[@]} -gt 0 ]]; then
        fail "Union type syntax without future import in: ${bad_files[*]}"
        return 1
    fi
    return 0
}
run_test "No bare union types without future annotations import" test_no_bare_union_types_without_future

test_no_lowercase_generics_without_future() {
    # Check for list[, dict[, tuple[, set[ in type annotations without future import
    local bad_files=()
    while IFS= read -r pyfile; do
        if [[ "$(basename "$pyfile")" == "__init__.py" ]]; then
            continue
        fi
        # Match type annotation patterns: `: list[`, `-> list[`, `: dict[`, etc.
        if grep -Pq '(:\s*|->)\s*(list|dict|tuple|set)\[' "$pyfile" 2>/dev/null; then
            if ! grep -q "from __future__ import annotations" "$pyfile"; then
                bad_files+=("${pyfile#${FRAMEWORK_DIR}/}")
            fi
        fi
    done < <(find "${FRAMEWORK_DIR}/core" -name "*.py" -type f)

    if [[ ${#bad_files[@]} -gt 0 ]]; then
        fail "Lowercase generics without future import in: ${bad_files[*]}"
        return 1
    fi
    return 0
}
run_test "No lowercase generics without future annotations import" test_no_lowercase_generics_without_future

# ──────────────────────────────────────────────
describe "Python 3.9 compat — import correctness"

test_future_annotations_before_docstring() {
    # from __future__ import annotations must be before other imports
    # (it can be after shebang and before/after docstring)
    local bad_files=()
    while IFS= read -r pyfile; do
        if ! grep -q "from __future__ import annotations" "$pyfile"; then
            continue
        fi
        # Check that no regular import comes before the future import
        local future_line
        future_line=$(grep -n "from __future__ import annotations" "$pyfile" | head -1 | cut -d: -f1)
        # Check for any import before the future import line (excluding shebang comments)
        local early_import
        early_import=$(head -n "$((future_line - 1))" "$pyfile" | grep -n "^import \|^from " | grep -v "^.*:from __future__" | head -1 || true)
        if [[ -n "$early_import" ]]; then
            bad_files+=("${pyfile#${FRAMEWORK_DIR}/}")
        fi
    done < <(find "${FRAMEWORK_DIR}/core" -name "*.py" -type f)

    if [[ ${#bad_files[@]} -gt 0 ]]; then
        fail "Future import is not the first import in: ${bad_files[*]}"
        return 1
    fi
    return 0
}
run_test "future annotations import is the first import" test_future_annotations_before_docstring

# ──────────────────────────────────────────────
print_summary
