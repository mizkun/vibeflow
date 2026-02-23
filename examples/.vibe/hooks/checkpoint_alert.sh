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
