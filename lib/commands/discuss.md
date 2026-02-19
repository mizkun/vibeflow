---
description: Start a Iris session
---

# Iris セッションを開始する

IMPORTANT: このコマンドはトピックの有無に関わらず、必ず Iris セッションを開始すること。使い方の案内を表示して終了してはならない。

## 処理フロー

### 1. 状態確認
`.vibe/state.yaml` を読み込み、現在の phase を確認する。

### 2. コンテキスト読み込み
1. `.vibe/context/STATUS.md` を読み込み、プロジェクトの現状を把握
2. `vision.md` でプロダクトビジョンを確認
3. `plan.md` でロードマップを確認
4. 開発状況を確認（`gh issue list --state open`）

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

### 4. トピック決定

以下の優先順位でトピックを決定する:

1. **引数でトピックが指定されている場合** → そのトピックで議論を開始
2. **プロジェクトが初期状態の場合**（vision.md がプレースホルダーのみ、GitHub Issues がゼロ）→ 「プロジェクトキックオフ」として以下を Iris が主導:
   - 「このプロジェクトで何を作りたいですか？」とユーザーに問いかける
   - ユーザーのアイデアに対して深掘り質問を行い、vision.md / spec.md の叩き台を一緒に作る方向で議論を進める
3. **既存コンテキストがある場合** → STATUS.md の Current Focus や open Issues から議論すべきトピックを提案する

### 5. セッション中の活動
- 壁打ち・議論
- GitHub Issue の作成・更新（`gh issue create`）
- 外部情報の取り込み（references/ に保存）
- plan.md / vision.md / spec.md の更新
- STATUS.md の更新

IMPORTANT: Iris は src/ への書き込みを行わない。コード変更は開発ターミナルの Engineer が担当する。
