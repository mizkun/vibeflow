## /next 実行時の事前チェック（v2 追加）

### Phase チェック
state.yaml の phase を確認する。
- phase が "discovery" の場合 → エラーを返す:
  「Discovery Phase が進行中です。/conclude で終了してから /next を使ってください。」
- phase が "development" の場合 → 以下の通常フローへ進む。

### Mode による実行分岐
current_step のワークフロー定義から mode を取得する。

#### mode: solo（従来通り）
メインエージェントが直接実行する。既存のロジックをそのまま使用。

#### mode: team（Agent Team）
1. CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 環境変数を確認
   - 未設定の場合 → mode: solo にフォールバックし、以下を通知:
     「Agent Team が無効です。solo モードで実行します。
      有効にするには: export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1」
2. ワークフロー定義の team_config に従い、チームメイトを spawn
3. consensus_required: true の場合、全チームメイトの合意を確認してから次 step へ

#### mode: fork（context: fork）
1. 該当 step の Skill を context: fork で実行
2. メインのコンテキスト（PM の議論内容）を引き継いだ状態で別エージェントに委譲
3. 完了後、結果サマリをメインに返す
4. context: fork が利用できない環境では mode: solo にフォールバック

### Safety ルールの自動適用
各 step 実行時に以下を自動チェック:
- 対象ファイルに CSS/HTML/TSX が含まれる場合 → state.yaml の safety.ui_mode を確認し、atomic なら 1 変更ずつ実行
- ファイル rename/move/delete が 2 つ以上ある場合 → git commit で checkpoint を自動作成
- 前回と同じアプローチでの修正が検出された場合 → safety.failed_approach_log を確認し、2 回以上なら別アプローチを強制

### Step 2.5 / Step 6.5 の自動挿入
- Step 2 完了後 → 自動的に Step 2.5（Infra: Hook Permission Setup）を実行
- Step 6 完了後 → 自動的に Step 6.5（Infra: Hook Rollback）を実行
- これらの step はユーザーが明示的に /next する必要はない（自動挿入）
