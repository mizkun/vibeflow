#!/bin/bash

# VibeFlow Test: Issue 1-4 — issue_labels.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Schema — issue_labels.yaml"

test_issue_labels_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" \
        "core/schema/issue_labels.yaml must exist"
}
run_test "issue_labels.yaml exists" test_issue_labels_exists

test_issue_labels_valid() {
    python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" 2>&1 || {
        fail "issue_labels.yaml should pass validation"
        return 1
    }
}
run_test "issue_labels.yaml passes validation" test_issue_labels_valid

# ──────────────────────────────────────────────
describe "Schema — required categories"

test_has_type_labels() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "type:dev" \
        "Should have type:dev label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "type:human" \
        "Should have type:human label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "type:discussion" \
        "Should have type:discussion label"
}
run_test "type category has required labels" test_has_type_labels

test_has_qa_labels() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "qa:auto" \
        "Should have qa:auto label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "qa:manual" \
        "Should have qa:manual label"
}
run_test "qa category has required labels" test_has_qa_labels

test_has_status_labels() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "status:implementing" \
        "Should have status:implementing label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "status:pr-ready" \
        "Should have status:pr-ready label"
}
run_test "status category has required labels" test_has_status_labels

test_has_priority_labels() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "priority:critical" \
        "Should have priority:critical label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "priority:low" \
        "Should have priority:low label"
}
run_test "priority category has required labels" test_has_priority_labels

# ──────────────────────────────────────────────
describe "Schema — label structure"

test_labels_have_required_fields() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "color:" \
        "Labels should have color field"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "description:" \
        "Labels should have description field"
}
run_test "Labels have name, color, description" test_labels_have_required_fields

# ──────────────────────────────────────────────
describe "Schema — validation rejects invalid"

test_missing_category_rejected() {
    cat > "${TEST_DIR}/bad_labels.yaml" << 'YAML'
categories:
  status:
    description: "Status labels"
    labels:
      - name: "status:open"
        color: "00ff00"
        description: "Open"
YAML

    python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${TEST_DIR}/bad_labels.yaml" 2>/dev/null && {
        fail "Missing required categories should fail validation"
        return 1
    }
    return 0
}
run_test "Missing required categories rejected" test_missing_category_rejected

test_missing_label_field_rejected() {
    cat > "${TEST_DIR}/bad_labels.yaml" << 'YAML'
categories:
  type:
    description: "Type labels"
    labels:
      - name: "type:dev"
  qa:
    description: "QA labels"
    labels:
      - name: "qa:auto"
        color: "00ff00"
        description: "Auto QA"
YAML

    python3 "${FRAMEWORK_DIR}/core/validators/schema_validate.py" \
        "${TEST_DIR}/bad_labels.yaml" 2>/dev/null && {
        fail "Missing label fields should fail validation"
        return 1
    }
    return 0
}
run_test "Missing label fields rejected" test_missing_label_field_rejected

# ──────────────────────────────────────────────
print_summary
