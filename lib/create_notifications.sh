#!/bin/bash
# Vibe Coding Framework - Notification Setup

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Create notification sound scripts
create_notification_scripts() {
    section "Setting up notification sounds"
    
    local os_type=$(detect_os)
    info "Detected OS: $os_type"
    
    # Create hooks directory
    mkdir -p .vibe/hooks
    
    # Create notification sound script based on OS
    case "$os_type" in
        "macos")
            create_macos_notifications
            ;;
        "linux")
            create_linux_notifications
            ;;
        "windows")
            create_windows_notifications
            ;;
        *)
            warning "Unknown OS. Creating generic notification scripts."
            create_generic_notifications
            ;;
    esac
    
    success "Notification scripts created"
}

# macOS notification scripts
create_macos_notifications() {
    info "Creating macOS notification scripts"
    
    # Task completion sound
    cat > .vibe/hooks/task_complete.sh << 'EOF'
#!/bin/bash
# Play system sound on macOS
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || echo "Task completed"
EOF
    
    # Blocking/waiting sound
    cat > .vibe/hooks/waiting_input.sh << 'EOF'
#!/bin/bash
# Play attention sound on macOS
afplay /System/Library/Sounds/Ping.aiff 2>/dev/null || echo "Waiting for input"
EOF
    
    # Error sound
    cat > .vibe/hooks/error_occurred.sh << 'EOF'
#!/bin/bash
# Play error sound on macOS
afplay /System/Library/Sounds/Basso.aiff 2>/dev/null || echo "Error occurred"
EOF
    
    chmod +x .vibe/hooks/*.sh
}

# Linux notification scripts
create_linux_notifications() {
    info "Creating Linux notification scripts"
    
    # Task completion sound
    cat > .vibe/hooks/task_complete.sh << 'EOF'
#!/bin/bash
# Play system sound on Linux
if command -v paplay &> /dev/null; then
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null
elif command -v aplay &> /dev/null; then
    aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null
else
    echo -e '\a'  # Terminal bell
fi
echo "Task completed"
EOF
    
    # Blocking/waiting sound
    cat > .vibe/hooks/waiting_input.sh << 'EOF'
#!/bin/bash
# Play attention sound on Linux
if command -v paplay &> /dev/null; then
    paplay /usr/share/sounds/freedesktop/stereo/message.oga 2>/dev/null
elif command -v aplay &> /dev/null; then
    aplay /usr/share/sounds/alsa/Noise.wav 2>/dev/null
else
    echo -e '\a\a'  # Terminal bell twice
fi
echo "Waiting for input"
EOF
    
    # Error sound
    cat > .vibe/hooks/error_occurred.sh << 'EOF'
#!/bin/bash
# Play error sound on Linux
if command -v paplay &> /dev/null; then
    paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga 2>/dev/null
elif command -v aplay &> /dev/null; then
    aplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null
else
    echo -e '\a\a\a'  # Terminal bell three times
fi
echo "Error occurred"
EOF
    
    chmod +x .vibe/hooks/*.sh
}

# Windows notification scripts
create_windows_notifications() {
    info "Creating Windows notification scripts"
    
    # Task completion sound
    cat > .vibe/hooks/task_complete.sh << 'EOF'
#!/bin/bash
# Play system sound on Windows
powershell -c "[System.Media.SystemSounds]::Asterisk.Play()" 2>/dev/null || echo "Task completed"
EOF
    
    # Blocking/waiting sound
    cat > .vibe/hooks/waiting_input.sh << 'EOF'
#!/bin/bash
# Play attention sound on Windows
powershell -c "[System.Media.SystemSounds]::Exclamation.Play()" 2>/dev/null || echo "Waiting for input"
EOF
    
    # Error sound
    cat > .vibe/hooks/error_occurred.sh << 'EOF'
#!/bin/bash
# Play error sound on Windows
powershell -c "[System.Media.SystemSounds]::Hand.Play()" 2>/dev/null || echo "Error occurred"
EOF
    
    chmod +x .vibe/hooks/*.sh
}

# Generic notification scripts (fallback)
create_generic_notifications() {
    info "Creating generic notification scripts"
    
    # Task completion sound
    cat > .vibe/hooks/task_complete.sh << 'EOF'
#!/bin/bash
# Generic notification
echo -e '\a'
echo "Task completed"
EOF
    
    # Blocking/waiting sound
    cat > .vibe/hooks/waiting_input.sh << 'EOF'
#!/bin/bash
# Generic notification
echo -e '\a\a'
echo "Waiting for input"
EOF
    
    # Error sound
    cat > .vibe/hooks/error_occurred.sh << 'EOF'
#!/bin/bash
# Generic notification
echo -e '\a\a\a'
echo "Error occurred"
EOF
    
    chmod +x .vibe/hooks/*.sh
}

# Create Claude Code settings template
create_claude_settings() {
    info "Creating Claude Code settings template"
    
    # Create settings directory if it doesn't exist
    local settings_dir="${HOME}/.config/claude"
    mkdir -p "$settings_dir"
    
    # Create settings template with hooks
    cat > .vibe/templates/claude-settings.json << 'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "TodoWrite",
        "hooks": [
          {
            "type": "command",
            "command": "${HOME}/.vibe/hooks/task_complete.sh",
            "timeout": 2000,
            "continueOnError": true
          }
        ]
      },
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "${HOME}/.vibe/hooks/task_complete.sh",
            "timeout": 2000,
            "continueOnError": true
          }
        ]
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "${HOME}/.vibe/hooks/waiting_input.sh",
        "timeout": 2000,
        "continueOnError": true
      }
    ],
    "UserPromptSubmit": [
      {
        "type": "validator",
        "command": "echo 'Processing your request...'",
        "timeout": 1000,
        "continueOnError": true
      }
    ]
  }
}
EOF
    
    # Create a simpler project-specific hook configuration
    cat > .vibe/claude-hooks.json << 'EOF'
{
  "description": "Vibe Coding Framework notification hooks",
  "hooks": {
    "task_complete": ".vibe/hooks/task_complete.sh",
    "waiting_input": ".vibe/hooks/waiting_input.sh",
    "error_occurred": ".vibe/hooks/error_occurred.sh"
  },
  "usage": "Copy settings from .vibe/templates/claude-settings.json to ~/.config/claude/settings.json"
}
EOF
    
    success "Claude Code settings template created"
}

# Create installation instructions
create_notification_readme() {
    info "Creating notification setup instructions"
    
    cat > .vibe/hooks/README.md << 'EOF'
# Vibe Coding Framework - Notification Sounds

This directory contains notification scripts that play sounds when certain events occur during development.

## Available Notifications

- `task_complete.sh` - Plays when a task is completed
- `waiting_input.sh` - Plays when Claude Code is waiting for user input
- `error_occurred.sh` - Plays when an error occurs

## Setup Instructions

### 1. Enable Claude Code Hooks

Add the hook configuration to your Claude Code settings:

**Option A: Global Settings**
Copy the contents of `.vibe/templates/claude-settings.json` to `~/.config/claude/settings.json`

**Option B: Project Settings**
Copy the contents of `.vibe/templates/claude-settings.json` to `.claude/settings.json` in your project root

### 2. Test Notifications

Run the scripts manually to test:

```bash
.vibe/hooks/task_complete.sh
.vibe/hooks/waiting_input.sh
.vibe/hooks/error_occurred.sh
```

### 3. Customize Sounds

You can modify the scripts to use different sounds or notification methods:

- **macOS**: Change the `.aiff` files in the scripts
- **Linux**: Change the sound files or use `notify-send` for desktop notifications
- **Windows**: Use different PowerShell SystemSounds

## Troubleshooting

If sounds don't play:

1. Check that your system has audio enabled
2. Verify the sound files exist on your system
3. Ensure the scripts have execute permissions: `chmod +x .vibe/hooks/*.sh`
4. Check Claude Code logs for hook execution errors

## Disabling Notifications

To disable notifications, remove or comment out the hooks section in your Claude Code settings file.
EOF
    
    success "Notification README created"
}

# Main setup function
setup_notifications() {
    create_notification_scripts
    create_claude_settings
    create_notification_readme
    
    info "Notification setup complete!"
    echo
    warning "To enable notifications in Claude Code:"
    echo "1. Copy settings from .vibe/templates/claude-settings.json"
    echo "2. Paste into ~/.config/claude/settings.json"
    echo "3. Restart Claude Code"
    echo
    info "Test sounds with: .vibe/hooks/task_complete.sh"
}

# Export functions
export -f setup_notifications
export -f create_notification_scripts
export -f detect_os