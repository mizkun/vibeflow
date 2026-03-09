---
name: vibeflow-ui-explore
description: Exploratory UI verification using Playwright MCP. Use when manually verifying UI behavior, reproducing bugs, or checking user flows.
---

# VibeFlow UI Exploratory Verification

## When to Use
- When verifying UI behavior during Step 7 (Acceptance Test)
- When reproducing a UI bug
- When checking user flows and navigation
- When performing exploratory testing on a new feature

## Instructions

### 1. MCP 設定確認
Playwright MCP が有効であることを確認:
- `.mcp.json` が存在し、`playwright` サーバーが設定されていること
- テンプレート: `.mcp.json.example` を参照

### 2. 探索的検証の実行

Playwright MCP を使って以下を実行:

#### ページの確認
1. 対象 URL にアクセス
2. ページのレンダリング状態を確認
3. 主要な要素が表示されていることを検証

#### ユーザーフローの検証
1. 想定されるユーザー操作を順次実行
2. 各操作後の状態を確認
3. エラーや不整合がないか検証

#### バグ再現
1. 報告されたバグの再現手順を実行
2. 修正後に同じ手順で問題が解消されたことを確認

### 3. 検証記録の作成

検証結果を記録する:
```
## Exploratory Verification Log
- Date: YYYY-MM-DD
- Issue: #N
- Verified URLs: [list]
- Steps performed: [list]
- Result: PASS / FAIL
- Notes: [observations]
```

### 4. Artifact の保存

検証中に以下の artifact を収集:
- Screenshot (変更前後)
- Trace ファイル (操作の記録)
- Console ログ (エラーがあれば)

```bash
# artifact をまとめてアーカイブ
bash scripts/playwright_trace_pack.sh
```

## UI Issue の品質ゲート (Quality Gate)

UI を含む Issue は、以下のうち**少なくとも 1 つ**を artifact として残すこと:

1. **Playwright test**: 自動テストが通ること (`tests/e2e/`)
2. **Trace artifact**: Playwright trace ファイル (`.vibe/artifacts/`)
3. **Screenshot**: 変更前後のスクリーンショット
4. **Exploratory verification log**: 手動検証の記録

> 探索的検証は特に `qa:manual` ラベルの Issue で推奨されます。

## Playwright MCP のポリシー
- **Isolated session を基本とする**: 既存ブラウザセッションは使わない
- **Staging / local を優先**: 本番環境ではなく開発環境で検証
- **Storage state**: ログインが必要な場合は storage state を利用

## Examples
- "ログインフローを検証して"
- "変更した画面のスクリーンショットを撮って"
- "バグ #42 の再現手順を実行して"
