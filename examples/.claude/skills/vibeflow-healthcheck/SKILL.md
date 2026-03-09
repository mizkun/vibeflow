---
name: vibeflow-healthcheck
description: Verify VibeFlow project repository consistency. Use when checking project structure, required files, and integration health.
---

# VibeFlow Healthcheck

## When to Use
- When verifying project setup is correct
- When troubleshooting configuration issues
- When onboarding to an existing project
- After running setup or upgrade

## Instructions

VibeFlow プロジェクトの整合性を検証します。

### Checks to Perform

#### 1. ディレクトリ構造
- .vibe/context/ が存在するか
- .vibe/references/ が存在するか
- .vibe/archive/ が存在するか
- .vibe/context/STATUS.md が存在するか
- .github/ISSUE_TEMPLATE/ が存在するか

#### 2. 必須ファイル
- vision.md, spec.md, plan.md が存在するか
- .vibe/project_state.yaml が有効なYAMLか
- .vibe/sessions/iris-main.yaml が存在し有効か
- .vibe/policy.yaml が存在するか

#### 3. State ファイル整合性
- `.vibe/project_state.yaml` を読み込み
  - `current_phase` が `development` | `discovery` のいずれかか
  - `active_issue` が null または有効な Issue 番号か
- `.vibe/sessions/iris-main.yaml` を読み込み
  - `current_role` が有効なロール名か
  - `kind` が `iris` か

> **Note**: `.vibe/state.yaml` が存在する場合は旧形式。正本は `project_state.yaml` + `sessions/*.yaml` です。

#### 4. GitHub Issues 連携
- `gh` CLI が利用可能か
- GitHub リポジトリとの接続確認
- Issue テンプレートが配置されているか

#### 5. Hook 設定
- .claude/settings.json が存在するか
- validate_access.py が存在し実行可能か

#### 6. ロール定義
- .vibe/roles/iris.md が存在するか（v3必須）
- 旧 discussion-partner.md が残っていないか

#### 7. Skills 確認
- .claude/skills/ ディレクトリが存在するか
- 必須 skills が配置されているか

### Output Format
各チェック項目について pass / warning / failure を表示。
日本語で表示し、修正手順を含めてください。

## Examples
- "プロジェクトの整合性をチェック"
- "/healthcheck"
