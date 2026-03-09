#!/bin/bash

# Vibe Coding Framework - Skills Creation
# This script creates Claude Code Skills for VibeFlow workflow

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Framework root (parent of lib/)
FRAMEWORK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# All skills to install
ALL_SKILLS=(
    "vibeflow-issue-template"
    "vibeflow-tdd"
    "vibeflow-discuss"
    "vibeflow-conclude"
    "vibeflow-progress"
    "vibeflow-healthcheck"
    "vibeflow-ui-smoke"
    "vibeflow-ui-explore"
)

# Function to create all skills
create_skills() {
    section "Claude Code Skills を作成中"

    for skill_name in "${ALL_SKILLS[@]}"; do
        install_skill "$skill_name"
    done

    success "すべての Skills の作成が完了しました"
    return 0
}

# Install a single skill from examples/
install_skill() {
    local skill_name="$1"
    local skill_dir=".claude/skills/${skill_name}"
    local skill_file="${skill_dir}/SKILL.md"
    local source_file="${FRAMEWORK_ROOT}/examples/.claude/skills/${skill_name}/SKILL.md"

    info "${skill_name} Skill を作成中..."

    mkdir -p "$skill_dir"

    if [ -f "$source_file" ]; then
        cp "$source_file" "$skill_file"
    else
        error "Source not found: ${source_file}"
        return 1
    fi

    if [ $? -eq 0 ]; then
        success "${skill_name} Skill を作成しました"
        return 0
    else
        error "${skill_name} Skill の作成に失敗しました"
        return 1
    fi
}

# Function to verify skills installation
verify_skills() {
    local missing=()

    for skill_name in "${ALL_SKILLS[@]}"; do
        local skill_file=".claude/skills/${skill_name}/SKILL.md"
        if [ ! -f "$skill_file" ]; then
            missing+=("$skill_file")
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
