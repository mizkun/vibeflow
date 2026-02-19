---
description: Start a Iris session
---

# Iris セッションを開始する

`/discuss` でIrisセッションを開始し、`/discuss [トピック]` で特定のトピックについて議論します。

## 処理フロー

### 1. 状態確認
`.vibe/state.yaml` を読み込み、現在の phase を確認する。

### 2. コンテキスト読み込み
1. `.vibe/context/STATUS.md` を読み込み、プロジェクトの現状を把握
2. `plan.md` でロードマップを確認
3. 開発状況を確認（`gh issue list --state open`）

### 3. セッション開始
1. **Phase 切り替え**: `phase: discovery` に更新
2. **Role 切り替え**: `current_role: "Iris"` に更新
3. **Discovery 更新**: `discovery.active: true`
4. **バナー表示**:
   ```
   ========================================
   💬 Iris MODE
   [トピックがあれば表示]
   Current Focus: [STATUS.md から]
   Dev Status: [current_issue の状況]
   ========================================
   ```

### 4. セッション中の活動
- 壁打ち・議論
- GitHub Issue の作成・更新（`gh issue create`）
- 外部情報の取り込み（references/ に保存）
- plan.md / vision.md / spec.md の更新
- STATUS.md の更新

### 5. トピック未指定の場合
STATUS.md の Current Focus からトピックを提案する。

IMPORTANT: Iris は src/ への書き込みを行わない。コード変更は開発ターミナルの Engineer が担当する。
