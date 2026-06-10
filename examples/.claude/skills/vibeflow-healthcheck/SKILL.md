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
- vision.md, plan.md が存在するか / .vibe/spec/ に構造化 spec があるか
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

#### 7b. Run Ledger 確認（ループの監査）
- `.vibe/runs/<date>.jsonl`（run ledger）の直近サマリを表示する
  （`run_ledger.summarize` — 直近 run の attempts / escalation / verdict 別件数）
- **closed Issue に台帳エントリがない場合は warning**
  （`run_ledger.closed_issues_without_entries`）。夜間・長時間ループの
  結果を PO が事後検証できるよう、各 Issue は台帳に記録されているべき

#### 8. 構造化 spec とコードの整合性（v6 — 日常検証の核）
- `vibeflow spec-verify --run-tests` を実行する
  （PATH に無ければ `python3 .vibe/runtime/spec_verify.py .vibe/spec . --run-tests`）
- **ERRORS が 1 件でもあれば failure**。spec がコードから drift している
  （source_files / producers / consumers / test / source_ref の参照先が消えた、
  story 参照が壊れた、必須フィールド欠落 等）。修正手順とともに表示する。
- **invariant の 3 状態を実数で表示する**: `verified / violated / pending`
  - **violated が 1 件でもあれば failure** — 既存の保証が破られている。
    該当 invariant（story/id・test パス）を表示し、修正 Issue を提案する
  - error（test パスがランナーに収集されない等）も failure として表示する
  - pending はテスト未整備の不変条件。後続 Issue で test を付けて verified に
    押し上げる対象。数の推移を毎回見える化する
- WARNINGS（schema_ref 未解決など）も表示する。

##### Spec Health の記録（STATUS.md）

spec-verify の結果を `.vibe/context/STATUS.md` の「## Spec Health」
セクションに **1 行追記**する:

```
- <YYYY-MM-DD>: errors=N warnings=N verified=N violated=N pending=N/total
```

セクションは**直近 10 行のみ保持**し、古い行は削除する（STATUS.md は
Tier-1 常時ロードのため無制限に追記しない）。

##### invariant 補強 Issue の提案

以下のいずれかに該当したら、Iris は **「invariant 補強 Issue」の作成を
PO に提案する**（対象 Story・pending invariant 一覧（`stats.pending_invariants`）・
追加すべき test を本文に含める。Issue 化は vibeflow-issue-template で行う）:

- (a) pending 比率が前回記録より増加した
- (b) pending 比率が 30% を超えたまま前回から減少していない
- (c) 同一 WARNING が 2 回連続で出ている

補強 Issue の「## Spec 変更」欄は「invariant への test フィールド追加
（pending → verified 昇格、To-Be = As-Is + test パス）」と明記する
（バグ分類 (iii) とは別物 — (iii) は invariant 未記録のケース）。

### Output Format
各チェック項目について pass / warning / failure を表示。
日本語で表示し、修正手順を含めてください。

## Examples
- "プロジェクトの整合性をチェック"
- "/healthcheck"
