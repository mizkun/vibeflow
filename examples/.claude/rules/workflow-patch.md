# Patch Loop Workflow

QA フィードバック・レビュー指摘など、親 Issue に紐づく軽微修正のための 4 Step ワークフロー。

## Steps

| Step | Description |
|------|------------|
| 1. Scope Review | 対象ファイル・テストの確認 + UI 判定 |
| 2. Fix Implementation | 限定スコープで修正 |
| 3. Targeted Test | 対象テストのみ再実行（UI 変更時は Playwright も） |
| 4. Commit | 修正をコミット |

## Step 1: UI 判定

Scope Review 時に、対象ファイルに UI ファイル (`.tsx`, `.vue`, `.svelte`, `.html`, `.css` 等) が含まれるかを確認する。
UI ファイルが含まれる場合、Step 3 で Playwright smoke テストの実行が**必須**となる。

## Step 3: UI 変更時の Playwright

対象に UI ファイルが含まれる場合:
1. `bash scripts/playwright_smoke.sh` を実行
2. Playwright テスト全 PASS を確認
3. artifact を 1 つ以上残す（Playwright test / trace / screenshot / exploratory log）
4. FAIL の場合は Step 2 に戻って修正

## 制約

- 親 Issue / PR が必須
- 対象ファイル数に上限あり
- 大きな仕様変更は禁止（Standard Issue に昇格）
- Safety Rules は適用
- **UI 変更を含む patch は Playwright 必須**
