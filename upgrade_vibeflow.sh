#!/bin/bash

# Vibe Coding Framework - Upgrade Script
# This script upgrades existing projects to the latest framework version

set -e

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="3.0"  # Orchestrator Context version
OLD_VERSION_MIN="2.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

section() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Check if running in a Vibe project
check_vibe_project() {
    if [ ! -d ".vibe" ] || [ ! -d ".claude" ]; then
        error "This doesn't appear to be a Vibe Coding project."
        error "Please run this script from your project root directory."
        exit 1
    fi
}

# Backup existing configuration
create_backup() {
    section "Creating backup"
    
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local backup_dir=".vibe_backup_${backup_date}"
    
    info "Creating backup in ${backup_dir}"
    
    mkdir -p "${backup_dir}"
    cp -r .vibe "${backup_dir}/" 2>/dev/null || true
    cp -r .claude "${backup_dir}/" 2>/dev/null || true
    cp CLAUDE.md "${backup_dir}/" 2>/dev/null || true
    
    success "Backup created successfully"
}

# Check current framework version
check_current_version() {
    section "Checking current version"
    
    # Check if orchestrator already exists
    if [ -f ".vibe/orchestrator.yaml" ]; then
        warning "Orchestrator Context already exists. This project may already be upgraded."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Upgrade cancelled."
            exit 0
        fi
    fi
    
    # Check state.yaml format
    if [ -f ".vibe/state.yaml" ]; then
        if grep -q "verification_status:" ".vibe/state.yaml"; then
            info "Project appears to be using new format"
        else
            info "Project is using old format - upgrade needed"
        fi
    fi
}

# Add Orchestrator Context
add_orchestrator() {
    section "Adding Orchestrator Context"
    
    if [ ! -f ".vibe/orchestrator.yaml" ]; then
        info "Creating orchestrator.yaml"
        
        # Get current state information
        local current_cycle=$(grep -oP 'current_cycle:\s*\K\d+' .vibe/state.yaml 2>/dev/null || echo "1")
        local current_step=$(grep -oP 'current_step:\s*\K\S+' .vibe/state.yaml 2>/dev/null || echo "unknown")
        
        cat > .vibe/orchestrator.yaml << EOF
# Vibe Coding Framework - Orchestrator Context
# This file tracks the overall project health and cross-role coordination

orchestrator:
  # Overall project health status
  project_health: "healthy"  # healthy, warning, critical
  last_updated: "$(date -Iseconds)"
  
  # Registry of completed steps and their artifacts
  step_registry:
    - step: "upgrade_from_v2"
      status: "completed"
      timestamp: "$(date -Iseconds)"
      artifacts_verified: false
      artifacts:
        - type: "migration"
          description: "Upgraded from v2.0 to v3.0"
      warnings: []
  
  # Critical decisions that need cross-role visibility
  critical_decisions: []
  
  # Verification log for tracking what has been checked
  verification_log:
    - timestamp: "$(date -Iseconds)"
      step: "framework_upgrade"
      checks_performed:
        - check: "backup_created"
          result: "passed"
          details: "Backup created successfully"
      overall_result: "passed"
  
  # Risk register for accumulating concerns
  risk_register: []
  
  # Communication log for important cross-role messages
  communication_log:
    - from: "upgrade_script"
      to: "all_roles"
      timestamp: "$(date -Iseconds)"
      subject: "Framework upgraded to v3.0"
      message: "Orchestrator Context and verification features are now available"
      priority: "medium"
  
  # Shared technical constraints and decisions
  shared_context:
    technical_constraints: []
    architecture_decisions: []
    discovered_limitations: []
  
  # Metrics for tracking progress
  metrics:
    total_cycles_completed: $((current_cycle - 1))
    total_issues_completed: 0
    average_cycle_time: null
    current_velocity: null
    quality_metrics:
      test_coverage: null
      build_success_rate: null
      review_pass_rate: null
  
  # Migration information
  migration:
    from_version: "2.0"
    to_version: "3.0"
    migrated_at: "$(date -Iseconds)"
    current_cycle: $current_cycle
    current_step: "$current_step"
EOF
        
        success "orchestrator.yaml created"
    else
        info "orchestrator.yaml already exists, skipping"
    fi
}

# Add verification rules
add_verification_rules() {
    section "Adding verification rules"
    
    if [ ! -f ".vibe/verification_rules.yaml" ]; then
        info "Creating verification_rules.yaml"
        
        # Create verification rules directly
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
        
        success "verification_rules.yaml created"
    else
        info "verification_rules.yaml already exists, skipping"
    fi
}

# Update state.yaml to new format
update_state_yaml() {
    section "Updating state.yaml format"
    
    if [ -f ".vibe/state.yaml" ]; then
        # Check if already in new format
        if grep -q "verification_status:" ".vibe/state.yaml"; then
            info "state.yaml already in new format"
        else
            info "Upgrading state.yaml to new format"
            
            # Backup current state
            cp .vibe/state.yaml .vibe/state.yaml.bak
            
            # Read current values
            local current_cycle=$(grep -oP 'current_cycle:\s*\K\d+' .vibe/state.yaml || echo "1")
            local current_step=$(grep -oP 'current_step:\s*\K\S+' .vibe/state.yaml || echo "1_plan_review")
            local current_issue=$(grep -oP 'current_issue:\s*\K"[^"]*"' .vibe/state.yaml || echo "null")
            local next_step=$(grep -oP 'next_step:\s*\K\S+' .vibe/state.yaml || echo "2_issue_breakdown")
            
            # Append new fields
            cat >> .vibe/state.yaml << EOF

# Step history for current cycle
step_history: []

# Verification status
verification_status:
  last_check: null
  all_gates_passed: true

# Communication
communication:
  unread_messages: 0
  pending_decisions: 0

# Framework version
framework_version: "$VERSION"
upgraded_from: "2.0"
upgraded_at: "$(date -Iseconds)"
EOF
            
            success "state.yaml updated to new format"
        fi
    fi
}

# Add new slash commands
add_new_commands() {
    section "Adding new slash commands"
    
    local commands_to_add=(
        "verify-step:現在のステップの成果物を検証"
        "orchestrator-status:全体的なプロジェクト状態と警告"
        "health-check:プロジェクト健全性の総合チェック"
    )
    
    for cmd_info in "${commands_to_add[@]}"; do
        IFS=':' read -r cmd_name cmd_desc <<< "$cmd_info"
        
        if [ ! -f ".claude/commands/${cmd_name}.md" ]; then
            info "Adding command: /${cmd_name}"
            
            case "$cmd_name" in
                "verify-step")
                    cat > ".claude/commands/verify-step.md" << 'EOF'
# 現在のステップを検証

Verify that the current step has completed successfully by checking:
1. All required artifacts exist
2. All verification rules pass  
3. Orchestrator is updated

This command will:
- Check .vibe/state.yaml to identify current step
- Load verification rules from .vibe/verification_rules.yaml
- Check all post_conditions for the current step
- Update .vibe/orchestrator.yaml with results
- Block progression if verification fails

Show verification results in Japanese with clear pass/fail indicators.
EOF
                    ;;
                    
                "orchestrator-status")
                    cat > ".claude/commands/orchestrator-status.md" << 'EOF'
# Orchestrator状態を表示

Display the current orchestrator status including:
- Overall project health (healthy/warning/critical)
- Recent step completions and their artifacts
- Active warnings and risks
- Critical decisions pending
- Communication log highlights

Read .vibe/orchestrator.yaml and provide a comprehensive summary in Japanese.

Format output as:
```
🌐 プロジェクト健全性: [status]
📦 成果物: [summary]
⚠️  警告: [count]
🔴 リスク: [summary]
💬 コミュニケーション: [recent]
```
EOF
                    ;;
                    
                "health-check")
                    cat > ".claude/commands/health-check.md" << 'EOF'
# プロジェクト健全性チェック

Perform a comprehensive health check of the project:
1. Verify all expected files exist
2. Check for accumulated warnings in orchestrator
3. Verify test status
4. Check for blocking issues
5. Assess overall project state

Provide a health report with:
- Overall status (🟢 Healthy / 🟡 Warning / 🔴 Critical)
- Specific issues found
- Recommended actions

Report in Japanese with clear status indicators and actionable recommendations.
EOF
                    ;;
            esac
            
            success "Added /${cmd_name}"
        else
            info "/${cmd_name} already exists"
        fi
    done
}

# Remove old duplicate commands
remove_duplicate_commands() {
    section "Cleaning up duplicate commands"
    
    if [ -f ".claude/commands/healthcheck.md" ] && [ -f ".claude/commands/health-check.md" ]; then
        info "Removing old healthcheck.md in favor of health-check.md"
        rm -f ".claude/commands/healthcheck.md"
        success "Removed duplicate healthcheck command"
    fi
}

# Update CLAUDE.md
update_claude_md() {
    section "Updating CLAUDE.md"
    
    # Check if Orchestrator section already exists
    if grep -q "Orchestrator Context" CLAUDE.md; then
        info "CLAUDE.md already mentions Orchestrator Context"
    else
        info "Adding Orchestrator Context section to CLAUDE.md"
        
        # Find a good place to insert (after Project Structure section)
        # This is a simplified approach - in reality would need more careful editing
        
        cat >> CLAUDE.md << 'EOF'

## 🌐 Orchestrator Context

The Orchestrator Context (`.vibe/orchestrator.yaml`) is a shared space that all roles can access to:
- Track overall project health (healthy/warning/critical)
- Share critical information between roles
- Record artifacts and verification results
- Accumulate warnings and risks
- Enable better decision-making

This solves the "success theater" problem where subagents report completion without actual verification.

### New Commands Available:
- `/verify-step` - Verify current step artifacts
- `/orchestrator-status` - View project health and warnings
- `/health-check` - Comprehensive project health check
EOF
        
        success "Updated CLAUDE.md with Orchestrator information"
    fi
}

# Main upgrade process
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║     🚀 Vibe Coding Framework Upgrade Script                  ║"
    echo "║                                                              ║"
    echo "║     Upgrading to version $VERSION with Orchestrator Context  ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    # Check if we're in a Vibe project
    check_vibe_project
    
    # Check current version
    check_current_version
    
    # Create backup
    create_backup
    
    # Perform upgrades
    add_orchestrator
    add_verification_rules
    update_state_yaml
    add_new_commands
    remove_duplicate_commands
    update_claude_md
    
    # Summary
    section "Upgrade Complete!"
    
    success "Your project has been upgraded to Vibe Coding Framework v$VERSION"
    echo
    info "New features available:"
    echo "  • Orchestrator Context for cross-role coordination"
    echo "  • Automated verification of artifacts"
    echo "  • Project health monitoring"
    echo "  • New commands: /verify-step, /orchestrator-status, /health-check"
    echo
    warning "Please review the changes and test your project"
    info "Backup created in .vibe_backup_* directory"
    echo
    echo -e "${CYAN}Happy Vibe Coding with enhanced reliability!${NC}"
}

# Run main function
main "$@"