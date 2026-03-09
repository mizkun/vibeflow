---
name: vibeflow-progress
description: Check current project progress and role status. Use when reviewing project state, open issues, and roadmap progress.
---

# VibeFlow Progress Check

## When to Use
- When checking current project status
- When reviewing open issues and roadmap
- When preparing for sprint planning or standup

## Instructions

以下を確認して包括的な進捗レポートを作成してください:

1. `.vibe/project_state.yaml` を読み込み、プロジェクト全体の状態を確認
2. `.vibe/sessions/iris-main.yaml` を読み込み、Iris セッションの状態を確認
3. `.vibe/context/STATUS.md` を読み込み、プロジェクトの全体像を確認
4. `gh issue list --state open` で未完了の Issue を取得
5. `gh issue list --state closed --limit 10` で最近完了した Issue を確認
6. `plan.md` でロードマップの進捗を確認

> **Note**: `.vibe/state.yaml` が存在する場合は旧形式の fallback として参照してもよいが、正本は `project_state.yaml` + `sessions/*.yaml` です。

## 出力フォーマット

```
Project Progress

## プロジェクト状態
- Current Phase: [project_state.yaml の current_phase]
- Current Role: [sessions/iris-main.yaml の current_role]
- Active Issue: [project_state.yaml の active_issue]

## GitHub Issues
- Open: N (dev: X, human: Y, discussion: Z)
- Recently Closed: N

## Active Issues (type:dev)
- #N [Title] (status label)
- ...

## Human Action Waiting (type:human)
- #N [Title]
- ...

## ロードマップ
[plan.md の現在のフェーズ進捗]

## Next Actions
1. [最優先の未着手Issue]
2. [次に着手すべきIssue]
```

日本語で表示してください。

## Examples
- "プロジェクトの進捗を確認"
- "/progress"
