#!/bin/bash

# VibeFlow v3 - CLAUDE.md Creation
# Copies the CLAUDE.md template from examples/

# Source common functions
_VF_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_VF_LIB_DIR}/common.sh"

# Function to create CLAUDE.md
create_claude_md() {
    section "CLAUDE.md を作成中"

    local src="${_VF_LIB_DIR}/../examples/CLAUDE.md"

    if [ -f "$src" ]; then
        create_file_with_backup "CLAUDE.md" "$(cat "$src")"
        success "CLAUDE.md の作成が完了しました"
        return 0
    else
        error "CLAUDE.md テンプレートが見つかりません: $src"
        return 1
    fi
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_claude_md
fi
