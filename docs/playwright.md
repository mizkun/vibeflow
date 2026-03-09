# Playwright Integration

VibeFlow における Playwright E2E テストと MCP 連携のガイド。

## セットアップ

### 1. Playwright のインストール

```bash
npm init playwright@latest
npx playwright install
```

### 2. MCP 設定

`.mcp.json.example` をコピーして `.mcp.json` を作成:

```bash
cp .mcp.json.example .mcp.json
```

必要に応じて値を編集:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@anthropic-ai/mcp-playwright"],
      "env": {
        "PLAYWRIGHT_BASE_URL": "http://localhost:3000",
        "PLAYWRIGHT_HEADLESS": "true"
      }
    }
  }
}
```

- `PLAYWRIGHT_BASE_URL`: アプリケーションの URL
- `PLAYWRIGHT_HEADLESS`: `true` でヘッドレス、`false` でブラウザ表示

### 3. Playwright 設定

`playwright.config.js` がプロジェクトルートに配置されていることを確認。
テンプレートは `examples/playwright.config.js` を参照。

## スクリプト

### playwright_smoke.sh — Smoke テスト

最低限の UI ヘルスチェック:

```bash
# 基本実行
bash scripts/playwright_smoke.sh

# Headed mode
bash scripts/playwright_smoke.sh --headed

# 特定プロジェクト
bash scripts/playwright_smoke.sh --project firefox
```

### playwright_open_report.sh — レポート表示

テスト結果の HTML レポートを開く:

```bash
bash scripts/playwright_open_report.sh
```

### playwright_trace_pack.sh — Artifact アーカイブ

trace / screenshot / report をまとめて `.vibe/artifacts/` に保存:

```bash
# デフォルト出力先: .vibe/artifacts/pw-<timestamp>.tar.gz
bash scripts/playwright_trace_pack.sh

# カスタム出力先
bash scripts/playwright_trace_pack.sh --output path/to/archive.tar.gz
```

収集対象:
- `test-results/` — trace ファイル、スクリーンショット、動画
- `playwright-report/` — HTML レポート

## UI Skills

| Skill | 用途 |
|-------|------|
| `vibeflow-ui-smoke` | Playwright smoke テスト実行 |
| `vibeflow-ui-explore` | 探索的 UI 検証 (Playwright MCP) |

## UI Issue の品質ゲート (Quality Gate)

UI を含む Issue は、以下のうち**少なくとも 1 つ**を artifact として残すこと:

| Artifact | 説明 | 推奨ラベル |
|----------|------|-----------|
| Playwright test | `tests/e2e/` の自動テスト通過 | `qa:auto` |
| Trace artifact | `.vibe/artifacts/` の trace ファイル | どちらでも |
| Screenshot | 変更前後のスクリーンショット | `qa:manual` |
| Exploratory log | 手動検証の記録 | `qa:manual` |

### ラベルとの対応
- **`qa:auto`**: Playwright test のみで可。自動テストで完全検証可能
- **`qa:manual`**: screenshot または exploratory log を推奨。人間の確認が必要

## 3 層モデル

### Layer 1: 通常の Playwright Test
リポジトリにコミットされる正式な E2E テスト (`tests/e2e/`)。
CI で自動実行され、regression を検出。

### Layer 2: Playwright MCP による探索的検証
Claude / Iris がブラウザを直接触って確認する層。
- Step 7 の受入確認
- Patch Loop の UI 確認
- バグ再現
- 動線確認

### Layer 3: codegen によるテスト生成補助
`npx playwright codegen` で初期テストを生成し、手動で整える。
生成コードをそのまま本番利用せず、review worker がレビュー。

## ベストプラクティス

- 実装詳細よりユーザー可視挙動をテストする
- locator は role / text / test id 優先
- fragile な CSS セレクタ依存を避ける
- codegen は初期たたき台として使い、最終版は手直しする
- trace は `--trace on` で有効化: `npx playwright test --trace on`

## Artifact の保存先

| 種類 | パス |
|------|------|
| テスト結果 | `test-results/` |
| HTML レポート | `playwright-report/` |
| パックされた artifact | `.vibe/artifacts/pw-*.tar.gz` |
| スクリーンショット | `test-results/` 内、または手動で `.vibe/artifacts/` |
