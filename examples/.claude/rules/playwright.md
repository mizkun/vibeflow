# Playwright E2E Testing Rules

## 原則: UI を含む Issue は Playwright 必須

UI に関連する Issue（画面変更、コンポーネント追加、スタイル変更など）では、Playwright の実行が**必須**です。
これは Standard Workflow、Patch Loop のいずれにも適用されます。

## UI Task の判定基準

以下のいずれかに該当する場合、Iris はその Issue を **UI task** と判定します:

1. **変更対象ファイル**: `.tsx`, `.jsx`, `.vue`, `.svelte`, `.html`, `.css`, `.scss`, `.less` を含む
2. **Issue タイトル/本文のキーワード**: 画面、表示、UI、デザイン、レイアウト、コンポーネント、ボタン、フォーム、モーダル、ダッシュボード、レスポンシブ、アニメーション
3. **Acceptance criteria に UI 関連の記述**: 「見た目」「表示される」「画面に」など

## UI Task のラベル付け

- UI task は原則 `qa:manual` を付与する
- 純粋にテストで検証可能な UI 変更（既存コンポーネントの内部ロジック変更など）のみ `qa:auto` を許可

## 必須 Artifact

UI task では、以下のうち **少なくとも 1 つ** を artifact として残すこと:

| Artifact | 説明 | 推奨ケース |
|----------|------|-----------|
| Playwright test | 自動 E2E テスト (`tests/e2e/`) | 繰り返し検証が必要な場合 |
| Trace | Playwright trace ファイル (`.vibe/artifacts/`) | 操作手順の記録 |
| Screenshot | 変更前後のスクリーンショット | ビジュアルの差分確認 |
| Exploratory log | 手動検証の記録 | 複雑な UI フロー |

## Workflow への組み込み

### Standard Workflow (11 Steps)

- **Step 4 (Test Writing)**: UI task の場合、Playwright E2E テストも作成する
- **Step 7 (Acceptance Test)**: UI task の場合、以下を実行:
  1. `bash scripts/playwright_smoke.sh` で E2E テスト実行
  2. artifact の存在を確認（上記 4 種のうち 1 つ以上）
  3. E2E テストが 1 つでも FAIL → verdict は `fail`
- **Step 7a (Human Checkpoint)**: UI task は原則 `needs_human` → スクリーンショットをユーザーに提示

### Patch Loop (4 Steps)

- **Step 1 (Scope Review)**: 対象ファイルに UI ファイルが含まれるか確認
- **Step 3 (Targeted Test)**: UI ファイルが含まれる場合、Playwright smoke テストも実行
- UI 変更を含む patch は、commit 前に artifact を 1 つ以上残す

## Quality Gate

- **Playwright テスト全 PASS** が PR マージの前提条件
- テスト FAIL → coding agent に修正を再 dispatch
- スクリーンショットの差分がある場合 → 人間チェックを要求

## How to Run

```bash
# Smoke テスト
bash scripts/playwright_smoke.sh

# Trace + screenshot のアーカイブ
bash scripts/playwright_trace_pack.sh

# レポート表示
bash scripts/playwright_open_report.sh
```
