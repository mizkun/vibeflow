#!/bin/bash

# Vibe Coding Framework - Directory Structure Creation
# This script creates the necessary directory structure for Vibe Coding

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create Vibe Coding directory structure
create_vibe_structure() {
    section "ディレクトリ構造を作成中"
    
    local directories=(
        ".claude/commands"
        ".claude/skills"
        ".claude/agents"
        ".vibe/templates"
        ".vibe/roles"
        ".vibe/hooks"
        "issues"
        "src"
    )
    
    local total=${#directories[@]}
    local current=0
    
    for dir in "${directories[@]}"; do
        current=$((current + 1))
        show_progress $current $total "ディレクトリ作成"
        
        if ! create_directory "$dir"; then
            error "ディレクトリ構造の作成に失敗しました"
            return 1
        fi
    done
    
    # Create .gitignore file
    info ".gitignore を作成中..."
    local gitignore_content='# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/

# Production
build/
dist/

# Misc
.DS_Store
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# IDE
.vscode/
.idea/

# Vibe Coding
.vibe/test-results.log

# Claude Code local settings (not committed)
.claude/settings.local.json'

    create_file_with_backup ".gitignore" "$gitignore_content"
    
    success "ディレクトリ構造の作成が完了しました"
    return 0
}

# Function to verify directory structure
verify_structure() {
    info "ディレクトリ構造を検証中..."
    
    local required_dirs=(
        ".claude/commands"
        ".claude/skills"
        ".claude/agents"
        ".vibe/templates"
        ".vibe/roles"
        ".vibe/hooks"
        "issues"
        "src"
    )
    
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [ ${#missing_dirs[@]} -eq 0 ]; then
        success "すべてのディレクトリが正しく作成されています"
        return 0
    else
        error "以下のディレクトリが見つかりません："
        for dir in "${missing_dirs[@]}"; do
            echo "  - $dir"
        done
        return 1
    fi
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_vibe_structure
fi