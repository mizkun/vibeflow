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
