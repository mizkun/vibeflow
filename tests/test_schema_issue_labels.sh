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
describe "Schema — Rev.4 required categories"

test_has_type_labels() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "type:dev" \
        "Should have type:dev label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "type:patch" \
        "Should have type:patch label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "type:spike" \
        "Should have type:spike label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "type:ops" \
        "Should have type:ops label"
}
run_test "type category has Rev.4 labels" test_has_type_labels

test_has_risk_labels() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "risk:low" \
        "Should have risk:low label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "risk:medium" \
        "Should have risk:medium label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "risk:high" \
        "Should have risk:high label"
}
run_test "risk category has required labels" test_has_risk_labels

test_has_qa_labels() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "qa:auto" \
        "Should have qa:auto label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "qa:manual" \
        "Should have qa:manual label"
}
run_test "qa category has required labels" test_has_qa_labels

test_has_workflow_labels() {
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "workflow:standard" \
        "Should have workflow:standard label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "workflow:patch" \
        "Should have workflow:patch label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "workflow:spike" \
        "Should have workflow:spike label"
    assert_file_contains "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" "workflow:ops" \
        "Should have workflow:ops label"
}
run_test "workflow category has required labels" test_has_workflow_labels

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
  type:
    description: "Type labels"
    labels:
      - name: "type:dev"
        color: "00ff00"
        description: "Dev"
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
  risk:
    description: "Risk labels"
    labels:
      - name: "risk:low"
        color: "00ff00"
        description: "Low risk"
  qa:
    description: "QA labels"
    labels:
      - name: "qa:auto"
        color: "00ff00"
        description: "Auto QA"
  workflow:
    description: "Workflow labels"
    labels:
      - name: "workflow:standard"
        color: "0075ca"
        description: "Standard"
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
describe "Setup — label creation script"

test_create_labels_script_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/lib/create_labels.sh" \
        "lib/create_labels.sh must exist"
}
run_test "create_labels.sh exists" test_create_labels_script_exists

test_create_labels_generates_commands() {
    # Test the Python helper that reads YAML and outputs gh commands
    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/generators/generate_label_commands.py" \
        "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" 2>&1)

    echo "$output" > "${TEST_DIR}/label_commands.txt"

    assert_file_contains "${TEST_DIR}/label_commands.txt" "gh label create" \
        "Should generate gh label create commands"
    assert_file_contains "${TEST_DIR}/label_commands.txt" "type:dev" \
        "Should include type:dev label"
    assert_file_contains "${TEST_DIR}/label_commands.txt" "risk:low" \
        "Should include risk:low label"
    assert_file_contains "${TEST_DIR}/label_commands.txt" "workflow:standard" \
        "Should include workflow:standard label"
}
run_test "Label command generator produces gh commands" test_create_labels_generates_commands

test_create_labels_uses_force_flag() {
    local output
    output=$(python3 "${FRAMEWORK_DIR}/core/generators/generate_label_commands.py" \
        "${FRAMEWORK_DIR}/core/schema/issue_labels.yaml" 2>&1)

    echo "$output" > "${TEST_DIR}/label_commands.txt"
    assert_file_contains "${TEST_DIR}/label_commands.txt" "\-\-force" \
        "Should use --force flag for idempotent updates"
}
run_test "Label commands use --force for idempotent updates" test_create_labels_uses_force_flag

# ──────────────────────────────────────────────
print_summary
