#!/bin/bash

# VibeFlow Test: Phase 4 — Skills 化 (Issue 4-2)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

# ──────────────────────────────────────────────
describe "Skills — new skills exist"

EXPECTED_SKILLS=(
    "vibeflow-discuss"
    "vibeflow-conclude"
    "vibeflow-progress"
    "vibeflow-healthcheck"
)

for skill_name in "${EXPECTED_SKILLS[@]}"; do
    eval "test_${skill_name//-/_}_exists() {
        assert_file_exists \"\${FRAMEWORK_DIR}/examples/.claude/skills/${skill_name}/SKILL.md\" \
            \"${skill_name}/SKILL.md must exist\"
    }"
    run_test "${skill_name} SKILL.md exists" "test_${skill_name//-/_}_exists"
done

# ──────────────────────────────────────────────
describe "Skills — existing skills still present"

test_tdd_skill_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-tdd/SKILL.md" \
        "vibeflow-tdd should still exist"
}
run_test "vibeflow-tdd still exists" test_tdd_skill_exists

test_issue_template_skill_exists() {
    assert_file_exists "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-issue-template/SKILL.md" \
        "vibeflow-issue-template should still exist"
}
run_test "vibeflow-issue-template still exists" test_issue_template_skill_exists

# ──────────────────────────────────────────────
describe "Skills — SKILL.md structure"

for skill_name in "${EXPECTED_SKILLS[@]}"; do
    eval "test_${skill_name//-/_}_has_frontmatter() {
        assert_file_contains \"\${FRAMEWORK_DIR}/examples/.claude/skills/${skill_name}/SKILL.md\" \
            \"name: ${skill_name}\" \"Should have name in frontmatter\"
    }"
    run_test "${skill_name} has frontmatter name" "test_${skill_name//-/_}_has_frontmatter"
done

for skill_name in "${EXPECTED_SKILLS[@]}"; do
    eval "test_${skill_name//-/_}_has_description() {
        assert_file_contains \"\${FRAMEWORK_DIR}/examples/.claude/skills/${skill_name}/SKILL.md\" \
            \"description:\" \"Should have description in frontmatter\"
    }"
    run_test "${skill_name} has description" "test_${skill_name//-/_}_has_description"
done

for skill_name in "${EXPECTED_SKILLS[@]}"; do
    eval "test_${skill_name//-/_}_has_when_to_use() {
        assert_file_contains \"\${FRAMEWORK_DIR}/examples/.claude/skills/${skill_name}/SKILL.md\" \
            \"When to Use\" \"Should have When to Use section\"
    }"
    run_test "${skill_name} has When to Use" "test_${skill_name//-/_}_has_when_to_use"
done

for skill_name in "${EXPECTED_SKILLS[@]}"; do
    eval "test_${skill_name//-/_}_has_instructions() {
        assert_file_contains \"\${FRAMEWORK_DIR}/examples/.claude/skills/${skill_name}/SKILL.md\" \
            \"Instructions\\|処理フロー\\|Checks\\|フォーマット\" \"Should have instructions or flow section\"
    }"
    run_test "${skill_name} has instructions/flow" "test_${skill_name//-/_}_has_instructions"
done

# ──────────────────────────────────────────────
describe "Skills — commands still exist (compatibility)"

EXPECTED_COMMANDS=(
    "discuss"
    "conclude"
    "progress"
    "healthcheck"
)

for cmd_name in "${EXPECTED_COMMANDS[@]}"; do
    eval "test_cmd_${cmd_name}_exists() {
        assert_file_exists \"\${FRAMEWORK_DIR}/examples/.claude/commands/${cmd_name}.md\" \
            \"commands/${cmd_name}.md must still exist\"
    }"
    run_test "command ${cmd_name}.md still exists" "test_cmd_${cmd_name}_exists"
done

# ──────────────────────────────────────────────
describe "Skills — commands reference skills"

for cmd_name in "${EXPECTED_COMMANDS[@]}"; do
    eval "test_cmd_${cmd_name}_refs_skill() {
        assert_file_contains \"\${FRAMEWORK_DIR}/examples/.claude/commands/${cmd_name}.md\" \
            \"vibeflow-${cmd_name}\" \"commands/${cmd_name}.md should reference vibeflow-${cmd_name} skill\"
    }"
    run_test "command ${cmd_name}.md references skill" "test_cmd_${cmd_name}_refs_skill"
done

# ──────────────────────────────────────────────
describe "Skills — create_skills.sh includes new skills"

test_create_skills_has_discuss() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_skills.sh" \
        "vibeflow-discuss" "create_skills.sh should include vibeflow-discuss"
}
run_test "create_skills.sh includes discuss" test_create_skills_has_discuss

test_create_skills_has_conclude() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_skills.sh" \
        "vibeflow-conclude" "create_skills.sh should include vibeflow-conclude"
}
run_test "create_skills.sh includes conclude" test_create_skills_has_conclude

test_create_skills_has_progress() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_skills.sh" \
        "vibeflow-progress" "create_skills.sh should include vibeflow-progress"
}
run_test "create_skills.sh includes progress" test_create_skills_has_progress

test_create_skills_has_healthcheck() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_skills.sh" \
        "vibeflow-healthcheck" "create_skills.sh should include vibeflow-healthcheck"
}
run_test "create_skills.sh includes healthcheck" test_create_skills_has_healthcheck

# ──────────────────────────────────────────────
describe "Skills — verify_skills checks new skills"

test_verify_skills_checks_all() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/create_skills.sh" \
        "verify_skills" "create_skills.sh should have verify_skills function"
}
run_test "verify_skills function exists" test_verify_skills_checks_all

# ──────────────────────────────────────────────
describe "Skills — lib/commands source unchanged"

test_lib_discuss_unchanged() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/commands/discuss.md" \
        "Discovery" "lib/commands/discuss.md should retain original content"
}
run_test "lib/commands/discuss.md unchanged" test_lib_discuss_unchanged

test_lib_conclude_unchanged() {
    assert_file_contains "${FRAMEWORK_DIR}/lib/commands/conclude.md" \
        "STATUS.md" "lib/commands/conclude.md should retain original content"
}
run_test "lib/commands/conclude.md unchanged" test_lib_conclude_unchanged

# ──────────────────────────────────────────────
describe "Skills — new state model (project_state + sessions)"

# vibeflow-discuss is deprecated in v5 — no longer requires project_state/sessions references

test_discuss_is_deprecated() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-discuss/SKILL.md" \
        "DEPRECATED\|deprecated" "vibeflow-discuss should be marked as deprecated"
}
run_test "discuss is deprecated" test_discuss_is_deprecated

test_conclude_refs_project_state() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-conclude/SKILL.md" \
        "project_state.yaml" "vibeflow-conclude should reference project_state.yaml"
}
run_test "conclude references project_state.yaml" test_conclude_refs_project_state

test_progress_refs_project_state() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-progress/SKILL.md" \
        "project_state.yaml" "vibeflow-progress should reference project_state.yaml"
}
run_test "progress references project_state.yaml" test_progress_refs_project_state

test_progress_refs_sessions() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-progress/SKILL.md" \
        "sessions/" "vibeflow-progress should reference sessions/"
}
run_test "progress references sessions/" test_progress_refs_sessions

test_healthcheck_refs_project_state() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-healthcheck/SKILL.md" \
        "project_state.yaml" "vibeflow-healthcheck should reference project_state.yaml"
}
run_test "healthcheck references project_state.yaml" test_healthcheck_refs_project_state

test_healthcheck_refs_sessions() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-healthcheck/SKILL.md" \
        "sessions/" "vibeflow-healthcheck should reference sessions/"
}
run_test "healthcheck references sessions/" test_healthcheck_refs_sessions

# ──────────────────────────────────────────────
describe "Skills — no old state.yaml as primary"

test_discuss_no_old_state_primary() {
    # Should NOT have ".vibe/state.yaml" as the first/primary state reference
    # (it's OK as fallback, but not as the main instruction)
    assert_file_not_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-discuss/SKILL.md" \
        "^.*状態確認.*state\.yaml" \
        "vibeflow-discuss should not use state.yaml as primary state source"
}
run_test "discuss does not use state.yaml as primary" test_discuss_no_old_state_primary

test_conclude_no_old_state_primary() {
    assert_file_not_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-conclude/SKILL.md" \
        "^.*状態確認.*state\.yaml" \
        "vibeflow-conclude should not use state.yaml as primary state source"
}
run_test "conclude does not use state.yaml as primary" test_conclude_no_old_state_primary

test_discuss_no_discovery_active() {
    assert_file_not_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-discuss/SKILL.md" \
        "discovery.active" \
        "vibeflow-discuss should not reference discovery.active (old field)"
}
run_test "discuss does not use discovery.active" test_discuss_no_discovery_active

test_conclude_no_discovery_active() {
    assert_file_not_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-conclude/SKILL.md" \
        "discovery.active" \
        "vibeflow-conclude should not reference discovery.active (old field)"
}
run_test "conclude does not use discovery.active" test_conclude_no_discovery_active

# ──────────────────────────────────────────────
print_summary
