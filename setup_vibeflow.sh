#!/bin/bash

# Vibe Coding Framework Setup Script
# Version: 2.0
# This is the main setup script that orchestrates the installation

set -e  # Exit on error
set -u  # Exit on undefined variable

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Check if lib directory exists
if [ ! -d "$LIB_DIR" ]; then
    echo "❌ Error: lib directory not found at $LIB_DIR"
    echo "Please ensure all files are properly extracted."
    exit 1
fi

# Source common functions
source "${LIB_DIR}/common.sh"

# Source all modules
source "${LIB_DIR}/create_structure.sh"
source "${LIB_DIR}/create_claude_md.sh"
source "${LIB_DIR}/create_commands.sh"
source "${LIB_DIR}/create_agents.sh"
source "${LIB_DIR}/create_templates.sh"

# Global variables
VERSION="2.0"
FORCE_INSTALL=false
BACKUP_ENABLED=true
VERBOSE=false

# Function to show usage
show_usage() {
    cat << EOF
Vibe Coding Framework Setup Script v${VERSION}

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -f, --force         Force installation without confirmation
    -n, --no-backup     Skip backup of existing files
    -v, --verbose       Enable verbose output
    -V, --version       Show version information

Examples:
    $0                  Normal installation with confirmations
    $0 --force          Install without asking for confirmation
    $0 --no-backup      Install without creating backups

EOF
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--force)
                FORCE_INSTALL=true
                shift
                ;;
            -n|--no-backup)
                BACKUP_ENABLED=false
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -V|--version)
                echo "Vibe Coding Framework Setup Script v${VERSION}"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to show welcome message
show_welcome() {
    clear
    print_color "$CYAN" "
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🚀 Vibe Coding Framework Setup Script v${VERSION}              ║
║                                                              ║
║     An AI-driven development methodology with                ║
║     role separation and structured workflow automation       ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"
    echo ""
    info "このスクリプトは以下を実行します："
    echo "  • ディレクトリ構造の作成"
    echo "  • CLAUDE.mdドキュメントの生成"
    echo "  • スラッシュコマンドの設定"
    echo "  • 4つのSubagentの作成"
    echo "  • テンプレートファイルの生成"
    echo ""
}

# Function to check if running in vibeflow repository
check_repository_location() {
    local current_dir="$(pwd)"
    local script_parent_dir="$(dirname "$SCRIPT_DIR")"
    
    # Check if we're in the vibeflow repository itself
    if [ -f "$current_dir/setup_vibeflow.sh" ] && [ -d "$current_dir/lib" ] && [ -d "$current_dir/docs" ]; then
        warning "Vibe Codingリポジトリ内で実行しようとしています！"
        echo ""
        echo "  推奨される使い方："
        echo "  1. 新しいプロジェクトディレクトリを作成"
        echo "  2. そのディレクトリに移動"
        echo "  3. このスクリプトを実行"
        echo ""
        echo "  例:"
        echo "    mkdir ~/my-project"
        echo "    cd ~/my-project"
        echo "    $SCRIPT_DIR/setup_vibeflow.sh"
        echo ""
        
        if [ "$FORCE_INSTALL" = false ]; then
            if ! confirm "本当にこのディレクトリで続行しますか？"; then
                info "インストールをキャンセルしました。"
                exit 0
            fi
        fi
    fi
}

# Function to check existing installation
check_existing_installation() {
    local has_existing=false
    
    if [ -f "CLAUDE.md" ] || [ -d ".claude" ] || [ -d ".vibe" ]; then
        has_existing=true
    fi
    
    if [ "$has_existing" = true ] && [ "$FORCE_INSTALL" = false ]; then
        warning "既存のVibe Coding設定が見つかりました。"
        if ! confirm "既存の設定を上書きしてもよろしいですか？"; then
            info "インストールをキャンセルしました。"
            exit 0
        fi
    fi
}

# Function to create backup
create_backup() {
    if [ "$BACKUP_ENABLED" = false ]; then
        return 0
    fi
    
    local backup_dir=".vibe_backup_$(date +%Y%m%d_%H%M%S)"
    local files_to_backup=()
    
    # Check which files need backing up
    [ -f "CLAUDE.md" ] && files_to_backup+=("CLAUDE.md")
    [ -f "vision.md" ] && files_to_backup+=("vision.md")
    [ -f "spec.md" ] && files_to_backup+=("spec.md")
    [ -f "plan.md" ] && files_to_backup+=("plan.md")
    [ -d ".claude" ] && files_to_backup+=(".claude")
    [ -d ".vibe" ] && files_to_backup+=(".vibe")
    [ -d "issues" ] && files_to_backup+=("issues")
    
    if [ ${#files_to_backup[@]} -gt 0 ]; then
        info "既存ファイルをバックアップ中..."
        mkdir -p "$backup_dir"
        
        for item in "${files_to_backup[@]}"; do
            cp -r "$item" "$backup_dir/"
        done
        
        success "バックアップを作成しました: $backup_dir"
    fi
}

# Function to run installation
run_installation() {
    section "インストールを開始します"
    
    # Step 1: Create directory structure
    if ! create_vibe_structure; then
        error "ディレクトリ構造の作成に失敗しました"
        exit 1
    fi
    
    # Step 2: Create CLAUDE.md
    if ! create_claude_md; then
        error "CLAUDE.mdの作成に失敗しました"
        exit 1
    fi
    
    # Step 3: Create slash commands
    if ! create_slash_commands; then
        error "スラッシュコマンドの作成に失敗しました"
        exit 1
    fi
    
    # Step 4: Create subagents
    if ! create_subagents; then
        error "Subagentの作成に失敗しました"
        exit 1
    fi
    
    # Step 5: Create templates
    if ! create_templates; then
        error "テンプレートの作成に失敗しました"
        exit 1
    fi
}

# Function to verify installation
verify_installation() {
    section "インストールを検証中"
    
    local all_good=true
    
    # Verify directory structure
    if verify_structure; then
        success "ディレクトリ構造: OK"
    else
        error "ディレクトリ構造: NG"
        all_good=false
    fi
    
    # Verify key files
    local key_files=("CLAUDE.md" "vision.md" "spec.md" "plan.md" ".vibe/state.yaml")
    for file in "${key_files[@]}"; do
        if [ -f "$file" ]; then
            success "$file: OK"
        else
            error "$file: NG"
            all_good=false
        fi
    done
    
    if [ "$all_good" = true ]; then
        success "すべての検証に合格しました！"
        return 0
    else
        error "一部のファイルが正しく作成されていません"
        return 1
    fi
}

# Function to show completion message
show_completion() {
    section "セットアップ完了！"
    
    print_color "$GREEN" "
✅ Vibe Coding Framework のセットアップが完了しました！

📝 次のステップ:
"
    echo "1. 以下のファイルを編集して、プロジェクトの内容を記入してください："
    echo "   • vision.md - プロダクトビジョン"
    echo "   • spec.md   - 仕様と技術設計"
    echo "   • plan.md   - 開発計画とTODO"
    echo ""
    echo "2. Claude Code でこのディレクトリを開いてください"
    echo ""
    echo "3. 以下のコマンドで開発を開始できます："
    print_color "$YELLOW" '   "開発サイクルを開始して"'
    echo ""
    echo "利用可能なコマンド:"
    echo "   /progress    - 現在の進捗確認"
    echo "   /healthcheck - 整合性チェック"
    echo "   /vibe-status - 設定確認"
    echo ""
    print_color "$PURPLE" "🎉 Happy Vibe Coding!"
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show welcome message
    show_welcome
    
    # Check prerequisites
    info "前提条件をチェック中..."
    if ! check_prerequisites; then
        error "前提条件のチェックに失敗しました"
        exit 1
    fi
    success "前提条件のチェック: OK"
    
    # Check if running in repository
    check_repository_location
    
    # Check for existing installation
    check_existing_installation
    
    # Create backup if needed
    create_backup
    
    # Run installation
    run_installation
    
    # Verify installation
    if verify_installation; then
        show_completion
    else
        error "インストールの検証に失敗しました"
        warning "問題が発生した場合は、バックアップから復元できます"
        exit 1
    fi
}

# Run main function
main "$@"