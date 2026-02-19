# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [3.0.0] - 2026-02-19

v2.0.0 からのメジャーアップグレード。GitHub Issues 統合、Project Partner ロール、マルチターミナル運用、3層コンテキスト管理を導入。ワークフローを大幅に簡素化。

### Added

#### GitHub Issues 統合
- タスク管理を GitHub Issues に一本化（ローカル `issues/` ディレクトリ廃止）
- Issue テンプレート 3 種: `type:dev`（開発）、`type:human`（人間タスク）、`type:discussion`（議論）
- ステータスラベル: `status:implementing`、`status:testing`、`status:pr-ready`
- 優先度ラベル: `priority:critical`、`priority:high`、`priority:medium`、`priority:low`
- `.github/ISSUE_TEMPLATE/` に Issue テンプレートを自動配置

#### Project Partner ロール（Discussion Partner の拡張）
- 壁打ち + 外部情報取り込み + タスク管理 + 意思決定記録 + コンテキスト管理
- `vision.md`、`spec.md`、`plan.md` の読み書き権限
- `gh issue` / `gh project` コマンドの実行権限
- `src/` への書き込みは不可（コード変更は Engineer 担当）

#### マルチターミナル運用
- Project Partner ターミナル x1（常駐）+ 開発ターミナル xN（Issue 単位）
- ターミナル間の情報共有: ファイルシステム + Git + GitHub Issues
- 書き込みスコープの明確な分離

#### 3 層コンテキスト管理
- `.vibe/context/`: 常時ロード（STATUS.md）
- `.vibe/references/`: ホットな参照情報（会議メモ、議論メモ）
- `.vibe/archive/`: アーカイブ（YAML front matter 必須、`YYYY-MM-DD-type-topic.md`）

#### Issues マイグレーションツール
- `.vibe/tools/migrate-issues.sh`: ローカル `issues/*.md` → GitHub Issues への変換
- `--dry-run` モード対応
- 完了済み Issue も含めてステータス保持

### Changed

#### ワークフロー簡素化
- 11 ステップ + 2 チェックポイント → Issue 駆動のシンプルなフロー
- ヒューマンチェックポイントを PR レビューのみに統合
- `/next` コマンド廃止（自然言語で進行）

#### state.yaml v3 スキーマ
- `current_step`、`current_cycle`、`checkpoint_status` 削除
- `issues_created` / `issues_completed` → `issues_recent` に簡素化
- `discovery` セクション簡素化: `active` / `last_session` のみ
- `current_issue`: GitHub Issue 番号形式 (`"#12"`)

#### コマンド更新
- `/discuss`: Project Partner セッション開始（トピック任意）
- `/conclude`: STATUS.md 更新 + 開発フェーズ復帰
- `/progress`: GitHub Issues 統合ビュー
- `/healthcheck`: v3 ディレクトリ構造チェック

#### ロール権限更新
- Product Manager: `issues/*` → `gh issue` コマンド
- Engineer: Issue 参照が `gh issue view` に変更
- QA Engineer: Issue 参照が `gh issue view` に変更
- Access Guard (`validate_access.py`): Project Partner 権限追加

### Removed
- `/next` コマンド（ステップ番号ベースのワークフロー廃止）
- `issues/` ディレクトリ（GitHub Issues に移行）
- Discussion Partner ロール（Project Partner に拡張統合）
- `discussions/` ディレクトリ（`references/` に統合、マイグレーション時にコピー）
- 11 ステップワークフロー定義
- `current_step`、`current_cycle` 等のステップ追跡

### Migration
- `vibeflow upgrade` で v2 → v3 自動マイグレーション
- `discussions/` → `references/` へのファイルコピー
- `discussion-partner.md` → `archive/` にアーカイブ
- `next.md` コマンド → `archive/` にアーカイブ
- `state.yaml` の自動スキーマ変換（safety セクション保持）
- Issues マイグレーションは手動: `bash .vibe/tools/migrate-issues.sh`

---

## [2.0.0] - 2025-02-08

v0.5.0 からのメジャーアップグレード。Discovery Phase（壁打ちフェーズ）、新ロール 2 種、Agent Team / context fork 対応、安全装置、CLI ツール化、マイグレーション機構を追加。

### Added

#### CLI ツール化

VibeFlow がサブコマンド形式の CLI ツールになった。PATH を通せばどこからでも実行可能。

```bash
# インストール
git clone https://github.com/mizkun/vibeflow.git ~/vibeflow
cd ~/vibeflow && ./install.sh

# 以降はどこからでも使える
vibeflow setup                    # 新規プロジェクト作成
vibeflow upgrade                  # 既存プロジェクトをアップグレード
vibeflow upgrade --dry-run        # 事前確認
vibeflow version                  # バージョン表示
vibeflow doctor                   # 環境診断
vibeflow help                     # ヘルプ

# フレームワーク更新の流れ
cd ~/vibeflow && git pull
cd ~/my-project && vibeflow upgrade
```

新規ファイル: `bin/vibeflow`, `install.sh`, `uninstall.sh`

#### Discovery Phase（壁打ちフェーズ）

開発サイクルの外で、プロダクト方針・技術選定・ビジネス戦略を議論するための新フェーズ。

**使い方:**

- `/discuss [トピック]` — 新規ディスカッションを開始
  - phase が `discovery` に切り替わる
  - `.vibe/discussions/DISC-XXX-[topic].md` が自動作成される
  - ロールが **Discussion Partner** に切り替わる
  - すべてのファイルが読み取り専用になる（discussion ファイルと state.yaml のみ書き込み可）
  - 相手の意見に同調するだけでなく、反論・疑問を積極的に提示してくる

- `/discuss --continue` — 前回のディスカッションを再開
  - 前回セッションの論点・仮の方針・未解決事項を要約して提示し、そこから議論を再開

- `/conclude` — ディスカッションを終了
  - 議論全体のサマリを作成（合意事項・未解決事項・結論・アクションアイテム）
  - vision.md / spec.md / plan.md への反映案を diff 形式で提示
  - ユーザー承認後に反映を実行
  - phase が `development` に戻る

**制約:**
- Discovery Phase 中に `/next` を実行するとエラーになる
- ファイル変更は `.vibe/discussions/` と `.vibe/state.yaml` のみ

**関連ファイル:** `.vibe/roles/discussion-partner.md`, `.vibe/templates/discussion-template.md`, `.claude/commands/discuss.md`, `.claude/commands/conclude.md`

#### Agent Team / context: fork

開発サイクルの特定ステップで、複数の視点による議論や、コンテキストを引き継いだ委譲実行が可能になった。

**実行モード:**

| モード | 説明 | フォールバック |
|---|---|---|
| **solo** | メインエージェントが単独で実行（従来通り） | — |
| **team** | Agent Team で複数の視点から議論 | solo に自動フォールバック |
| **fork** | context: fork で別エージェントに委譲（PM コンテキスト引き継ぎ） | solo に自動フォールバック |

**各ステップのモード割り当て:**

| ステップ | ロール | モード | チームメンバー |
|---|---|---|---|
| Step 1: Plan Review | PM | solo | — |
| Step 2: Issue Breakdown | PM | **team** | Technical Feasibility Analyst, UX Critic, Devil's Advocate |
| Step 2.5: Hook Permission Setup | Infra Manager | solo | — |
| Step 3: Branch Creation | Engineer | solo | — |
| Step 4: Test Writing (TDD Red) | Engineer | **fork** | — |
| Step 5: Implementation (TDD Green) | Engineer | **fork** | — |
| Step 6: Refactoring (TDD Refactor) | Engineer | **fork** | — |
| Step 6.5: Hook Rollback | Infra Manager | solo | — |
| Step 7: Acceptance Test | QA | **team** | Spec Compliance Checker, Edge Case Hunter, UI Visual Verifier |
| Step 9: Code Review | QA | **team** | Security Reviewer, Performance Reviewer, Test Coverage Reviewer |

**有効化:**

```bash
# Agent Team を有効にする（任意）
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

- 未設定でも動作する（solo にフォールバック）
- context: fork は Claude Code 2.1.20+ が必要（未対応環境では solo にフォールバック）

#### Safety Rules（安全装置）

5 つの安全ルールが CLAUDE.md に組み込まれた。

| # | ルール | 内容 |
|---|---|---|
| 1 | UI/CSS 変更ルール | atomic commit 単位で実行。変更前後のスクリーンショット確認をユーザーに求める |
| 2 | 破壊的ファイル操作の禁止 | `rm -rf`、`git reset --hard` 等は実行前に必ずユーザー確認 |
| 3 | 修正再試行の制限 | 同一アプローチでの再試行は最大 3 回まで。超えたらアプローチを変更し、失敗ログを `safety.failed_approach_log` に記録 |
| 4 | Hook 事前確認ルール | `.vibe/hooks/` 配下の変更は、影響範囲を説明して承認を得てから実行。ロールバック手順を `infra_log` に記録 |
| 5 | plans/ ディレクトリ書き込み禁止 | `validate_write.sh` フックによりブロック。計画は `plan.md` または `issues/` に記載 |

#### Infrastructure Manager ロール

hook の権限管理を担う新ロール。自動挿入ステップで起動する。

- **Step 2.5: Hook Permission Setup**（Step 2a の後に自動挿入）
  - `issues/*.md` の「対象ファイル」セクションを読み取り、`validate_write.sh` の許可リストを更新
  - 変更内容を `state.yaml` の `infra_log` に記録

- **Step 6.5: Hook Rollback**（Step 6a の後に自動挿入）
  - `infra_log` を参照して Step 2.5 で追加した権限をロールバック
  - `rollback_pending: false` を確認

ユーザーが `/next` を打たなくても自動で実行される。hook 変更時にはユーザー確認あり。

関連ファイル: `.vibe/roles/infra.md`

#### Write Guard（validate_write.sh）

PreToolUse フックとして `plans/` ディレクトリへの書き込みをブロック。

- 対象ツール: Write, Edit, MultiEdit
- 例外: Infrastructure Manager ロールは `.vibe/hooks/*` と `validate-write*` への書き込みが許可
- 設定場所: `.claude/settings.json` に PreToolUse フックとして登録済み

#### マイグレーション機構

既存の v1 プロジェクトを自動で v2 にアップグレードする仕組み。

```bash
cd your-project
vibeflow upgrade              # 通常実行
vibeflow upgrade --dry-run    # 事前確認（変更なし）
```

**動作の流れ:**

1. `.vibe/version` とフレームワークの `VERSION` を比較
2. 適用すべきマイグレーションスクリプトを特定（`migrations/` 内）
3. バックアップを作成（git commit + ファイルコピー → `.vibe/backups/`）
4. マイグレーションを順番に実行
5. `.vibe/version` を更新

**v1→v2 マイグレーションの内容:**

| # | 処理 | 詳細 |
|---|---|---|
| 1 | ディレクトリ作成 | `.vibe/discussions/`, `.vibe/backups/` |
| 2 | ロール・テンプレート追加 | `discussion-partner.md`, `infra.md`, `discussion-template.md` |
| 3 | コマンド追加 | `discuss.md`, `conclude.md` + 既存 `next.md` に v2 拡張を追記 |
| 4 | state.yaml 拡張 | `phase`, `discovery`, `safety`, `infra_log` フィールドを追加 |
| 5 | CLAUDE.md 更新 | Safety Rules セクション追記 + ワークフロー定義を v2 に置換 |
| 6 | validate_write.sh 配置 | Write Guard フックをコピー |
| 7 | Issue テンプレート拡張 | Implementation Plan + Progress セクションを追記 |
| 8 | バージョン記録 | `.vibe/version` を `2.0.0` に更新 |

**特徴:**
- 冪等: 何回実行しても同じ結果（既存ファイルは上書きしない）
- バックアップ付き: 失敗時は `.vibe/backups/` から復旧可能
- 段階的: 将来 v2.1.0 が出たら `migrations/v2.0.0_to_v2.1.0.sh` を追加するだけ
- 前提: `yq` コマンド推奨（`brew install yq`）。なくてもフォールバックで動作

新規ファイル: `upgrade_vibeflow.sh`, `lib/migration_helpers.sh`, `migrations/v1.0.0_to_v2.0.0.sh`

#### Issue テンプレート拡張

Issue テンプレートに 2 つのセクションが追加された。

- **Implementation Plan**: Engineer が Step 4 開始時に記述。対象ファイル、テスト対象、依存 issue、並列実行可否
- **Progress**: TDD サイクルの進捗追跡チェックリスト（テスト作成 / 実装 / リファクタリング）

#### state.yaml の新フィールド

v2 で 4 つのトップレベルフィールドが追加された。

```yaml
# フェーズ管理
phase: development           # "discovery" or "development"

# Discovery Phase の状態
discovery:
  id: null                   # DISC-XXX 形式の ID
  started: null              # 開始日
  topic: null                # トピック名
  sessions: []               # セッション履歴

# 安全装置の設定
safety:
  ui_mode: atomic            # UI 変更モード
  destructive_op: require_confirmation
  max_fix_attempts: 3        # 同一アプローチの最大再試行回数
  failed_approach_log: []    # 失敗アプローチの記録

# Infrastructure Manager のログ
infra_log:
  step: null                 # 現在のステップ
  hook_changes: []           # hook 変更履歴
  rollback_pending: false    # ロールバック待ち状態
```

#### プロジェクト構造の追加ファイル

```
.vibe/
├── version                           # バージョン追跡
├── discussions/                      # Discovery Phase の記録
├── backups/                          # アップグレード時のバックアップ
├── hooks/validate_write.sh           # Write Guard フック
├── roles/discussion-partner.md       # Discussion Partner ロール
├── roles/infra.md                    # Infrastructure Manager ロール
└── templates/discussion-template.md  # ディスカッションテンプレート

.claude/commands/
├── discuss.md                        # /discuss コマンド
└── conclude.md                       # /conclude コマンド
```

フレームワーク側:

```
vibeflow/
├── VERSION
├── bin/vibeflow
├── install.sh
├── uninstall.sh
├── upgrade_vibeflow.sh
├── lib/
│   ├── migration_helpers.sh
│   ├── claude-md-safety-rules.md
│   ├── claude-md-workflow-v2.md
│   ├── state-yaml-template.yaml
│   ├── roles/
│   ├── templates/
│   └── commands/
│       └── next-v2-extension.md
└── migrations/
    └── v1.0.0_to_v2.0.0.sh
```

### コマンドクイックリファレンス

**CLI コマンド（ターミナル）:**

| コマンド | 説明 |
|---|---|
| `vibeflow setup` | 新規プロジェクトをセットアップ |
| `vibeflow upgrade` | 既存プロジェクトをアップグレード |
| `vibeflow upgrade --dry-run` | 事前確認（変更なし） |
| `vibeflow version` | バージョン表示 |
| `vibeflow doctor` | 環境診断 |

**スラッシュコマンド（Claude Code 内）:**

| コマンド | 説明 | フェーズ |
|---|---|---|
| `/discuss [トピック]` | 壁打ち開始 | → discovery |
| `/discuss --continue` | 前回の壁打ちを再開 | discovery |
| `/conclude` | 壁打ち終了・反映 | discovery → development |
| `/next` | 次のステップへ進む | development |
| `/progress` | 進捗確認 | any |
| `/healthcheck` | 整合性チェック | any |

**環境変数（任意）:**

| 変数 | 説明 |
|---|---|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | Agent Team モードを有効化 |

## [0.5.0] - 2025-02-07

### Added

- Claude Code Hooks（PreToolUse / PostToolUse / Stop）による自動ガードレール
- Subagents（qa-acceptance, code-reviewer, test-runner）
- Skills（vibeflow-issue-template, vibeflow-tdd）
- validate_access.py によるロールベースアクセス制御
- 通知音（task_complete.sh, waiting_input.sh）

## [0.4.0] - 2025-02-06

### Changed

- examples/ ディレクトリの構造をリファクタリング
- 仕様の一貫性を修正
- 未使用コマンドを削除しフレームワークを簡素化
