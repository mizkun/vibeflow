---
description: Enter quick fix mode for minor adjustments
---

Enter Quick Fix Mode - a streamlined mode for minor changes:

## Activation
Print mode change:
🔧 ENTERING QUICK FIX MODE

Bypassing normal workflow for minor adjustments
Allowed: UI tweaks, typos, small bug fixes
Max scope: 5 files, <50 lines total changes

## Constraints in Quick Fix Mode
- Can modify any file directly
- Must document all changes
- Cannot add new features
- Cannot modify database schema
- Must exit properly with /exit-quickfix

## Process
1. Make the requested minor changes
2. Run relevant tests if any
3. Document changes in state.yaml under "quick_fixes"
4. Commit with prefix: "quickfix: [description]"

## 使用方法
`/quickfix [修正内容の説明]`

例:
- `/quickfix ボタンの色を青に変更`
- `/quickfix ヘッダーの余白を調整`
- `/quickfix タイポを修正`

Note: This mode operates in the main context, not as a subagent. All changes are made directly while maintaining context continuity.