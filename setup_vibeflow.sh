#!/bin/bash

# Vibe Coding Framework Setup Script
# This is the main setup script that orchestrates the installation
# Includes: GitHub Issues, Iris, Multi-Terminal, 3-Tier Context, Safety Rules

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail

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
source "${LIB_DIR}/framework_version.sh"

# Source all modules
source "${LIB_DIR}/create_structure.sh"
source "${LIB_DIR}/create_claude_md.sh"
source "${LIB_DIR}/create_commands.sh"
source "${LIB_DIR}/create_templates.sh"

# Source optional modules if they exist
if [ -f "${LIB_DIR}/create_playwright.sh" ]; then
    source "${LIB_DIR}/create_playwright.sh"
fi
if [ -f "${LIB_DIR}/create_notifications.sh" ]; then
    source "${LIB_DIR}/create_notifications.sh"
fi

# Source new Claude Code integration modules
if [ -f "${LIB_DIR}/create_access_guard.sh" ]; then
    source "${LIB_DIR}/create_access_guard.sh"
fi
if [ -f "${LIB_DIR}/create_claude_settings.sh" ]; then
    source "${LIB_DIR}/create_claude_settings.sh"
fi
if [ -f "${LIB_DIR}/create_skills.sh" ]; then
    source "${LIB_DIR}/create_skills.sh"
fi
if [ -f "${LIB_DIR}/create_subagents.sh" ]; then
    source "${LIB_DIR}/create_subagents.sh"
fi
if [ -f "${LIB_DIR}/create_dev_launcher.sh" ]; then
    source "${LIB_DIR}/create_dev_launcher.sh"
fi
if [ -f "${LIB_DIR}/create_labels.sh" ]; then
    source "${LIB_DIR}/create_labels.sh"
fi

# Global variables — version comes from framework_version.sh (sourced above)
VERSION="$FRAMEWORK_VERSION"
FORCE_INSTALL=false
BACKUP_ENABLED=true
VERBOSE=false
WITH_E2E=false
# Note: --with-notifications is deprecated; hooks are now integrated by default

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
    --with-e2e          Include Playwright E2E testing setup

Features (included by default):
    - GitHub Issues integration: Task management via gh CLI
    - Iris: Strategic partner for planning and context management
    - Multi-Terminal: Iris (permanent) + Dev terminal(s) (per-issue)
    - 3-Tier Context: context/ + references/ + archive/
    - Safety Rules: UI/CSS atomic mode, destructive op guard, write guard
    - Hooks: Access control (validate_access.py), Write guard (validate_write.sh)
    - Skills: vibeflow-issue-template, vibeflow-tdd
    - Subagents: qa-acceptance, code-reviewer, test-runner

Examples:
    $0                  Normal installation with confirmations
    $0 --force          Install without asking for confirmation
    $0 --no-backup      Install without creating backups
    $0 --with-e2e       Install with E2E testing support

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
            --with-e2e)
                WITH_E2E=true
                shift
                ;;
            --with-notifications)
                # Deprecated: notifications are now included by default
                warning "--with-notifications は廃止されました。通知はデフォルトで有効です。"
                shift
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
    # clear - disabled for non-interactive use
    print_color "$CYAN" "
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🚀 Vibe Coding Framework Setup Script v${VERSION}            ║
║                                                              ║
║     An AI-driven development methodology with                ║
║     role separation and structured workflow automation       ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"
    echo ""
    info "このスクリプトは以下を実行します："
    echo "  • ディレクトリ構造の作成"
    echo "  • CLAUDE.mdドキュメントの生成（ロールベースシステム）"
    echo "  • スラッシュコマンドの設定"
    echo "  • テンプレートファイルの生成（拡張state.yaml）"
    echo "  • ロールベースのコンテキスト継続型開発環境"
    echo ""
}

# Function to check if running in vibeflow repository
check_repository_location() {
    local current_dir="$(pwd)"
    local script_parent_dir="$(dirname "$SCRIPT_DIR")"
    
    # Detect execution inside the vibeflow repository itself
    if [[ "$current_dir" == "$SCRIPT_DIR" || "$current_dir" == "$script_parent_dir" ]]; then
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
    
    # Step 4: Create templates
    if ! create_templates; then
        error "テンプレートの作成に失敗しました"
        exit 1
    fi
    
    # Step 5: Create Access Guard Hook (validates role-based file access)
    if type create_access_guard &>/dev/null; then
        if ! create_access_guard; then
            warning "アクセスガードフックの作成に失敗しましたが、インストールは続行します"
        fi
    else
        warning "アクセスガードモジュールが見つかりません"
    fi
    
    # Step 5b: Create Write Guard Hook (validates plans/ directory block)
    if type create_write_guard &>/dev/null; then
        if ! create_write_guard; then
            warning "書き込みガードフックの作成に失敗しましたが、インストールは続行します"
        fi
    else
        warning "書き込みガードモジュールが見つかりません"
    fi

    # Step 6: Create Claude Code Settings (hooks configuration)
    if type create_claude_settings &>/dev/null; then
        if ! create_claude_settings; then
            warning "Claude Code設定の作成に失敗しましたが、インストールは続行します"
        fi
        # Also create notification hook scripts
        if type create_notification_hooks &>/dev/null; then
            create_notification_hooks
        fi
    else
        warning "Claude Code設定モジュールが見つかりません"
    fi
    
    # Step 7: Create Skills
    if type create_skills &>/dev/null; then
        if ! create_skills; then
            warning "Skillsの作成に失敗しましたが、インストールは続行します"
        fi
    else
        warning "Skillsモジュールが見つかりません"
    fi
    
    # Step 8: Create Subagents
    if type create_subagents &>/dev/null; then
        if ! create_subagents; then
            warning "Subagentsの作成に失敗しましたが、インストールは続行します"
        fi
    else
        warning "Subagentsモジュールが見つかりません"
    fi
    
    # Step 8b: Create Step 7a Guard Hook
    if type create_step7a_guard &>/dev/null; then
        if ! create_step7a_guard; then
            warning "Step 7a ガードフックの作成に失敗しましたが、インストールは続行します"
        fi
    fi

    # Step 8c: Create Dev Launcher
    if type create_dev_launcher &>/dev/null; then
        if ! create_dev_launcher; then
            warning "開発ランチャーの作成に失敗しましたが、インストールは続行します"
        fi
    fi

    # Step 9: Create GitHub Labels from issue_labels.yaml
    if type create_github_labels &>/dev/null; then
        if ! create_github_labels; then
            warning "GitHub ラベルの作成に失敗しましたが、インストールは続行します"
        fi
    fi

    # Setup E2E testing (optional)
    if [ "$WITH_E2E" = true ]; then
        if type setup_playwright &>/dev/null; then
            if ! setup_playwright; then
                warning "E2Eテストのセットアップに失敗しましたが、インストールは続行します"
            fi
        else
            warning "E2Eセットアップスクリプトが見つかりません"
        fi
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

    # Verify commands directory and key command files
    if [ -d ".claude/commands" ]; then
        success ".claude/commands: OK"
        local cmds=(
            ".claude/commands/progress.md"
            ".claude/commands/healthcheck.md"
            ".claude/commands/discuss.md"
            ".claude/commands/conclude.md"
        )
        for c in "${cmds[@]}"; do
            if [ -f "$c" ]; then
                success "$c: OK"
            else
                warning "$c: Missing"
            fi
        done
        # Optional: run-e2e
        if [ -f ".claude/commands/run-e2e.md" ]; then
            success ".claude/commands/run-e2e.md: OK"
        fi
    else
        error ".claude/commands: NG"
        all_good=false
    fi
    
    # Verify Claude Code settings
    if [ -f ".claude/settings.json" ]; then
        success ".claude/settings.json: OK"
        # Verify JSON syntax
        if python3 -c "import json; json.load(open('.claude/settings.json'))" 2>/dev/null; then
            success ".claude/settings.json 構文: OK"
        else
            warning ".claude/settings.json 構文: JSON形式エラー"
        fi
    else
        warning ".claude/settings.json: Missing (Hooks無効)"
    fi
    
    # Verify Write Guard Hook
    if [ -f ".vibe/hooks/validate_write.sh" ]; then
        success ".vibe/hooks/validate_write.sh: OK"
        if [ -x ".vibe/hooks/validate_write.sh" ]; then
            success ".vibe/hooks/validate_write.sh 実行権限: OK"
        else
            warning ".vibe/hooks/validate_write.sh 実行権限: Missing"
        fi
    else
        warning ".vibe/hooks/validate_write.sh: Missing (書き込みガード無効)"
    fi

    # Verify v3 files
    local v3_files=(
        ".vibe/context"
        ".vibe/context/STATUS.md"
        ".vibe/references"
        ".vibe/archive"
        ".vibe/roles/iris.md"
        ".vibe/roles/infra.md"
        ".github/ISSUE_TEMPLATE"
    )
    for v3_item in "${v3_files[@]}"; do
        if [ -e "$v3_item" ]; then
            success "$v3_item: OK"
        else
            warning "$v3_item: Missing"
        fi
    done

    # Verify Access Guard Hook
    if [ -f ".vibe/hooks/validate_access.py" ]; then
        success ".vibe/hooks/validate_access.py: OK"
        if [ -x ".vibe/hooks/validate_access.py" ]; then
            success ".vibe/hooks/validate_access.py 実行権限: OK"
        else
            warning ".vibe/hooks/validate_access.py 実行権限: Missing"
        fi
    else
        warning ".vibe/hooks/validate_access.py: Missing (アクセス制御無効)"
    fi
    
    # Verify Skills
    if type verify_skills &>/dev/null; then
        verify_skills
    else
        if [ -d ".claude/skills" ]; then
            local skill_count=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l)
            if [ "$skill_count" -gt 0 ]; then
                success ".claude/skills: $skill_count skill(s) found"
            else
                warning ".claude/skills: No skills found"
            fi
        fi
    fi
    
    # Verify Subagents
    if type verify_subagents &>/dev/null; then
        verify_subagents
    else
        if [ -d ".claude/agents" ]; then
            local agent_count=$(find .claude/agents -name "*.md" 2>/dev/null | wc -l)
            if [ "$agent_count" -gt 0 ]; then
                success ".claude/agents: $agent_count agent(s) found"
            else
                warning ".claude/agents: No agents found"
            fi
        fi
    fi
    
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
    echo "   • plan.md   - ロードマップ"
    echo ""
    echo "2. GitHub リポジトリを作成し、gh CLI を認証してください："
    echo "   gh auth login"
    echo ""
    echo "3. Claude Code でこのディレクトリを開いてください"
    echo ""
    echo "4. マルチターミナルで開発を開始："
    echo "   Terminal 1 (Iris): /discuss"
    echo "   Terminal 2 (Development):     Issue 単位で実装"
    echo ""
    echo "利用可能なコマンド:"
    echo "   /discuss     - Iris セッション開始"
    echo "   /conclude    - セッション終了・STATUS.md 更新"
    echo "   /progress    - 現在の進捗確認（GitHub Issues 統合）"
    echo "   /healthcheck - 整合性チェック"
    echo "   /run-e2e     - E2Eテスト実行（Playwright導入時）"
    echo ""
    print_color "$PURPLE" "🎉 Happy Vibe Coding!"
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    # Enable verbose trace when requested
    if [ "$VERBOSE" = true ]; then
        set -x
    fi
    
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
        # Write framework version file
        write_version_file "."
        # Write simple version file for upgrade tracking
        echo "$VERSION" > ".vibe/version"
        show_completion
    else
        error "インストールの検証に失敗しました"
        warning "問題が発生した場合は、バックアップから復元できます"
        exit 1
    fi
}

# Run main function
main "$@"