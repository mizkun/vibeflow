---
description: Check project progress (compatibility — prefer vibeflow-progress skill)
---

# プロジェクト進捗確認

> **Note**: This command is a compatibility wrapper. The canonical implementation is the `vibeflow-progress` skill.

以下を確認して包括的な進捗レポートを作成してください:

1. `.vibe/state.yaml` を読み込み、現在の状態を確認
2. `.vibe/context/STATUS.md` を読み込み、プロジェクトの全体像を確認
3. `gh issue list --state open` で未完了の Issue を取得
4. `gh issue list --state closed --limit 10` で最近完了した Issue を確認
5. `plan.md` でロードマップの進捗を確認

## 出力フォーマット

```
Project Progress

## プロジェクト状態
- Current Role: [role]
- Phase: [phase]
- Current Issue: [issue]

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

日本語で表示し、絵文字で視認性を向上させてください。
