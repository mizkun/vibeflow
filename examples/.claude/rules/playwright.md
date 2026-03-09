# Playwright E2E Testing Rules

## UI Issue Requirement

UI に関連する Issue（画面変更、コンポーネント追加、スタイル変更など）では、Playwright E2E テストの作成・実行が**必須**です。

## When to Run

- `type:dev` かつ UI ファイル (`.tsx`, `.vue`, `.svelte`, `.html`, `.css`) を変更する場合
- `type:patch` かつ UI の見た目に影響する修正の場合
- Acceptance criteria に「画面」「表示」「UI」「デザイン」が含まれる場合

## How to Run

```bash
bash scripts/playwright_smoke.sh
```

## Quality Gate

- Playwright テスト全 PASS が PR マージの前提条件
- スクリーンショットの差分がある場合は人間チェックを要求
