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
