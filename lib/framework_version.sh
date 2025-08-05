#!/bin/bash

# Vibe Coding Framework - Version Management
# This script handles framework versioning

# Current framework version
FRAMEWORK_VERSION="3.2.0"
FRAMEWORK_NAME="Orchestrator Context with E2E, Notifications & Quick Fix"
FRAMEWORK_RELEASE_DATE="2024-12-20"

# Version history
declare -A VERSION_HISTORY=(
    ["1.0.0"]="Initial release"
    ["2.0.0"]="Modular architecture, error handling"
    ["3.0.0"]="Orchestrator Context, verification system"
    ["3.1.0"]="E2E testing with Playwright, notification sounds"
    ["3.2.0"]="Quick Fix Mode for rapid minor adjustments"
)

# Breaking changes by version
declare -A BREAKING_CHANGES=(
    ["2.0.0"]="Script modularization"
    ["3.0.0"]="New state.yaml format, Orchestrator required"
)

# Function to check version compatibility
check_version_compatibility() {
    local project_version=$1
    local target_version=$2
    
    # Extract major version numbers
    local project_major=$(echo "$project_version" | cut -d. -f1)
    local target_major=$(echo "$target_version" | cut -d. -f1)
    
    if [ "$project_major" -lt "$target_major" ]; then
        return 1  # Upgrade needed
    else
        return 0  # Compatible
    fi
}

# Function to get version info
get_version_info() {
    echo "Vibe Coding Framework v${FRAMEWORK_VERSION} - ${FRAMEWORK_NAME}"
    echo "Released: ${FRAMEWORK_RELEASE_DATE}"
}

# Function to write version file
write_version_file() {
    local target_dir=$1
    cat > "${target_dir}/.vibe/framework_version.yaml" << EOF
# Vibe Coding Framework Version Information
framework:
  version: "${FRAMEWORK_VERSION}"
  name: "${FRAMEWORK_NAME}"
  installed_at: "$(date -Iseconds)"
  
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

# Export functions
export -f check_version_compatibility
export -f get_version_info
export -f write_version_file