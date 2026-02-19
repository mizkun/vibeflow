#!/bin/bash

# VibeFlow Test Helpers
# Simple shell test framework for VibeFlow

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

# Framework directory (where vibeflow source is)
FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ──────────────────────────────────────────────
# Test lifecycle
# ──────────────────────────────────────────────

setup_test_env() {
    TEST_DIR=$(mktemp -d)
    export VIBEFLOW_PROJECT_DIR="$TEST_DIR"
    export VIBEFLOW_FRAMEWORK_DIR="$FRAMEWORK_DIR"
    export VIBEFLOW_FROM_VERSION="${1:-2.0.0}"
    export VIBEFLOW_TO_VERSION="${2:-3.0.0}"

    # Initialize as git repo (required by some functions)
    cd "$TEST_DIR"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
}

teardown_test_env() {
    if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# ──────────────────────────────────────────────
# Create a v2 project structure for migration testing
# ──────────────────────────────────────────────

create_v2_project() {
    local dir="${1:-$TEST_DIR}"
    cd "$dir"

    # Core directories
    mkdir -p .vibe/roles .vibe/hooks .vibe/templates .vibe/discussions .vibe/backups
    mkdir -p .claude/commands .claude/agents .claude/skills
    mkdir -p issues

    # Version file
    echo "2.0.0" > .vibe/version

    # State file (v2 format)
    cat > .vibe/state.yaml << 'YAML'
current_cycle: 1
current_step: 1_plan_review
current_issue: null
current_role: "Product Manager"
last_role_transition: null
last_completed_step: null
next_step: 2_issue_breakdown

phase: development

checkpoint_status:
  2a_issue_validation: pending
  7a_runnable_check: pending

issues_created: []
issues_completed: []

quick_fixes: []

discovery:
  id: null
  started: null
  topic: null
  sessions: []

safety:
  ui_mode: atomic
  destructive_op: require_confirmation
  max_fix_attempts: 3
  failed_approach_log: []

infra_log:
  step: null
  hook_changes: []
  rollback_pending: false
YAML

    # Policy file (v2 format)
    cat > .vibe/policy.yaml << 'YAML'
roles:
  product_manager:
    can_read: ["vision.md", "spec.md", "plan.md", ".vibe/state.yaml", ".vibe/qa-reports/**"]
    can_write: ["plan.md", "issues/**", ".vibe/state.yaml"]
    can_create: ["issues/**"]
  engineer:
    can_read: ["spec.md", "issues/**", "src/**", ".vibe/state.yaml"]
    can_write: ["src/**", "**/*.test.*", ".vibe/state.yaml"]
    can_create: ["src/**", "**/*.test.*"]
  qa_engineer:
    can_read: ["spec.md", "issues/**", "src/**", ".vibe/state.yaml", ".vibe/qa-reports/**"]
    can_write: [".vibe/test-results.log", ".vibe/qa-reports/**", ".vibe/state.yaml"]
    can_create: [".vibe/qa-reports/**", ".vibe/test-results.log"]
  discussion_partner:
    can_read: ["vision.md", "spec.md", "plan.md", ".vibe/state.yaml", ".vibe/discussions/**"]
    can_write: [".vibe/discussions/**", ".vibe/state.yaml"]
    can_create: [".vibe/discussions/**"]
  infra_manager:
    can_read: [".vibe/hooks/**", ".vibe/state.yaml", ".claude/settings.json"]
    can_write: [".vibe/hooks/**", ".vibe/state.yaml"]
    can_create: [".vibe/hooks/**"]
YAML

    # Role files (v2)
    echo "# Discussion Partner" > .vibe/roles/discussion-partner.md
    echo "# Product Manager" > .vibe/roles/product-manager.md
    echo "# Engineer" > .vibe/roles/engineer.md
    echo "# QA Engineer" > .vibe/roles/qa-engineer.md
    echo "# Infrastructure Manager" > .vibe/roles/infra.md

    # Command files (v2)
    echo "# /next command" > .claude/commands/next.md
    echo "# /discuss command" > .claude/commands/discuss.md
    echo "# /conclude command" > .claude/commands/conclude.md
    echo "# /progress command" > .claude/commands/progress.md
    echo "# /healthcheck command" > .claude/commands/healthcheck.md

    # Sample issue
    cat > issues/ISSUE-001.md << 'MD'
# Add login feature

## Overview
Implement user login

## Acceptance Criteria
- [ ] Login form works
MD

    # Sample discussion
    cat > .vibe/discussions/DISC-001-architecture.md << 'MD'
# DISC-001: Architecture Discussion

## Topic
System architecture review

## Agreements
- Use microservices
MD

    # CLAUDE.md placeholder
    echo "# VibeFlow v2 CLAUDE.md" > CLAUDE.md
    echo "step_1_plan_review" >> CLAUDE.md

    # Project docs
    echo "# Vision" > vision.md
    echo "# Spec" > spec.md
    echo "# Plan" > plan.md

    # Git commit
    git add -A
    git commit -q -m "Initial v2 project"
}

# ──────────────────────────────────────────────
# Assertion helpers
# ──────────────────────────────────────────────

assert_file_exists() {
    local file="$1"
    local msg="${2:-File should exist: $file}"
    if [ -f "$file" ]; then
        return 0
    else
        fail "$msg"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local msg="${2:-File should NOT exist: $file}"
    if [ ! -f "$file" ]; then
        return 0
    else
        fail "$msg"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local msg="${2:-Directory should exist: $dir}"
    if [ -d "$dir" ]; then
        return 0
    else
        fail "$msg"
        return 1
    fi
}

assert_dir_not_exists() {
    local dir="$1"
    local msg="${2:-Directory should NOT exist: $dir}"
    if [ ! -d "$dir" ]; then
        return 0
    else
        fail "$msg"
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local msg="${3:-File $file should contain: $pattern}"
    if grep -q "$pattern" "$file" 2>/dev/null; then
        return 0
    else
        fail "$msg"
        return 1
    fi
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local msg="${3:-File $file should NOT contain: $pattern}"
    if ! grep -q "$pattern" "$file" 2>/dev/null; then
        return 0
    else
        fail "$msg"
        return 1
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-Expected '$expected' but got '$actual'}"
    if [ "$expected" = "$actual" ]; then
        return 0
    else
        fail "$msg"
        return 1
    fi
}

# ──────────────────────────────────────────────
# Test runner
# ──────────────────────────────────────────────

describe() {
    echo ""
    echo -e "${YELLOW}▸ $1${NC}"
}

it() {
    CURRENT_TEST="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} ${CURRENT_TEST}"
}

fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} ${CURRENT_TEST}"
    echo -e "    ${RED}→ $1${NC}"
}

run_test() {
    local test_name="$1"
    it "$test_name"

    setup_test_env

    # Run the test function; disable set -e for test execution
    set +e
    "$2"
    local result=$?
    set -e

    if [ "$result" -eq 0 ]; then
        pass
    fi

    teardown_test_env
}

print_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}All $TESTS_RUN tests passed${NC}"
    else
        echo -e "${RED}$TESTS_FAILED of $TESTS_RUN tests failed${NC}"
        echo -e "${GREEN}$TESTS_PASSED passed${NC}, ${RED}$TESTS_FAILED failed${NC}"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    return "$TESTS_FAILED"
}
