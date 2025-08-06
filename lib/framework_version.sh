#!/bin/bash

# Vibe Coding Framework - Version Management
# This script handles framework versioning

# Current framework version
FRAMEWORK_VERSION="0.4.1"
FRAMEWORK_NAME="Simplified State Management with E2E, Notifications & Quick Fix"
FRAMEWORK_RELEASE_DATE="2024-12-20"

# Function to write version file
write_version_file() {
    local target_dir=$1
    cat > "${target_dir}/.vibe/framework_version.yaml" << EOF
# Vibe Coding Framework Version Information
framework:
  version: "${FRAMEWORK_VERSION}"
  name: "${FRAMEWORK_NAME}"
  installed_at: "$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')"
  
  # Version compatibility
  minimum_compatible: "0.3.0"
  
  # Features enabled
  features:
    simplified_state: true
    verification_system: true
    quick_fix_mode: true
    e2e_testing: true
    notifications: true
  
  # Project repository
  repository_url: "https://github.com/mizkun/vibeflow"
EOF
}

# Export function
export -f write_version_file