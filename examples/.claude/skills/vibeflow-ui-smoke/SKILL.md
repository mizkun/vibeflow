---
name: vibeflow-ui-smoke
description: Run Playwright smoke tests for quick UI health check. Use after UI changes to verify basic functionality.
---

# VibeFlow UI Smoke Test

## When to Use
- After making UI changes (CSS, layout, components)
- Before creating a PR that includes UI modifications
- As a quick check during Step 7 (Acceptance Test)
- When verifying a bug fix that affects UI

## Instructions

### 1. 前提確認
- Node.js / npm がインストールされていること
- `playwright.config.js` (or `.ts`) がプロジェクトルートに存在すること
- Playwright ブラウザがインストール済みであること (`npx playwright install`)

### 2. Smoke テスト実行
```bash
# 基本実行
bash scripts/playwright_smoke.sh

# Headed mode (ブラウザを表示)
bash scripts/playwright_smoke.sh --headed

# 特定のプロジェクト
bash scripts/playwright_smoke.sh --project firefox
```

### 3. 結果の確認
- テスト成功: 次のステップへ進む
- テスト失敗:
  1. `npx playwright show-report` でレポートを確認
  2. 失敗したテストを修正
  3. 再度 smoke テストを実行

### 4. Artifact の保存
UI 変更を含む Issue では、以下の artifact のうち少なくとも 1 つを残すこと:

```bash
# trace + screenshot をまとめてアーカイブ
bash scripts/playwright_trace_pack.sh
```

## UI Issue の品質ゲート (Quality Gate)

UI を含む Issue は、以下のうち**少なくとも 1 つ**を artifact として残すこと:

1. **Playwright test**: 自動テストが通ること (`tests/e2e/`)
2. **Trace artifact**: Playwright trace ファイル (`.vibe/artifacts/`)
3. **Screenshot**: 変更前後のスクリーンショット
4. **Exploratory verification log**: 手動検証の記録

> `qa:auto` ラベルの Issue は Playwright test のみで可。
> `qa:manual` ラベルの Issue は screenshot または exploratory log を推奨。

## Examples
- "UI の smoke テストを実行して"
- "変更後のスクリーンショットを撮って"
