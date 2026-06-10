---
description: Execute a single GitHub Issue through the full 11-Step workflow (compatibility — prefer vibeflow-execute-issue skill)
---

# Issue を 11-Step Workflow で自動完遂する

> **Note**: This command is a compatibility wrapper. The canonical implementation is the `vibeflow-execute-issue` skill.

IMPORTANT: Issue 番号が必須です。`/execute-issue <番号>` の形式で呼び出してください。

`vibeflow-execute-issue` スキルを起動し、指定された Issue を 11-Step Workflow
（Issue Review → Task Breakdown → Branch → TDD → Implementation → Refactoring →
Acceptance Test → Human Checkpoint → PR → Cross-Review → Merge → Close）で完遂してください。

## 使い方

```
/execute-issue <issue番号>
```
