# Project Structure

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

## Subagents

- `qa-acceptance` — QA レポート生成
- `code-reviewer` — Read-only コードレビュー
- `test-runner` — テスト並列実行
