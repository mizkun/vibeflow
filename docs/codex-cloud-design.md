# Codex Cloud Task — 設計ドキュメント

> Phase 3-5 成果物。実装は将来フェーズで行う。

## 1. 背景と目的

VibeFlow の Phase 3 で実装したローカル Codex 連携（`codex_review.sh`, `codex_impl.sh`）は、
開発者のマシン上で同期的に Codex を実行する前提で設計されている。

しかし以下のケースでは、ローカル実行では対応が難しい：

- **長時間タスク**: 大規模コードベースの review が 10 分以上かかる場合、ターミナルを占有し続ける
- **並列実行**: 複数の handoff packet を同時に処理したい場合、ローカルではリソース制約がある
- **非同期ワークフロー**: 夜間バッチや CI/CD パイプラインから投入し、結果を後で取得したい

Cloud task 対応は、これらのユースケースに対応するための**非同期実行レイヤー**を提供する。

## 2. 想定ユースケース

### 2.1 長時間 review
- 大規模 PR（100+ ファイル変更）の review を cloud に投入
- 開発者はローカルで作業を続行
- 完了時に通知を受け取り、結果を確認

### 2.2 大規模 migration review
- フレームワークアップグレード後の全ファイル review
- ローカルでは時間がかかりすぎるケース
- 結果は `.vibe/reviews/` に保存される（ローカルと同じスキーマ）

### 2.3 夜間バッチ
- CI/CD から handoff packet を投入
- 朝にはすべての review/impl 結果が揃っている
- 失敗したタスクのみ再実行

### 2.4 並列 task 実行
- Issue 分割後の複数 dev task を同時実行
- 各 task は独立した worktree/branch で動作（ローカル実装と同じ分離モデル）
- すべて完了後に順次 review → merge

## 3. ローカル実装との違い

| 観点 | ローカル (`codex_impl.sh`) | Cloud task |
|------|---------------------------|------------|
| 実行環境 | 開発者マシン | リモートサーバー / Codex Cloud API |
| 同期/非同期 | 同期（ブロッキング） | 非同期（投入 → polling/webhook → 取得） |
| worktree | ローカル `.vibe/worktrees/` | リモート側で管理、結果を diff/patch で返却 |
| 結果保存 | ローカルファイルシステム | API レスポンス → ローカルにダウンロード |
| 並列数 | マシンリソースに依存（通常 1） | API 側の制限に依存（複数可） |
| diff validation | ローカルで即時実行 | 結果取得後にローカルで実行（同じロジック） |
| validation commands | worktree 内で実行 | リモートでは実行不可 → 結果取得後にローカルで実行 |
| AGENTS.md | ローカルから読み込み | 投入時に添付 or リモートリポジトリから読み込み |

**重要**: diff validation と validation commands は**必ずローカルで再実行**する。
リモート側の結果だけを信頼しない（safety-first 原則）。

## 4. タスク投入フロー

```
handoff packet
    │
    ▼
┌─────────────────────┐
│  cloud_submit.sh    │  ← 将来実装
│  (or Python CLI)    │
└─────────┬───────────┘
          │
          │  POST /tasks (API call)
          │  Body: { packet, agents_md, repo_ref }
          ▼
┌─────────────────────┐
│  Codex Cloud API    │
│  (or self-hosted)   │
└─────────┬───────────┘
          │
          │  task_id (cloud)
          ▼
┌─────────────────────┐
│  .vibe/cloud-tasks/ │  ← ローカルにタスク情報を保存
│  <task_id>.json     │
└─────────────────────┘
```

### 投入時に送信するもの
- handoff packet（そのまま）
- AGENTS.md の内容（instruction layer）
- リポジトリ参照情報（repo URL, branch, commit SHA）
- must_read ファイルの内容（snapshot）

### 投入時に**送信しないもの**
- 認証情報、秘密鍵
- `.env` ファイル
- `.vibe/` 内部の状態ファイル（project_state.yaml 等）

## 5. タスク状態管理

### 状態遷移

```
submitted → queued → running → completed
                         │         │
                         ▼         ▼
                       failed   cancelled
```

### ローカル状態ファイル: `.vibe/cloud-tasks/<cloud_task_id>.json`

```json
{
  "cloud_task_id": "ct-abc123",
  "local_task_id": "task-42-dev",
  "status": "running",
  "submitted_at": "2026-03-09T10:00:00Z",
  "updated_at": "2026-03-09T10:05:00Z",
  "api_endpoint": "https://api.example.com/tasks/ct-abc123",
  "result_path": null,
  "error": null
}
```

## 6. Polling vs Webhook

### Polling 方式

```
while status != "completed":
    GET /tasks/<id>/status
    sleep interval
```

**Pros:**
- 実装がシンプル
- NAT/ファイアウォール問題なし
- CLI ツールとの相性が良い

**Cons:**
- レイテンシ（interval 分の遅延）
- API コール数が多い

### Webhook 方式

```
POST /tasks/<id> { callback_url: "https://..." }
# 完了時に callback_url に POST される
```

**Pros:**
- リアルタイム通知
- API コール数が少ない

**Cons:**
- ローカル開発環境に public URL が必要（ngrok 等）
- ファイアウォール/NAT 問題
- 信頼性（callback 失敗時のリトライ）

### 推奨: Polling-first + Webhook optional

- **デフォルト**: Polling（`cloud_poll.sh` or `vibeflow cloud status <id>`）
- **オプション**: Webhook（CI/CD 環境で利用）
- Polling interval: 初回 5s、以降 exponential backoff（max 60s）
- Timeout: 設定可能（デフォルト 30 分）

## 7. 結果取得の流れ

```
┌─────────────────────┐
│  cloud_fetch.sh     │  ← 将来実装
│  (or vibeflow CLI)  │
└─────────┬───────────┘
          │
          │  GET /tasks/<id>/result
          ▼
┌─────────────────────┐
│  結果ダウンロード     │
│  - diff / patch     │
│  - review JSON      │
│  - execution log    │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────────────────────────┐
│  ローカル検証（必須）                      │
│  1. diff validation (validate_diff)     │
│  2. validation commands (run_validation)│
│  3. 結果を .vibe/reviews/ に保存          │
│  4. branch 作成 + patch 適用             │
└─────────────────────────────────────────┘
```

**結果取得後のローカル検証は必須**。リモートの結果を無条件に信頼しない。

### Review タスクの結果
- `codex_review.py` の `parse_review()` と同じスキーマで保存
- `passed`, `has_warnings`, `findings` をローカルで再判定

### Implementation タスクの結果
- diff/patch 形式で受け取り
- ローカルで `validate_diff()` を実行
- `git apply` で worktree に適用（auto-merge しない）
- validation commands をローカルで実行

## 8. 失敗時の扱い

### リモート実行失敗
- `status: "failed"` + `error` フィールドに詳細
- ローカル状態ファイルを更新
- ユーザーに通知（CLI 出力 or webhook callback）
- 自動リトライは行わない（明示的な再投入が必要）

### ネットワーク障害
- Polling 失敗時: exponential backoff で継続
- 投入失敗時: ローカルにドラフト状態で保存、手動リトライ可能
- 結果取得失敗時: 再取得コマンドを提供

### Timeout
- デフォルト 30 分超過 → `status: "timeout"`
- タスク種別ごとに設定可能（review: 15 分、impl: 60 分等）

### 部分的成功
- review で一部ファイルの解析が失敗した場合
- 成功分の findings を返し、失敗分を error として報告
- `passed` 判定は成功分のみで行う（保守的に fail にする選択肢もあり）

## 9. 安全性

### 9.1 allowed_paths / forbidden_paths
- handoff packet の `constraints` はローカルと**完全に同じロジック**で検証
- リモート側が constraints を守ったかどうかに関わらず、ローカルで `validate_diff()` を再実行
- 違反があれば結果を却下（patch 適用しない）

### 9.2 validation.required_commands
- リモートでは実行しない（リモート環境にプロジェクト依存のツールがない可能性）
- 結果取得後にローカル worktree で実行
- 失敗時は結果を却下

### 9.3 Manual merge 前提
- cloud task の結果は**絶対に** auto-merge しない
- ローカルの `codex_impl.sh` と同じく、feature branch に留める
- merge はユーザーの明示的な操作のみ

### 9.4 Secret の扱い
- handoff packet に secret を含めない
- AGENTS.md は送信するが、`.env` や credential は送信しない
- リモート実行環境の secret は API 側の責任（VibeFlow は管理しない）

### 9.5 結果の検証
- リモートから受け取った diff/review は**信頼しない**
- すべての validation をローカルで再実行
- 「リモートで OK」でもローカル validation が fail なら却下

## 10. handoff packet と worker_adapter への接続方法

### handoff packet
- 既存の packet スキーマをそのまま使用
- 追加フィールド（将来）:

```json
{
  "...existing fields...",
  "execution_mode": "cloud",
  "cloud_config": {
    "api_endpoint": "https://...",
    "timeout_minutes": 30,
    "priority": "normal"
  }
}
```

- `execution_mode` が未指定 or `"local"` の場合は既存のローカル実行

### worker_adapter
- 将来 `CloudCodexWorker` を追加:

```python
class CloudCodexWorker(WorkerAdapter):
    worker_type = "codex-cloud"

    def _execute(self, packet: dict) -> dict:
        # 1. API にタスク投入
        # 2. cloud_task_id を返す
        # 3. status: "submitted" で即座に return
        return {
            "status": "submitted",
            "cloud_task_id": "ct-xxx",
            "poll_url": "https://...",
        }
```

- `get_worker("codex-cloud")` で取得
- `execute()` は非同期（即座に return）
- 結果取得は別コマンド（`cloud_fetch.sh` or `vibeflow cloud fetch <id>`）

### _WORKERS レジストリ拡張

```python
_WORKERS = {
    "claude": ClaudeWorker,
    "codex": CodexWorker,
    "codex-cloud": CloudCodexWorker,  # 将来追加
    "human": HumanWorker,
}
```

## 11. 今後の実装候補（Phase 4 以降）

| 優先度 | 項目 | 概要 |
|--------|------|------|
| P1 | `cloud_submit.sh` | タスク投入スクリプト |
| P1 | `cloud_fetch.sh` | 結果取得 + ローカル検証スクリプト |
| P1 | `CloudCodexWorker` | worker_adapter への追加 |
| P1 | `.vibe/cloud-tasks/` | ローカル状態管理 |
| P2 | `vibeflow cloud status` | CLI コマンド |
| P2 | Polling with backoff | 状態監視ループ |
| P2 | CI/CD integration | GitHub Actions からの投入 |
| P3 | Webhook support | リアルタイム通知 |
| P3 | 並列タスクダッシュボード | 複数タスクの一括管理 |
| P3 | Cost estimation | 投入前のコスト見積もり |

## 12. 非スコープ

以下は本設計ドキュメントおよび Phase 3 の範囲外：

- Cloud task の実装コード
- 非同期実行ランタイム
- Queue / message broker の選定・実装
- Webhook エンドポイントの実装
- Codex Cloud API の認証フロー実装
- 課金・コスト管理
- マルチテナント対応
- Phase 4 の項目（Iris Session Manager, Patch Loop 等）
