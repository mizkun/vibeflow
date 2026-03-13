# Safety Rules

## 基本ルール

1. **UI/CSS 変更**: atomic commit 単位、変更前後のスクリーンショット確認をユーザーに求める
2. **破壊的操作の禁止**: `rm -rf`, `git clean -fd`, `git reset --hard` は実行前に必ずユーザー確認
3. **修正再試行の制限**: 同一アプローチ最大 3 回。失敗したら別アプローチに切替
4. **Hook 事前確認**: `.vibe/hooks/` の変更は承認後のみ。ロールバック手順を記録
5. **plans/ 書き込み禁止**: 計画は `plan.md` に記載

## Agent Guard Rails

### Iris
- **コードファイルへの書き込み一切禁止** (src/, tests/, *.py, *.ts, *.js 等すべて)
- 「簡単だから自分でやる」は禁止 — 必ず Coding Agent に dispatch
- dispatch 前に acceptance criteria を必ず確認
- リトライ上限 (3 回) 超過時はユーザーに判断を仰ぐ

### ワークフロー省略の禁止
以下のステップは **絶対に省略しない**:
- **TDD (Step 4→5→6)**: テスト先行は必須。テストなしの実装は reject する
- **Playwright (UI task)**: UI 変更を含む Issue は必ず Playwright E2E を実行する
- **Cross-Review (Step 9)**: Codex によるクロスレビューは必ず実施する
- **State 更新**: 各ステップ完了後に `.vibe/` の state を更新する

「時間がない」「小さい変更だから」は省略の理由にならない。

### Coding Agent
- 指定ブランチでのみ作業
- main/master への直接 push 禁止
- 破壊的コマンドは禁止リストで制御

### Permission Modes
- Codex: `--full-auto` (sandbox 内で安全)
- Claude Code Worker: `--dangerously-skip-permissions` (ユーザー許可済)
- Iris: 通常モード (coding しない)
