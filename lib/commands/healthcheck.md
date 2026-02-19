# プロジェクト整合性チェック

VibeFlow プロジェクトの整合性を検証します。

## Checks to Perform:

1. **ディレクトリ構造**
   - .vibe/context/ が存在するか
   - .vibe/references/ が存在するか
   - .vibe/archive/ が存在するか
   - .vibe/context/STATUS.md が存在するか
   - .github/ISSUE_TEMPLATE/ が存在するか

2. **必須ファイル**
   - vision.md, spec.md, plan.md が存在するか
   - .vibe/state.yaml が有効なYAMLか
   - .vibe/policy.yaml が存在するか

3. **State ファイル整合性**
   - .vibe/state.yaml を読み込み
   - current_role が有効なロール名か
   - phase が development または discovery か

4. **GitHub Issues 連携**
   - `gh` CLI が利用可能か
   - GitHub リポジトリとの接続確認
   - Issue テンプレートが配置されているか

5. **Hook 設定**
   - .claude/settings.json が存在するか
   - validate_access.py が存在し実行可能か

6. **ロール定義**
   - .vibe/roles/project-partner.md が存在するか（v3必須）
   - 旧 discussion-partner.md が残っていないか

## Output Format:
✅ passing checks / ⚠️ warnings / ❌ failures
日本語で表示し、修正手順を含めてください。
