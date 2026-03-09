#!/bin/bash

# VibeFlow Test: v5 — README v5 Sync (Issue #68)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "README v5 — Iris-Only message"

test_iris_only_message() {
    assert_file_contains "${FRAMEWORK_DIR}/README.md" \
        "Iris.*only\|Iris のみ\|Iris だけ\|Iris-Only\|talk.*Iris" \
        "README should communicate Iris-only model"
}
run_test "README has Iris-only message" test_iris_only_message

# ──────────────────────────────────────────────
describe "README v5 — Codex integration"

test_mentions_codex() {
    assert_file_contains "${FRAMEWORK_DIR}/README.md" \
        "Codex\|codex" "README should mention Codex integration"
}
run_test "mentions Codex" test_mentions_codex

# ──────────────────────────────────────────────
describe "README v5 — cross-review"

test_mentions_cross_review() {
    assert_file_contains "${FRAMEWORK_DIR}/README.md" \
        "cross.review\|クロスレビュー\|Cross.Review" "README should mention cross-review"
}
run_test "mentions cross-review" test_mentions_cross_review

# ──────────────────────────────────────────────
describe "README v5 — auto QA"

test_mentions_auto_qa() {
    assert_file_contains "${FRAMEWORK_DIR}/README.md" \
        "auto.*QA\|QA.*自動\|auto.*close\|自動.*判断\|auto_pass" \
        "README should mention auto QA judgment"
}
run_test "mentions auto QA" test_mentions_auto_qa

# ──────────────────────────────────────────────
describe "README v5 — rules/ structure"

test_mentions_rules() {
    assert_file_contains "${FRAMEWORK_DIR}/README.md" \
        "rules/\|\.claude/rules" "README should mention rules/ structure"
}
run_test "mentions rules/ structure" test_mentions_rules

# ──────────────────────────────────────────────
describe "README v5 — no multi-terminal"

test_no_multi_terminal() {
    assert_file_not_contains "${FRAMEWORK_DIR}/README.md" \
        "Terminal 1.*Terminal 2\|マルチターミナル構成で" \
        "README should not reference multi-terminal setup"
}
run_test "no multi-terminal references" test_no_multi_terminal

# ──────────────────────────────────────────────
describe "README v5 — commands mention natural language"

test_natural_language() {
    assert_file_contains "${FRAMEWORK_DIR}/README.md" \
        "自然言語\|natural language\|話しかけ\|会話" \
        "README should mention natural language interaction"
}
run_test "mentions natural language interaction" test_natural_language

# ──────────────────────────────────────────────
describe "README v5 — quick start"

test_has_quick_start() {
    assert_file_contains "${FRAMEWORK_DIR}/README.md" \
        "Quick Start\|クイックスタート\|Getting Started" \
        "README should have quick start section"
}
run_test "has quick start section" test_has_quick_start

# ──────────────────────────────────────────────
print_summary
