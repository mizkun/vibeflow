#!/bin/bash
# Play error sound on macOS
afplay /System/Library/Sounds/Basso.aiff 2>/dev/null || echo "Error occurred"
