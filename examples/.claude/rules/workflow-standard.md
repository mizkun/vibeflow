# Standard Workflow — 11 Steps

v5 では Iris が自動的にワークフローを進行します。ユーザーは Iris に指示するだけです。

## Steps

| Step | Description | Agent |
|------|------------|-------|
| 1. Issue Review | Issue の内容確認・要件整理・UI task 判定 | Iris |
| 2. Task Breakdown | タスク分解・計画策定 | Iris |
| 3. Branch Creation | feature branch 作成 | Coding Agent |
| 4. Test Writing | TDD: テスト先行で作成（UI task は Playwright E2E も） | Coding Agent |
| 5. Implementation | テストをパスする実装 | Coding Agent |
| 6. Refactoring | コード品質の改善 | Coding Agent |
| 7. Acceptance Test | テスト実行・結果検証（UI task は Playwright 必須） | Iris (QA) |
| 7a. Human Checkpoint | 必要な場合のみ人間確認 | Human |
| 8. PR Creation | Pull Request 作成 | Coding Agent |
| 9. Cross-Review | 別 agent によるコードレビュー | Review Agent |
| 10. Merge | PR マージ | Iris |
| 11. Close | Issue クローズ・状態更新 | Iris |

## Step 1: UI Task 判定

Iris は Issue Review 時に以下を判定する:

1. **UI task か否か**: 変更対象に UI ファイルが含まれるか、Issue に UI キーワードがあるか
2. UI task と判定した場合:
   - `qa:manual` ラベルを付与（原則）
   - Step 4 で Playwright テスト作成を必須化
   - Step 7 で Playwright 実行を必須化

判定基準の詳細は `rules/playwright.md` を参照。

## Step 7: Acceptance Test

### 非 UI task
- ユニットテスト + インテグレーションテスト全 PASS を確認

### UI task（Playwright 必須）
1. `bash scripts/playwright_smoke.sh` で E2E テスト実行
2. 必須 artifact の存在を確認（Playwright test / trace / screenshot / exploratory log のうち 1 つ以上）
3. E2E テスト FAIL → verdict は `fail`、coding agent に修正を再 dispatch

## Step 7a 判断基準

### 人間チェック不要 (auto_pass)
- 全テスト PASS + クロスレビュー PASS
- diff が小さい (files ≤ 5, lines ≤ 200)
- `type:fix` or `type:chore` + `risk:low`
- **UI task ではない**

### 人間チェック必要 (needs_human)
- **UI task**（UI 変更は原則 needs_human）
- `risk:high`
- `qa:manual`
- セキュリティ関連
- 3 回目のリトライ

## TDD Enforcement

Step 4→5→6 は必ず TDD (Red-Green-Refactor) で実行:
1. テストを先に書く (Red)（UI task は Playwright E2E テストも含む）
2. テストをパスする実装 (Green)
3. リファクタリング (Refactor)
