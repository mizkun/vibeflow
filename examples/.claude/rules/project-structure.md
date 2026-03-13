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

**`qa:auto` の条件（全て満たすこと）:**
- 変更が外部から観測不能（UI・セッションフロー・CLI 出力に影響なし）
- 自動テストで AC を完全に検証可能
- 内部リファクタ、型変更、バグ修正（振る舞い変更なし）

**`qa:manual` を強制する条件（1 つでも該当すれば manual）:**
- セッションフロー（フェーズ順序・遷移）の変更
- UI コンポーネントの追加・変更
- ユーザーに見える振る舞いの変更
- 新しい画面・ステップの追加

**迷ったら `qa:manual`。**

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
