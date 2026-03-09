# VibeFlow v5 — Iris-Only Architecture

**Language**: Communicate in Japanese (日本語) for all interactions.

## Overview

VibeFlow v5 は Iris-Only アーキテクチャです。ユーザーは Iris とだけ会話します。
Iris が Issue 作成 → coding agent 選択 → dispatch → 結果収集 → QA 判断 → クローズ を一貫して行います。

詳細なルールは `.claude/rules/` を参照してください。

## Role Definitions

<!-- VF:BEGIN roles -->
### Iris
**Description**: プロジェクトの唯一のインターフェース — 計画、dispatch、QA判断、クローズ
**Enforcement**: hard
**Can Write**: `vision.md`, `spec.md`, `plan.md`, `.vibe/**`, GitHub Issues

### Coding Agent (Codex / Claude Code)
**Description**: コーディング、テスト、リファクタリング
**Enforcement**: hard
**Can Write**: `src/*`, `tests/*`, `**/*.test.*`, `**/__tests__/*`

<!-- VF:END roles -->

## Architecture

```
ユーザー ── Iris (単一ターミナル) ──┬── Codex (default)
                                    └── Claude Code (fallback)
```

### Agent Selection
- **Default**: Codex (sandbox 実行、非同期)
- **Claude Code**: MCP 連携、Playwright、ローカル FS アクセス、Codex 2回失敗時

### Cross-Review
コーディングしなかった方の agent がレビューする。

## Workflow

<!-- VF:BEGIN workflow -->
### Standard Workflow (11 Steps)
Iris が自動進行。詳細は `rules/workflow-standard.md`。

| Step | Description | Who |
|------|------------|-----|
| 1-2 | Issue Review + Task Breakdown | Iris |
| 3-6 | Branch + TDD (Test→Impl→Refactor) | Coding Agent |
| 7-7a | Acceptance Test + Human Checkpoint | Iris / Human |
| 8 | PR Creation | Coding Agent |
| 9 | Cross-Review | Other Agent |
| 10-11 | Merge + Close | Iris |

### Patch Workflow (4 Steps)
詳細は `rules/workflow-patch.md`。

| Step | Description |
|------|------------|
| 1 | Scope Review |
| 2 | Fix Implementation |
| 3 | Targeted Test |
| 4 | Commit |

### Spike Workflow
| Step | Description |
|------|------------|
| 1 | Question Framing |
| 2 | Exploration |
| 3 | Decision Summary |

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
- **PreToolUse** (`validate_access.py`): ロールベースのアクセス制御
- **PreToolUse** (`validate_write.sh`): plans/ ディレクトリ書き込みブロック
- **PreToolUse** (`validate_step7a.py`): QA checkpoint ガード
- **PostToolUse** (`task_complete.sh`): 完了通知
- **Stop** (`waiting_input.sh`): 入力待ち通知
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
