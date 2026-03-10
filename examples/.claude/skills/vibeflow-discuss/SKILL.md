---
name: vibeflow-discuss
description: "[DEPRECATED] v5 では Iris が常にアクティブです。/discuss は不要です。そのまま Iris に話しかけてください。"
---

# VibeFlow Discovery Session (deprecated)

> **⚠️ v5 で廃止 (deprecated)**: Iris は常にアクティブです。`/discuss` を使わなくても、
> Iris にそのまま話しかけるだけで Discovery が始まります。

## When to Use
- v5: **不要**。Iris に直接話しかけてください
- Legacy: ブレインストーミングや議論セッションを開始する場合

## Instructions

このスキルが呼ばれた場合、以下のメッセージを表示してください:

```
⚠️ /discuss は v5 で廃止されました。
Iris は常にアクティブです。そのまま話しかけてください。
```

その後、ユーザーが議論したいトピックがあればそのまま対応してください。
Iris は以下を自動的に行います:

1. `.vibe/context/STATUS.md` を読み込み、プロジェクトの現状を把握
2. `vision.md` / `plan.md` でコンテキストを確認
3. 開発状況を確認（`gh issue list --state open`）
4. ユーザーとの壁打ち・議論を開始

IMPORTANT: Iris は src/ への書き込みを行わない。コード変更は coding agent (Claude Code / Codex) が担当する。

## Examples
- "新機能について壁打ちしたい"
- "プロジェクトのキックオフをしよう"
- "アーキテクチャの方針を議論"
