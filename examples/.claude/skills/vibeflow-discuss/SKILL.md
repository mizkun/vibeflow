---
name: vibeflow-discuss
description: Start Discovery (Spike workflow) via Iris. Use when brainstorming, exploring ideas, or starting a discussion session.
---

# VibeFlow Discovery Session

## When to Use
- When starting a new brainstorming or discussion session
- When exploring ideas before implementation
- When doing project kickoff
- When reviewing and updating project direction

## Instructions

IMPORTANT: このスキルはトピックの有無に関わらず、必ず Discovery セッションを開始すること。使い方の案内を表示して終了してはならない。
IMPORTANT: Discovery は Iris の機能の一つ。「特殊モード」ではなく、Iris が実行する Spike workflow です。

### 処理フロー

#### 1. 状態確認
`.vibe/project_state.yaml` を読み込み、現在の `current_phase` を確認する。
`.vibe/sessions/iris-main.yaml` を読み込み、Iris セッションの状態を確認する。

> **Note**: `.vibe/state.yaml` が存在する場合は旧形式の fallback として参照してもよいが、正本は `project_state.yaml` + `sessions/*.yaml` です。

#### 2. コンテキスト読み込み
1. `.vibe/context/STATUS.md` を読み込み、プロジェクトの現状を把握
2. `vision.md` でプロダクトビジョンを確認
3. `plan.md` でロードマップを確認
4. 開発状況を確認（`gh issue list --state open`）

#### 3. セッション開始
1. **Phase 切り替え**: `.vibe/project_state.yaml` の `current_phase: discovery` に更新
2. **Role 確認**: `.vibe/sessions/iris-main.yaml` の `current_role: "Iris"` を確認（通常は変更不要）
3. **バナー表示**:
   ```
   ========================================
   Iris MODE
   [トピックがあれば表示]
   Current Focus: [STATUS.md から]
   Dev Status: [active_issue の状況]
   ========================================
   ```

#### 4. トピック決定

以下の優先順位でトピックを決定する:

1. **引数でトピックが指定されている場合** → そのトピックで議論を開始
2. **プロジェクトが初期状態の場合**（vision.md がプレースホルダーのみ、GitHub Issues がゼロ）→ 「プロジェクトキックオフ」として以下を Iris が主導:
   - 「このプロジェクトで何を作りたいですか？」とユーザーに問いかける
   - ユーザーのアイデアに対して深掘り質問を行い、vision.md / spec.md の叩き台を一緒に作る方向で議論を進める
3. **既存コンテキストがある場合** → STATUS.md の Current Focus や open Issues から議論すべきトピックを提案する

#### 5. セッション中の活動
- 壁打ち・議論
- GitHub Issue の作成・更新（`gh issue create`）
- 外部情報の取り込み（references/ に保存）
- plan.md / vision.md / spec.md の更新
- STATUS.md の更新

IMPORTANT: Iris は src/ への書き込みを行わない。コード変更は開発ターミナルの Engineer が担当する。

## State 更新の対象

| ファイル | フィールド | 値 |
|---------|-----------|-----|
| `.vibe/project_state.yaml` | `current_phase` | `discovery` |
| `.vibe/sessions/iris-main.yaml` | `current_role` | `Iris`（確認のみ） |
| `.vibe/sessions/iris-main.yaml` | `status` | `active` |

## Examples
- "新機能について壁打ちしたい"
- "プロジェクトのキックオフをしよう"
- "/discuss アーキテクチャの方針を議論"
