#!/bin/bash

# Vibe Coding Framework - Version Management
# This script handles framework versioning

# Current framework version
FRAMEWORK_VERSION="3.2.0"
FRAMEWORK_NAME="Orchestrator Context with E2E, Notifications & Quick Fix"
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
  minimum_compatible: "3.0.0"
  
  # Features enabled
  features:
    orchestrator_context: true
    verification_system: true
    health_monitoring: true
    cross_role_communication: true
  
  # Change log reference
  changelog_url: "https://github.com/mizkun/vibeflow/blob/main/CHANGELOG.md"
EOF
}

# Export function
export -f write_version_file