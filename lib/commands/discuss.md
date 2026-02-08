---
description: Start or continue a discovery discussion
---

# Discovery Discussion（壁打ち）を開始する

`/discuss [トピック]` で新しい議論を開始、`/discuss --continue` で前回のセッションを継続します。

## 処理フロー

### 1. 状態確認
`.vibe/state.yaml` を読み込み、現在の phase を確認する。

### 2. 新規議論の場合（トピック指定あり）

1. **Phase 切り替え**: `phase: discovery` に更新
2. **DISC-ID 採番**: `.vibe/discussions/` 内の既存ファイルから最大番号を取得し +1
   - ファイルが存在しない場合は `DISC-001` から開始
3. **議論ファイル作成**: `.vibe/discussions/DISC-XXX-[topic-slug].md`
   - `.vibe/templates/discussion-template.md` のテンプレートを使用
   - トピック名、日付、IDを埋め込む
4. **State 更新**:
   ```yaml
   phase: discovery
   current_role: "Discussion Partner"
   discovery:
     id: "DISC-XXX"
     started: "YYYY-MM-DD"
     topic: "[トピック名]"
     sessions:
       - date: "YYYY-MM-DD"
         status: active
   ```
5. **ロール遷移バナー表示**:
   ```
   ========================================
   💬 DISCOVERY PHASE
   Topic: [トピック名]
   Discussion ID: DISC-XXX
   Now operating as: Discussion Partner
   ========================================
   ```
6. **壁打ち開始**: Discussion Partner として議論を開始

### 3. 継続の場合（--continue）

1. `discovery.id` から前回の議論ファイルを特定
2. 議論ファイルを読み込み、前回の内容をコンテキストとして復元
3. 新しいセッションエントリを追加
4. Discussion Partner として議論を再開

### 4. エラーケース
- トピックも `--continue` も指定されていない場合: 使い方を案内
- 既に discovery phase の場合（新規時）: 先に `/conclude` で終了するよう案内
- 継続する議論がない場合: 新規作成を案内

IMPORTANT: Discussion Partner ロールではファイル変更を行わない（discussions/ と state.yaml のみ例外）。コード生成・修正は一切行わず、議論のみに集中する。
