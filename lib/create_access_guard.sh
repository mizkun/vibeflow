#!/bin/bash

# Vibe Coding Framework - Access Guard Hook Creation
# This script creates the validate_access.py hook for role-based access control

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create the access guard hook
create_access_guard() {
    section "アクセスガードフックを作成中"
    
    local hook_file=".vibe/hooks/validate_access.py"
    
    info "validate_access.py を作成中..."

    # Copy from examples/ (single source of truth)
    local examples_dir="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/examples"
    cp "${examples_dir}/.vibe/hooks/validate_access.py" "$hook_file"

    if [ $? -eq 0 ]; then
        chmod +x "$hook_file"
        success "アクセスガードフックを作成しました: $hook_file"
        return 0
    else
        error "アクセスガードフックの作成に失敗しました"
        return 1
    fi
}

# Function to create the write guard hook
create_write_guard() {
    section "書き込みガードフックを作成中"

    local hook_file=".vibe/hooks/validate_write.sh"

    info "validate_write.sh を作成中..."

    # Copy from examples/ (single source of truth)
    local examples_dir="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/examples"
    cp "${examples_dir}/.vibe/hooks/validate_write.sh" "$hook_file"

    if [ $? -eq 0 ]; then
        chmod +x "$hook_file"
        success "書き込みガードフックを作成しました: $hook_file"
        return 0
    else
        error "書き込みガードフックの作成に失敗しました"
        return 1
    fi
}

# Function to create the Step 7a guard hook
create_step7a_guard() {
    section "Step 7a ガードフックを作成中"

    local hook_file=".vibe/hooks/validate_step7a.py"
    mkdir -p ".vibe/checkpoints"

    info "validate_step7a.py を作成中..."

    # Copy from examples/ (single source of truth)
    local examples_dir="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/examples"
    cp "${examples_dir}/.vibe/hooks/validate_step7a.py" "$hook_file"

    if [ $? -eq 0 ]; then
        chmod +x "$hook_file"
        success "Step 7a ガードフックを作成しました: $hook_file"
        return 0
    else
        error "Step 7a ガードフックの作成に失敗しました"
        return 1
    fi
}

# Function to verify access guard installation
verify_access_guard() {
    local hook_file=".vibe/hooks/validate_access.py"
    
    if [ ! -f "$hook_file" ]; then
        error "アクセスガードフックが見つかりません: $hook_file"
        return 1
    fi
    
    if [ ! -x "$hook_file" ]; then
        error "アクセスガードフックに実行権限がありません: $hook_file"
        return 1
    fi
    
    # Verify Python syntax
    if python3 -m py_compile "$hook_file" 2>/dev/null; then
        success "アクセスガードフックの構文チェックが完了しました"
        return 0
    else
        warning "アクセスガードフックの構文に問題がある可能性があります"
        return 1
    fi
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_access_guard
fi

