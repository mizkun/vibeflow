#!/bin/bash

# Vibe Coding Framework - Skills Creation
# This script creates Claude Code Skills for VibeFlow workflow

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create all skills
create_skills() {
    section "Claude Code Skills を作成中"
    
    create_issue_template_skill
    create_tdd_skill
    
    success "すべての Skills の作成が完了しました"
    return 0
}

# Function to create vibeflow-issue-template skill
create_issue_template_skill() {
    local skill_dir=".claude/skills/vibeflow-issue-template"
    local skill_file="${skill_dir}/SKILL.md"
    
    info "vibeflow-issue-template Skill を作成中..."
    
    # Ensure directory exists
    mkdir -p "$skill_dir"
    
    cat > "$skill_file" << 'SKILL_CONTENT'
---
name: vibeflow-issue-template
description: Create or refine VibeFlow issue files under issues/. Use when turning plan items into implementable tasks with clear acceptance criteria.
---

# VibeFlow Issue Template

## When to Use
- When creating new issue files from plan items
- When refining existing issues with clearer acceptance criteria
- When converting user requests into implementable tasks

## Output Format (Required)

Every issue file MUST include these sections:

### Overview
Brief description of the task (1-2 sentences).

### Requirements
- Bullet list of functional requirements
- What the implementation must achieve

### Acceptance Criteria
- [ ] Testable, unambiguous criteria
- [ ] Each item should be verifiable
- [ ] Include edge cases where relevant

### Technical Details
- Implementation approach
- Architecture decisions
- API contracts (if applicable)

### File Locations
- List of files to be created/modified
- Include paths relative to project root

### Testing Requirements
- Unit test requirements
- Integration test requirements (if applicable)
- E2E test requirements (if applicable)

### Dependencies
- Other issues this depends on
- External dependencies (packages, APIs)

### Non-goals (optional)
- What is explicitly out of scope

## Instructions

1. **Read context first**: Always read `spec.md` and `plan.md` before creating issues.
2. **Check state**: Read `.vibe/state.yaml` to understand current phase.
3. **Create file**: Write to `issues/<issue-name>.md`.
4. **Verify completeness**: Ensure all required sections are present.
5. **Cross-reference**: Link to related issues if applicable.

## Examples

- "Create an issue for user authentication"
- "Turn plan item 2.1 into an implementable issue"
- "Refine issue-001 with clearer acceptance criteria"
SKILL_CONTENT

    if [ $? -eq 0 ]; then
        success "vibeflow-issue-template Skill を作成しました"
        return 0
    else
        error "vibeflow-issue-template Skill の作成に失敗しました"
        return 1
    fi
}

# Function to create vibeflow-tdd skill
create_tdd_skill() {
    local skill_dir=".claude/skills/vibeflow-tdd"
    local skill_file="${skill_dir}/SKILL.md"
    
    info "vibeflow-tdd Skill を作成中..."
    
    # Ensure directory exists
    mkdir -p "$skill_dir"
    
    cat > "$skill_file" << 'SKILL_CONTENT'
---
name: vibeflow-tdd
description: Execute TDD Red-Green-Refactor cycle. Use when implementing features with test-driven development.
---

# VibeFlow TDD Cycle

## When to Use
- When implementing new features
- When fixing bugs with regression tests
- When refactoring with test coverage

## The Red-Green-Refactor Cycle

### Phase 1: Red (Write Failing Tests)

**Goal**: Define expected behavior through tests that don't pass yet.

1. Read the issue file and acceptance criteria
2. Create test files:
   - Unit tests: `tests/` or `src/**/__tests__/`
   - Integration tests: `tests/integration/`
   - E2E tests: `e2e/` or `tests/e2e/`
3. Write tests that define expected behavior
4. Run tests and confirm they fail (RED)
5. Commit: `test: Add failing tests for <feature>`

**Checklist**:
- [ ] Tests cover all acceptance criteria
- [ ] Tests cover edge cases
- [ ] Tests are independent (no shared state)
- [ ] Test names are descriptive

### Phase 2: Green (Make Tests Pass)

**Goal**: Write minimal code to pass all tests.

1. Write the simplest code that makes tests pass
2. Run tests after each small change
3. Do NOT over-engineer at this stage
4. Do NOT add features not covered by tests
5. Commit: `feat: Implement <feature>`

**Checklist**:
- [ ] All tests pass (GREEN)
- [ ] No new tests added in this phase
- [ ] Implementation is minimal

### Phase 3: Refactor (Improve Code Quality)

**Goal**: Improve code structure while keeping tests green.

1. Identify code smells:
   - Duplication
   - Long functions
   - Poor naming
   - Missing abstractions
2. Make one refactoring change at a time
3. Run tests after EVERY change
4. Keep tests GREEN throughout
5. Commit: `refactor: Improve <feature> code structure`

**Checklist**:
- [ ] All tests still pass
- [ ] Code is DRY (Don't Repeat Yourself)
- [ ] Functions are small and focused
- [ ] Names are clear and descriptive
- [ ] No dead code

## Common Test Patterns

### Unit Test Pattern
```
describe('<Component/Function>', () => {
  it('should <expected behavior> when <condition>', () => {
    // Arrange
    // Act
    // Assert
  });
});
```

### Edge Cases to Consider
- Empty inputs
- Null/undefined values
- Boundary values
- Error conditions
- Concurrent operations

## Examples

- "Implement user login with TDD"
- "Add validation with TDD cycle"
- "Refactor payment module keeping tests green"
SKILL_CONTENT

    if [ $? -eq 0 ]; then
        success "vibeflow-tdd Skill を作成しました"
        return 0
    else
        error "vibeflow-tdd Skill の作成に失敗しました"
        return 1
    fi
}

# Function to verify skills installation
verify_skills() {
    local skills=(
        ".claude/skills/vibeflow-issue-template/SKILL.md"
        ".claude/skills/vibeflow-tdd/SKILL.md"
    )
    
    local missing=()
    
    for skill in "${skills[@]}"; do
        if [ ! -f "$skill" ]; then
            missing+=("$skill")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        success "すべての Skills が正しくインストールされています"
        return 0
    else
        error "以下の Skills が見つかりません："
        for s in "${missing[@]}"; do
            echo "  - $s"
        done
        return 1
    fi
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_skills
fi

