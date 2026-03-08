#!/bin/bash
# VibeFlow Issues Migration Tool
# Converts local issues/*.md to GitHub Issues via gh CLI
#
# Usage: bash .vibe/tools/migrate-issues.sh [--dry-run]

set -euo pipefail

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
    echo "🔍 DRY RUN MODE - no changes will be made"
    echo ""
fi

# Check prerequisites
if ! command -v gh &>/dev/null; then
    echo "❌ gh CLI is not installed. Install it: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &>/dev/null 2>&1; then
    echo "❌ gh is not authenticated. Run: gh auth login"
    exit 1
fi

# Ensure required labels exist
ensure_labels() {
    local labels=(
        "type:dev|0e8a16|開発タスク"
        "type:human|d93f0b|ヒューマンアクション"
        "type:discussion|0075ca|議論・検討"
        "status:implementing|fbca04|実装中"
        "status:testing|f9d0c4|テスト中"
        "status:pr-ready|c2e0c6|PRレビュー待ち"
        "priority:critical|b60205|即座に対応"
        "priority:high|d93f0b|高優先度"
        "priority:medium|fbca04|通常優先度"
        "priority:low|c5def5|低優先度"
    )
    echo "🏷️  Ensuring labels exist..."
    for entry in "${labels[@]}"; do
        IFS='|' read -r name color desc <<< "$entry"
        if ! gh label list --search "$name" --json name -q '.[].name' 2>/dev/null | grep -qF "$name"; then
            if [ "$DRY_RUN" = true ]; then
                echo "     [DRY RUN] Would create label: $name"
            else
                gh label create "$name" --color "$color" --description "$desc" 2>/dev/null || true
            fi
        fi
    done
    echo ""
}

ensure_labels

ISSUES_DIR="issues"
if [ ! -d "$ISSUES_DIR" ]; then
    echo "ℹ️  issues/ directory not found. Nothing to migrate."
    exit 0
fi

# Count files
file_count=$(find "$ISSUES_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
if [ "$file_count" -eq 0 ]; then
    echo "ℹ️  No .md files found in issues/. Nothing to migrate."
    exit 0
fi

echo "📋 Found $file_count issue file(s) to migrate"
echo ""

migrated=0
failed=0

for issue_file in "$ISSUES_DIR"/*.md; do
    [ -f "$issue_file" ] || continue

    filename=$(basename "$issue_file")

    # Extract title from first H1 or filename
    title=$(grep -m1 '^# ' "$issue_file" | sed 's/^# //' || echo "$filename")
    if [ -z "$title" ]; then
        title="$filename"
    fi

    # Read body
    body=$(cat "$issue_file")

    # Add migration note
    body="${body}

---
_Migrated from local \`issues/${filename}\` by VibeFlow v3 migration tool_"

    echo "  📄 $filename → \"$title\""

    if [ "$DRY_RUN" = true ]; then
        echo "     [DRY RUN] Would create GitHub Issue with label type:dev"
        migrated=$((migrated + 1))
        continue
    fi

    # Create GitHub Issue
    if issue_url=$(gh issue create --title "$title" --body "$body" --label "type:dev" 2>&1); then
        echo "     ✅ Created: $issue_url"
        migrated=$((migrated + 1))
    else
        echo "     ❌ Failed: $issue_url"
        failed=$((failed + 1))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $migrated migrated, $failed failed"

if [ "$DRY_RUN" = false ] && [ "$failed" -eq 0 ] && [ "$migrated" -gt 0 ]; then
    echo ""
    echo "All issues migrated successfully."
    echo "You can now safely remove the issues/ directory:"
    echo "  rm -rf issues/"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
