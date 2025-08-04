#!/bin/bash

# Vibe Coding Framework - Setup Test Script
# This script tests the setup process

set -e

# Get the directory where this script is located
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
SETUP_SCRIPT="$PROJECT_ROOT/setup_vibeflow.sh"

# Test configuration
TEST_PROJECT_DIR="/tmp/vibe-test-$$"
PASSED=0
FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
pass() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED++))
}

info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Cleanup function
cleanup() {
    if [ -d "$TEST_PROJECT_DIR" ]; then
        rm -rf "$TEST_PROJECT_DIR"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Test functions
test_script_exists() {
    info "Testing: Setup script exists"
    if [ -f "$SETUP_SCRIPT" ]; then
        pass "Setup script found"
    else
        fail "Setup script not found at $SETUP_SCRIPT"
    fi
}

test_lib_directory_exists() {
    info "Testing: Lib directory exists"
    if [ -d "$PROJECT_ROOT/lib" ]; then
        pass "Lib directory found"
    else
        fail "Lib directory not found"
    fi
}

test_all_lib_files_exist() {
    info "Testing: All lib files exist"
    local lib_files=(
        "common.sh"
        "create_agents.sh"
        "create_claude_md.sh"
        "create_commands.sh"
        "create_structure.sh"
        "create_templates.sh"
    )
    
    local all_exist=true
    for file in "${lib_files[@]}"; do
        if [ ! -f "$PROJECT_ROOT/lib/$file" ]; then
            fail "Missing lib file: $file"
            all_exist=false
        fi
    done
    
    if [ "$all_exist" = true ]; then
        pass "All lib files exist"
    fi
}

test_help_option() {
    info "Testing: --help option"
    if $SETUP_SCRIPT --help > /dev/null 2>&1; then
        pass "--help option works"
    else
        fail "--help option failed"
    fi
}

test_version_option() {
    info "Testing: --version option"
    if $SETUP_SCRIPT --version | grep -q "v2.0"; then
        pass "--version option works and shows v2.0"
    else
        fail "--version option failed or wrong version"
    fi
}

test_setup_in_temp_directory() {
    info "Testing: Setup in temporary directory"
    
    # Create test directory
    mkdir -p "$TEST_PROJECT_DIR"
    cd "$TEST_PROJECT_DIR"
    
    # Run setup with force option
    if $SETUP_SCRIPT --force > /dev/null 2>&1; then
        pass "Setup completed successfully"
    else
        fail "Setup failed"
        return
    fi
    
    # Check created files and directories
    local required_items=(
        "CLAUDE.md"
        "vision.md"
        "spec.md"
        "plan.md"
        ".claude/agents"
        ".claude/commands"
        ".vibe/state.yaml"
        ".vibe/templates"
        "issues"
        "src"
    )
    
    for item in "${required_items[@]}"; do
        if [ -e "$TEST_PROJECT_DIR/$item" ]; then
            pass "Created: $item"
        else
            fail "Missing: $item"
        fi
    done
}

test_slash_commands_created() {
    info "Testing: Slash commands created"
    
    if [ ! -d "$TEST_PROJECT_DIR/.claude/commands" ]; then
        fail "Commands directory not found"
        return
    fi
    
    local commands=(
        "progress.md"
        "healthcheck.md"
        "abort.md"
        "next.md"
        "restart-cycle.md"
        "skip-tests.md"
        "vibe-status.md"
        "role-product_manager.md"
        "role-engineer.md"
        "role-qa_engineer.md"
        "role-reset.md"
    )
    
    local all_exist=true
    for cmd in "${commands[@]}"; do
        if [ ! -f "$TEST_PROJECT_DIR/.claude/commands/$cmd" ]; then
            fail "Missing command: $cmd"
            all_exist=false
        fi
    done
    
    if [ "$all_exist" = true ]; then
        pass "All slash commands created"
    fi
}

test_subagents_created() {
    info "Testing: Subagents created"
    
    if [ ! -d "$TEST_PROJECT_DIR/.claude/agents" ]; then
        fail "Agents directory not found"
        return
    fi
    
    local agents=(
        "pm-auto.md"
        "engineer-auto.md"
        "qa-auto.md"
        "deploy-auto.md"
    )
    
    local all_exist=true
    for agent in "${agents[@]}"; do
        if [ ! -f "$TEST_PROJECT_DIR/.claude/agents/$agent" ]; then
            fail "Missing agent: $agent"
            all_exist=false
        fi
    done
    
    if [ "$all_exist" = true ]; then
        pass "All subagents created"
    fi
}

# Main test execution
main() {
    echo "==================================="
    echo "Vibe Coding Framework Setup Tests"
    echo "==================================="
    echo ""
    
    # Run tests
    test_script_exists
    test_lib_directory_exists
    test_all_lib_files_exist
    test_help_option
    test_version_option
    test_setup_in_temp_directory
    test_slash_commands_created
    test_subagents_created
    
    # Summary
    echo ""
    echo "==================================="
    echo "Test Summary"
    echo "==================================="
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run main
main