#!/bin/bash

# VibeFlow v3 - Slash Commands Creation
# Copies command definitions from lib/commands/ to project .claude/commands/

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create slash commands
create_slash_commands() {
    section "スラッシュコマンドを作成中"

    local commands=(
        "discuss:Iris セッション開始"
        "conclude:セッション終了"
        "progress:進捗確認"
        "healthcheck:整合性チェック"
        "run-e2e:E2Eテスト実行"
    )

    local total=${#commands[@]}
    local current=0

    mkdir -p ".claude/commands"

    for cmd_info in "${commands[@]}"; do
        current=$((current + 1))
        IFS=':' read -r cmd_name cmd_title <<< "$cmd_info"

        show_progress $current $total "コマンド作成 (${cmd_name})"

        local src="${SCRIPT_DIR}/commands/${cmd_name}.md"
        local dst=".claude/commands/${cmd_name}.md"

        if [ -f "$src" ]; then
            create_file_with_backup "$dst" "$(cat "$src")"
        else
            warning "${cmd_name}.md のソースが見つかりません: $src"
        fi
    done

    success "スラッシュコマンドの作成が完了しました"
    return 0
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_slash_commands
fi
