#!/bin/bash
# Waiting for input notification hook
# Called by Stop hook when Claude Code stops and waits for user input

OS_TYPE="$(uname -s)"

case "$OS_TYPE" in
    Darwin*)
        # macOS: Use afplay with system sound
        afplay /System/Library/Sounds/Ping.aiff 2>/dev/null &
        ;;
    Linux*)
        # Linux: Try paplay (PulseAudio) or aplay (ALSA)
        if command -v paplay &>/dev/null; then
            paplay /usr/share/sounds/freedesktop/stereo/message.oga 2>/dev/null &
        elif command -v aplay &>/dev/null; then
            aplay /usr/share/sounds/sound-icons/prompt.wav 2>/dev/null &
        fi
        ;;
esac

exit 0

