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

