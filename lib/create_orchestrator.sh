#!/bin/bash

# Vibe Coding Framework - Orchestrator Creation
# This script creates the orchestrator context files

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create orchestrator.yaml
create_orchestrator() {
    section "Orchestrator Context を作成中"
    
    # Create orchestrator.yaml
    cat > .vibe/orchestrator.yaml << 'EOF'
# Vibe Coding Framework - Orchestrator Context
# This file tracks the overall project health and cross-role coordination

orchestrator:
  # Overall project health status
  project_health: "healthy"  # healthy, warning, critical
  last_updated: ""
  
  # Registry of completed steps and their artifacts
  step_registry: []
    # Example entry:
    # - step: "2_issue_breakdown"
    #   status: "completed"
    #   timestamp: "2024-12-20T10:00:00Z"
    #   artifacts_verified: true
    #   artifacts:
    #     - type: "issue_files"
    #       count: 5
    #       location: "issues/"
    #   warnings: []
  
  # Critical decisions that need cross-role visibility
  critical_decisions: []
    # Example entries:
    # - "API contract required - awaiting PM confirmation"
    # - "Test coverage at 60% - below standard"
  
  # Verification log for tracking what has been checked
  verification_log: []
    # Example entry:
    # - timestamp: "2024-12-20T10:00:00Z"
    #   step: "4_test_writing"
    #   checks_performed:
    #     - check: "test_files_exist"
    #       result: "passed"
    #       details: "15 test files found"
    #   overall_result: "passed"
  
  # Risk register for accumulating concerns
  risk_register: []
    # Example entry:
    # - risk: "Complex dependency chain"
    #   severity: "medium"  # low, medium, high, critical
    #   identified_at: "step_2"
    #   mitigation: "Consider phased implementation"
  
  # Communication log for important cross-role messages
  communication_log: []
    # Example entry:
    # - from: "engineer"
    #   to: "product_manager"
    #   timestamp: "2024-12-20T10:30:00Z"
    #   subject: "Technical constraint discovered"
    #   message: "Database schema needs revision for feature X"
    #   priority: "high"
  
  # Shared technical constraints and decisions
  shared_context:
    technical_constraints: []
      # Example: "Node.js version must be >= 18"
    architecture_decisions: []
      # Example: "Using microservices pattern"
    discovered_limitations: []
      # Example: "External API rate limit: 100 req/min"
  
  # Metrics for tracking progress
  metrics:
    total_cycles_completed: 0
    total_issues_completed: 0
    average_cycle_time: null
    current_velocity: null
    quality_metrics:
      test_coverage: null
      build_success_rate: null
      review_pass_rate: null
EOF

    # Create verification rules
    cat > .vibe/verification_rules.yaml << 'EOF'
# Verification rules for each step

verification_rules:
  # Step 2: Issue Breakdown
  2_issue_breakdown:
    pre_conditions: []
    post_conditions:
      - type: "file_exists"
        path: "issues/*.md"
        min_count: 1
        error_message: "No issue files created"
      - type: "file_contains"
        path: "issues/*.md"
        must_contain: ["## Overview", "## Acceptance Criteria"]
        error_message: "Issue files missing required sections"
  
  # Step 4: Test Writing
  4_test_writing:
    pre_conditions:
      - type: "file_exists"
        path: "issues/*.md"
        min_count: 1
        error_message: "No issues found to work on"
    post_conditions:
      - type: "file_exists"
        path_pattern: "**/*test*"
        min_count: 1
        error_message: "No test files created"
      - type: "command_exit_code"
        command: "npm test || pytest || go test ./... || cargo test || echo 'No test runner found'"
        expected_code: 1  # Tests should fail initially
        error_message: "Tests should be failing at this stage"
  
  # Step 5: Implementation
  5_implementation:
    pre_conditions:
      - type: "tests_exist"
        error_message: "No tests found to implement against"
    post_conditions:
      - type: "tests_passing"
        error_message: "Tests are not passing after implementation"
      - type: "source_files_created"
        error_message: "No source files created"
  
  # Step 6: Refactoring
  6_refactoring:
    pre_conditions:
      - type: "tests_passing"
        error_message: "Tests must be passing before refactoring"
    post_conditions:
      - type: "tests_passing"
        error_message: "Tests broken during refactoring"
      - type: "no_new_issues"
        error_message: "New issues introduced during refactoring"
  
  # Step 7: Acceptance Test
  7_acceptance_test:
    pre_conditions:
      - type: "tests_passing"
        error_message: "All tests must pass before acceptance testing"
    post_conditions:
      - type: "acceptance_criteria_met"
        error_message: "Not all acceptance criteria are met"
  
  # Step 8: Pull Request
  8_pull_request:
    pre_conditions:
      - type: "clean_working_tree"
        error_message: "Working tree must be clean"
      - type: "branch_exists"
        error_message: "Feature branch must exist"
    post_conditions:
      - type: "pr_created"
        error_message: "Pull request was not created"
  
  # Step 10: Merge
  10_merge:
    pre_conditions:
      - type: "pr_approved"
        error_message: "PR must be approved before merging"
    post_conditions:
      - type: "merged_to_main"
        error_message: "Changes not merged to main branch"
EOF

    success "Orchestrator Context を作成しました"
}

# Export the function
export -f create_orchestrator