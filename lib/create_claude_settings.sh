#!/bin/bash

# Vibe Coding Framework - Claude Code Settings Creation
# This script creates .claude/settings.json with hooks configuration

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create Claude Code settings with hooks
create_claude_settings() {
    section "Claude Code 設定を作成中"
    
    local settings_file=".claude/settings.json"
    local local_template=".vibe/templates/settings.local.json"
    
    info "settings.json を作成中..."
    
    # Create the settings.json using heredoc
    cat > "$settings_file" << 'JSON_CONTENT'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.vibe/hooks/validate_access.py",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.vibe/hooks/validate_write.sh",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.vibe/hooks/validate_step7a.py",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "TodoWrite|Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.vibe/hooks/task_complete.sh 2>/dev/null || true",
            "timeout": 2
          }
        ]
      },
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.vibe/hooks/postwrite_lint.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.vibe/hooks/stop_test_gate.sh",
            "timeout": 120
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.vibe/hooks/waiting_input.sh 2>/dev/null || true",
            "timeout": 2
          }
        ]
      }
    ]
  }
}
JSON_CONTENT

    if [ $? -eq 0 ]; then
        success "Claude Code 設定を作成しました: $settings_file"
    else
        error "Claude Code 設定の作成に失敗しました"
        return 1
    fi
    
    # Create local settings template for emergency hook disable
    info "緊急用ローカル設定テンプレートを作成中..."
    
    cat > "$local_template" << 'JSON_CONTENT'
{
  "disableAllHooks": true
}
JSON_CONTENT

    if [ $? -eq 0 ]; then
        success "ローカル設定テンプレートを作成しました: $local_template"
        info "💡 緊急時は $local_template を .claude/settings.local.json にコピーして Hook を無効化できます"
    else
        warning "ローカル設定テンプレートの作成に失敗しました"
    fi
    
    return 0
}

# Function to create notification hook scripts (simplified versions)
create_notification_hooks() {
    info "通知フックスクリプトを作成中..."
    
    local task_complete=".vibe/hooks/task_complete.sh"
    local waiting_input=".vibe/hooks/waiting_input.sh"
    
    # Copy from examples/ (single source of truth)
    local examples_dir="${VIBEFLOW_FRAMEWORK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/examples"

    # Copy task_complete.sh
    cp "${examples_dir}/.vibe/hooks/task_complete.sh" "$task_complete"
    chmod +x "$task_complete"

    # Copy waiting_input.sh
    cp "${examples_dir}/.vibe/hooks/waiting_input.sh" "$waiting_input"
    chmod +x "$waiting_input"

    # Copy checkpoint_alert.sh
    local checkpoint_alert=".vibe/hooks/checkpoint_alert.sh"
    cp "${examples_dir}/.vibe/hooks/checkpoint_alert.sh" "$checkpoint_alert"
    chmod +x "$checkpoint_alert"

    # Copy postwrite_lint.sh
    local postwrite_lint=".vibe/hooks/postwrite_lint.sh"
    cp "${examples_dir}/.vibe/hooks/postwrite_lint.sh" "$postwrite_lint"
    chmod +x "$postwrite_lint"

    # Copy stop_test_gate.sh
    local stop_test_gate=".vibe/hooks/stop_test_gate.sh"
    cp "${examples_dir}/.vibe/hooks/stop_test_gate.sh" "$stop_test_gate"
    chmod +x "$stop_test_gate"

    success "通知フックスクリプトを作成しました"
    return 0
}

# Function to verify Claude settings installation
verify_claude_settings() {
    local settings_file=".claude/settings.json"
    
    if [ ! -f "$settings_file" ]; then
        error "Claude Code 設定が見つかりません: $settings_file"
        return 1
    fi
    
    # Basic JSON syntax check using python
    if python3 -c "import json; json.load(open('$settings_file'))" 2>/dev/null; then
        success "Claude Code 設定の構文チェックが完了しました"
        return 0
    else
        error "Claude Code 設定の JSON 構文エラー: $settings_file"
        return 1
    fi
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_claude_settings
    create_notification_hooks
fi

