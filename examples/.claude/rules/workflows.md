# Workflows

VibeFlow v5 のワークフロー一覧。Iris がワークフローを自動選択・進行します。

## Standard Workflow (11 Steps)

詳細は `workflow-standard.md` を参照。

## Patch Workflow (4 Steps)

詳細は `workflow-patch.md` を参照。

## Spike Workflow

探索・調査 — 意思決定を出力する（本番コードは書かない）

| Step | Role | Mode |
|------|------|------|
| 1_question_framing | iris | solo |
| 2_exploration | coding_agent | solo |
| 3_decision_summary | iris | solo |

## Ops Workflow

非開発タスク（リリース、ドキュメント、バックログ整理）

| Step | Role | Mode |
|------|------|------|
| 1_task_review | iris | solo |
| 2_execution | iris | solo |
| 3_completion | iris | solo |
