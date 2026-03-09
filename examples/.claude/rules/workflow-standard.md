# Standard Workflow — 11 Steps

v5 では Iris が自動的にワークフローを進行します。ユーザーは Iris に指示するだけです。

## Steps

| Step | Description | Agent |
|------|------------|-------|
| 1. Issue Review | Issue の内容確認・要件整理 | Iris |
| 2. Task Breakdown | タスク分解・計画策定 | Iris |
| 3. Branch Creation | feature branch 作成 | Coding Agent |
| 4. Test Writing | TDD: テスト先行で作成 | Coding Agent |
| 5. Implementation | テストをパスする実装 | Coding Agent |
| 6. Refactoring | コード品質の改善 | Coding Agent |
| 7. Acceptance Test | テスト実行・結果検証 | Iris (QA) |
| 7a. Human Checkpoint | 必要な場合のみ人間確認 | Human |
| 8. PR Creation | Pull Request 作成 | Coding Agent |
| 9. Cross-Review | 別 agent によるコードレビュー | Review Agent |
| 10. Merge | PR マージ | Iris |
| 11. Close | Issue クローズ・状態更新 | Iris |

## Step 7a 判断基準

### 人間チェック不要 (auto_pass)
- 全テスト PASS + クロスレビュー PASS
- diff が小さい (files ≤ 5, lines ≤ 200)
- `type:fix` or `type:chore` + `risk:low`

### 人間チェック必要 (needs_human)
- UI/CLI の見た目変更
- `risk:high`
- `qa:manual`
- セキュリティ関連
- 3 回目のリトライ

## TDD Enforcement

Step 4→5→6 は必ず TDD (Red-Green-Refactor) で実行:
1. テストを先に書く (Red)
2. テストをパスする実装 (Green)
3. リファクタリング (Refactor)
