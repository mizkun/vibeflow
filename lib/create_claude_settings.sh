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
      }
    ],
    "Stop": [
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
    
    # Detect OS for appropriate sound command
    local os_type
    os_type=$(detect_os)
    
    # Create task_complete.sh
    cat > "$task_complete" << 'BASH_SCRIPT'
#!/bin/bash
# Task completion notification hook
# Called by PostToolUse hook after Edit/Write/MultiEdit/TodoWrite

OS_TYPE="$(uname -s)"

case "$OS_TYPE" in
    Darwin*)
        # macOS: Use afplay with system sound
        afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
        ;;
    Linux*)
        # Linux: Try paplay (PulseAudio) or aplay (ALSA)
        if command -v paplay &>/dev/null; then
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
        elif command -v aplay &>/dev/null; then
            aplay /usr/share/sounds/sound-icons/glass-water-1.wav 2>/dev/null &
        fi
        ;;
esac

exit 0
BASH_SCRIPT
    chmod +x "$task_complete"
    
    # Create waiting_input.sh
    cat > "$waiting_input" << 'BASH_SCRIPT'
#!/bin/bash
# Waiting for input notification hook
# Called by Stop hook when Claude Code stops and waits for user input
# Plays a dramatic sound at Step 7a (human checkpoint), normal ping otherwise

OS_TYPE="$(uname -s)"

# Check if we're at Step 7a (human checkpoint)
IS_STEP7A=false
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.vibe/state.yaml"
if [ -f "$STATE_FILE" ]; then
    CURRENT_STEP=$(grep -E "^current_step:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/current_step:[[:space:]]*//' | tr -d '"' | tr -d "'")
    if [ "$CURRENT_STEP" = "7" ]; then
        IS_STEP7A=true
    fi
fi

case "$OS_TYPE" in
    Darwin*)
        if [ "$IS_STEP7A" = true ]; then
            # Step 7a: Dramatic alert sequence
            (
                afplay /System/Library/Sounds/Hero.aiff 2>/dev/null
                sleep 0.3
                afplay /System/Library/Sounds/Hero.aiff 2>/dev/null
                sleep 0.3
                afplay /System/Library/Sounds/Glass.aiff 2>/dev/null
            ) &
        else
            # Normal: Simple ping
            afplay /System/Library/Sounds/Ping.aiff 2>/dev/null &
        fi
        ;;
    Linux*)
        if [ "$IS_STEP7A" = true ]; then
            # Step 7a: Dramatic alert
            if command -v paplay &>/dev/null; then
                (
                    paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null
                    sleep 0.3
                    paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null
                    sleep 0.3
                    paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null
                ) &
            fi
        else
            # Normal: Simple notification
            if command -v paplay &>/dev/null; then
                paplay /usr/share/sounds/freedesktop/stereo/message.oga 2>/dev/null &
            elif command -v aplay &>/dev/null; then
                aplay /usr/share/sounds/sound-icons/prompt.wav 2>/dev/null &
            fi
        fi
        ;;
esac

exit 0
BASH_SCRIPT
    chmod +x "$waiting_input"
    
    # Create checkpoint_alert.sh
    local checkpoint_alert=".vibe/hooks/checkpoint_alert.sh"
    cat > "$checkpoint_alert" << 'BASH_SCRIPT'
#!/bin/bash
# VibeFlow Checkpoint Alert
# Plays a distinctive notification when Step 7a requires user attention.
# Called by validate_step7a.py when blocking gh pr create.

OS_TYPE="$(uname -s)"

case "$OS_TYPE" in
    Darwin*)
        # macOS: Play attention-grabbing sequence
        (
            afplay /System/Library/Sounds/Hero.aiff 2>/dev/null
            sleep 0.3
            afplay /System/Library/Sounds/Hero.aiff 2>/dev/null
            sleep 0.3
            afplay /System/Library/Sounds/Glass.aiff 2>/dev/null
        ) &
        ;;
    Linux*)
        if command -v paplay &>/dev/null; then
            (
                paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null
                sleep 0.3
                paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null
            ) &
        elif command -v aplay &>/dev/null; then
            aplay /usr/share/sounds/sound-icons/glass-water-1.wav 2>/dev/null &
        fi
        ;;
esac

exit 0
BASH_SCRIPT
    chmod +x "$checkpoint_alert"

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

