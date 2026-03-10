# Session Startup Routine

セッション開始時、Iris は以下の起動ルーチンを実行する。

## 起動チェックリスト

1. **VibeFlow 整合性チェック**: `vibeflow doctor` を実行し、マニフェスト・スキーマの整合性を確認。warn/error があれば報告
2. **Git 状態確認**: `git status` で未コミットの変更を確認
3. **直近の作業把握**: `git log --oneline -10` で直近のコミットを確認
4. **中断状態の検出**: `.vibe/state.yaml` を読み、`current_step` が `idle` でない場合は前セッションが中断している
5. **テスト疎通**: テストを 1 回実行して壊れていないか確認
6. **STATUS.md 読み込み**: `.vibe/context/STATUS.md` でプロジェクトの現状を把握

## 中断検出時のリカバリ

| 中断時の state | リカバリ手順 |
|---------------|-------------|
| `3_branch_creation` ~ `6_refactoring` | テスト実行して状態確認。失敗していれば修正してから続行 |
| `7_acceptance_test` | QA 判定を再実行 |
| `8_pr_creation` ~ `9_code_review` | PR の状態を `gh pr list` で確認 |
| `10_merge` | PR がマージ済みか確認、未マージなら続行 |

## 未コミット変更の処理

- 変更内容を確認し、意図的な作業途中であればコミットを提案
- 不要な変更（デバッグ用コードなど）であれば stash を提案
- ユーザーに確認してから対処する（勝手に stash/reset しない）

## テスト疎通の実行

プロジェクトのテストランナーを自動検出して実行する:
- `package.json` の `test` スクリプト → `npm test`
- `pytest.ini` / `pyproject.toml` → `pytest`
- `Makefile` の `test` ターゲット → `make test`
- `tests/run_tests.sh` → `bash tests/run_tests.sh`

テストが失敗していた場合、ユーザーに報告し、修復してから他の作業を開始する。

## 注意事項

- 起動ルーチンは **毎セッション開始時** に実行する（スキップしない）
- 結果はユーザーに簡潔に報告する（問題がなければ 1-2 行で OK）
- 問題がある場合のみ詳細を表示する
