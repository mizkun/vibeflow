# VibeFlow v5 — Iris-Only Architecture

**Language**: Communicate in Japanese (日本語) for all interactions.

## Overview

VibeFlow v5 は Iris-Only アーキテクチャです。ユーザーは Iris とだけ会話します。
Iris が Issue 作成 → coding agent 選択 → dispatch → 結果収集 → QA 判断 → クローズ を一貫して行います。

詳細なルールは `.claude/rules/` を参照してください。

## Role Definitions

<!-- VF:BEGIN roles -->
### Iris
**Description**: プロジェクトの唯一のインターフェース (default entry point) — triage、dispatch、QA判断、クローズ
**Enforcement**: hard
**Can Write**: `vision.md`, `spec.md`, `plan.md`, `.vibe/**`

### Coding Agent (Claude Code / Codex)
**Description**: コーディング、テスト、リファクタリング
**Enforcement**: hard
**Can Write**: `src/*`, `tests/*`, `**/*.test.*`, `**/__tests__/*`, `.vibe/project_state.yaml`, `.vibe/sessions/*.yaml`, `.vibe/state.yaml`, `.vibe/test-results.log`

<!-- VF:END roles -->

## Architecture

```
ユーザー ── Iris (単一ターミナル) ──┬── Claude Code (default: 実装)
                                    └── Codex (default: レビュー)
```

### Agent Selection
- **Default**: Claude Code (実装)、Codex (クロスレビュー)
- **Codex**: sandbox 実行が必要な場合、Claude Code 2回失敗時のフォールバック

### Cross-Review
コーディングしなかった方の agent がレビューする。

## Workflow

<!-- VF:BEGIN workflow -->
### Standard Workflow
Standard development workflow — Iris dispatches to Coding Agent, reviews results

| Step | Role | Mode |
|------|------|------|
| 1_issue_review | iris | solo |
| 2_task_breakdown | iris | solo |
| 3_branch_creation | coding_agent | solo |
| 4_test_writing | coding_agent | solo |
| 5_implementation | coding_agent | solo |
| 6_refactoring | coding_agent | solo |
| 7_acceptance_test | iris | solo |
| 8_pr_creation | coding_agent | solo |
| 9_code_review | iris | solo |
| 10_merge | coding_agent | solo |

### Patch Workflow
Lightweight patch loop for scoped fixes from QA/review feedback

| Step | Role | Mode |
|------|------|------|
| 1_scope_review | iris | solo |
| 2_fix_implementation | coding_agent | solo |
| 3_targeted_test | coding_agent | solo |
| 4_commit | coding_agent | solo |

### Spike Workflow
Exploration and discovery — produces decisions, not production code

| Step | Role | Mode |
|------|------|------|
| 1_question_framing | iris | solo |
| 2_exploration | coding_agent | solo |
| 3_decision_summary | iris | solo |

### Ops Workflow
Non-development project tasks (release, docs, backlog grooming)

| Step | Role | Mode |
|------|------|------|
| 1_task_review | iris | solo |
| 2_execution | iris | solo |
| 3_completion | iris | solo |

<!-- VF:END workflow -->

## Issue Labels

### Type Labels
- `type:dev` — Standard workflow
- `type:patch` — Patch Loop
- `type:spike` — 探索・調査
- `type:ops` — 非開発タスク

### Risk Labels
- `risk:low` — ドキュメント、テスト、軽微修正
- `risk:medium` — 機能追加、リファクタリング
- `risk:high` — 破壊的変更、セキュリティ

### QA Labels
- `qa:auto` — 自動テストで完全検証可能。auto-close 対象
- `qa:manual` — 人間の手動確認が必要（UI、CLI など）

## 3-Tier Context Management

### Tier 1: `.vibe/context/` — Always Loaded
- **STATUS.md** — プロジェクトの現状（Iris が自動更新）

### Tier 2: `.vibe/references/` — Hot Reference
- 議論メモ、リサーチ結果、フィードバック

### Tier 3: `.vibe/archive/` — Archived Info
- 命名規則: `YYYY-MM-DD-type-topic.md`

## Safety Rules

詳細は `rules/safety.md`。

1. **UI/CSS 変更**: atomic commit + スクリーンショット確認
2. **破壊的操作**: 実行前にユーザー確認必須
3. **修正再試行**: 最大 3 回、失敗したらアプローチ変更
4. **Hook 変更**: 承認後のみ
5. **plans/ 書き込み禁止**: `plan.md` に記載

## Available Commands

- `/conclude` — 会話をまとめ、Plan/Spec/STATUS.md を更新
- `/patch <issue番号>` — Patch Loop 開始
- `/progress` — 進捗確認
- `/healthcheck` — 整合性チェック
- `/run-e2e` — Playwright E2E テスト実行

## Hooks

<!-- VF:BEGIN hook_list -->
The framework uses Claude Code hooks for automatic safety and notification:

- **PreToolUse** (`validate_access.py`): Access control that blocks unauthorized file edits based on current role. Exit code 2 blocks the tool call.
- **PreToolUse** (`validate_write.sh`): Write guard that blocks writes to `plans/` directory.
- **PreToolUse** (`validate_step7a.py`): Step 7a guard that blocks `gh pr create` until QA checkpoint is approved.
- **PostToolUse** (`task_complete.sh`): Plays notification sound on Edit/Write/MultiEdit/TodoWrite completion.
- **Stop** (`waiting_input.sh`): Plays notification sound when waiting for user input.

Configuration: `.claude/settings.json`
<!-- VF:END hook_list -->

## Skills

- `vibeflow-kickoff` — Vision/Spec/Plan キックオフ生成
- `vibeflow-conclude` — セッション終了・Plan/Spec 更新
- `vibeflow-progress` — 進捗確認
- `vibeflow-healthcheck` — 整合性チェック
- `vibeflow-issue-template` — Issue テンプレート
- `vibeflow-tdd` — TDD Red-Green-Refactor
- `vibeflow-ui-smoke` — Playwright smoke test
- `vibeflow-ui-explore` — Playwright 探索

## Subagents

- `qa-acceptance` — QA レポート生成
- `code-reviewer` — Read-only コードレビュー
- `test-runner` — テスト並列実行

## Critical Rules

1. **TDD**: テストを先に書く (Red-Green-Refactor)
2. **Issue 駆動**: すべての作業は GitHub Issue に紐づける
3. **Permission**: ロールベースのファイルアクセス権限を厳守
4. **State 更新**: 各ステップ後に state を更新
5. **Incremental**: 小さな単位で継続的にデリバリー
