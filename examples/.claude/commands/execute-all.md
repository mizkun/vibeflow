---
description: Execute all open GitHub Issues in dependency order (compatibility — prefer vibeflow-execute-all skill)
---

# Open Issues を依存順に一括実行する

> **Note**: This command is a compatibility wrapper. The canonical implementation is the `vibeflow-execute-all` skill.

`vibeflow-execute-all` スキルを起動し、Open 状態の Issue を依存関係順に
1 件ずつ 11-Step Workflow で実行してください。各 Issue の完了ごとに進捗を報告し、
失敗した Issue はリトライポリシーに従って処理してください。

## 使い方

```
/execute-all
```
