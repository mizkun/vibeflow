#!/bin/bash

# Vibe Coding Framework - GitHub Label Creation
# Reads core/schema/issue_labels.yaml and creates labels via gh CLI.

create_github_labels() {
    section "GitHub ラベルを作成中"

    local labels_yaml="${SCRIPT_DIR}/core/schema/issue_labels.yaml"

    if [ ! -f "$labels_yaml" ]; then
        warning "issue_labels.yaml が見つかりません: ${labels_yaml}"
        return 0
    fi

    # Check if gh CLI is available and authenticated
    if ! command_exists gh; then
        warning "gh CLI が見つかりません。ラベル作成をスキップします。"
        info "GitHub CLI をインストールしてください: https://cli.github.com/"
        return 0
    fi

    if ! gh auth status &>/dev/null; then
        warning "gh CLI が認証されていません。ラベル作成をスキップします。"
        info "認証してください: gh auth login"
        return 0
    fi

    # Check if we're in a git repo with a remote
    if ! git remote get-url origin &>/dev/null; then
        warning "Git リモートが設定されていません。ラベル作成をスキップします。"
        return 0
    fi

    # Generate and execute label commands
    local commands
    commands=$(python3 "${SCRIPT_DIR}/core/generators/generate_label_commands.py" \
        "$labels_yaml" 2>&1)

    if [ $? -ne 0 ]; then
        warning "ラベルコマンドの生成に失敗しました: ${commands}"
        return 0
    fi

    local label_count=0
    local fail_count=0

    while IFS= read -r cmd; do
        [ -z "$cmd" ] && continue
        if eval "$cmd" 2>/dev/null; then
            label_count=$((label_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi
    done <<< "$commands"

    if [ "$label_count" -gt 0 ]; then
        success "${label_count} 個のラベルを作成/更新しました"
    fi
    if [ "$fail_count" -gt 0 ]; then
        warning "${fail_count} 個のラベルの作成に失敗しました"
    fi

    return 0
}
