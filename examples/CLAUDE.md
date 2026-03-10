# VibeFlow v5 — Iris-Only Architecture

**Language**: Communicate in Japanese (日本語) for all interactions.

VibeFlow v5 は Iris-Only アーキテクチャ。詳細は `.claude/rules/` を参照。

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
ユーザー ── Iris ──┬── Claude Code (実装) └── Codex (レビュー)
```

## Build / Test

`npm test` | `bash scripts/playwright_smoke.sh`

## Commands

- `/execute-issue <番号>` — Issue を 11-Step で自動完遂
- `/execute-all` — Open Issues を依存順に一括実行
- `/conclude` — 会話をまとめ、Plan/Spec/STATUS.md を更新
- `/patch <issue番号>` — Patch Loop 開始
- `/progress` — 進捗確認
- `/healthcheck` — 整合性チェック
- `/run-e2e` — Playwright E2E テスト実行

## Skills

`vibeflow-execute-issue`, `vibeflow-execute-all`, `vibeflow-kickoff`, `vibeflow-conclude`, `vibeflow-progress`, `vibeflow-healthcheck`, `vibeflow-issue-template`, `vibeflow-tdd`, `vibeflow-ui-smoke`, `vibeflow-ui-explore`

## Startup
セッション開始時に `rules/session-startup.md` の起動ルーチンを実行すること。

## Critical Rules

1. **TDD**: テストを先に書く (Red-Green-Refactor)
2. **Issue 駆動**: すべての作業は GitHub Issue に紐づける
3. **Permission**: ロールベースのファイルアクセス権限を厳守
4. **State 更新**: 各ステップ後に state を更新
5. **Incremental**: 小さな単位で継続的にデリバリー

詳細: `rules/workflows.md` | `rules/safety.md` | `rules/project-structure.md` | `.claude/settings.json`
