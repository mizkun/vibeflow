---
description: Start Patch Loop (compatibility alias for /patch)
---

# /quickfix — /patch の互換 alias

IMPORTANT: `/quickfix` は `/patch` の互換 alias です。今後は `/patch <issue番号>` を使用してください。
IMPORTANT: 親 Issue 番号が必須です。引数なしで呼ばれた場合は、以下の手順を案内してください。

## 引数なしで呼ばれた場合

以下のメッセージを表示してください:

```
Patch Loop には親 Issue が必要です。

使い方:
  /patch <issue番号>    — 親 Issue に紐づく軽微修正を開始

Issue がまだない場合:
  1. gh issue create で Issue を作成してください
  2. type:patch と workflow:patch ラベルを付けてください
  3. /patch <issue番号> で Patch Loop を開始してください

詳細: /patch コマンドのヘルプを参照
```

## 引数ありで呼ばれた場合

`/patch <issue番号>` と同じ処理を実行してください。

1. 引数を親 Issue 番号として扱う
2. Patch Loop の Step 1 (Scope Review) から開始
3. 以降は /patch コマンドと同じフローに従う

## /patch との違い

- 機能的な違いはありません
- `/quickfix` は v3 との後方互換のために残されています
- 新規利用では `/patch` を推奨します
