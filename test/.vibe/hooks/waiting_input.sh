#!/bin/bash
# Play attention sound on macOS
afplay /System/Library/Sounds/Ping.aiff 2>/dev/null || echo "Waiting for input"
