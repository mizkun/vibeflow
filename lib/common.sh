#!/bin/bash

# Vibe Coding Framework - Common Functions and Utilities
# This file contains shared functions used across all setup scripts

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_PROJECT_NAME="vibeflow"
DEFAULT_LANGUAGE="ja"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print info messages
info() {
    print_color "$BLUE" "ℹ️  $1"
}

# Function to print success messages
success() {
    print_color "$GREEN" "✅ $1"
}

# Function to print warning messages
warning() {
    print_color "$YELLOW" "⚠️  $1"
}

# Function to print error messages
error() {
    print_color "$RED" "❌ $1"
}

# Function to print section headers
section() {
    echo ""
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$CYAN" "  $1"
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    local missing_tools=()
    
    # Check for required tools
    local required_tools=("git" "cat" "mkdir" "chmod")
    
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "以下のツールがインストールされていません："
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        return 1
    fi
    
    return 0
}

# Function to create directory with error handling
create_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        if mkdir -p "$dir"; then
            success "ディレクトリを作成しました: $dir"
        else
            error "ディレクトリの作成に失敗しました: $dir"
            return 1
        fi
    else
        info "ディレクトリは既に存在します: $dir"
    fi
    return 0
}

# Function to create file with backup
create_file_with_backup() {
    local file=$1
    local content=$2
    
    # Create backup if file exists
    if [ -f "$file" ]; then
        local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_file"
        warning "既存ファイルをバックアップしました: $backup_file"
    fi
    
    # Create the file
    echo "$content" > "$file"
    if [ $? -eq 0 ]; then
        success "ファイルを作成しました: $file"
        return 0
    else
        error "ファイルの作成に失敗しました: $file"
        return 1
    fi
}

# Function to show progress
show_progress() {
    local current=$1
    local total=$2
    local task=$3
    local percent=$((current * 100 / total))
    
    echo -ne "\r[${percent}%] ${task}..."
    
    if [ $current -eq $total ]; then
        echo -e "\r[100%] ${task}... ✅"
    fi
}

# Function to prompt for confirmation
confirm() {
    local message=$1
    local response
    
    read -p "❓ ${message} (y/N): " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macOS"
            ;;
        Linux*)
            echo "Linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "Windows"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Function to get script directory
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")" && pwd)"
}

# Export functions and variables for use in other scripts
export -f print_color info success warning error section
export -f command_exists check_prerequisites create_directory
export -f create_file_with_backup show_progress confirm detect_os
export RED GREEN YELLOW BLUE PURPLE CYAN NC