# Iris-Only Architecture v5 設計書

## 1. 現行モデル vs 目標モデル

### 現行モデル (v4.1.0): Iris-first, user-operated

```
ユーザー ──┬── Iris Terminal (常駐)        → /discuss, /conclude
           ├── Dev Terminal (Issue単位)     → dev.sh <issue> → 11ステップ TDD
           └── Patch Terminal (Issue単位)   → /patch <issue> → 4ステップ修正
```

- ユーザーが **3種のターミナル** を操作
- ワークフローのステップ遷移はユーザー主導 (`/next`)
- Iris はコンテキスト管理・計画のみ。実行の dispatch はしない
- Engineer/QA/PM ロールの切替はステップごとに自動だが、ターミナル起動はユーザー

### 目標モデル (v5.0.0): Iris-only, user-talks

```
ユーザー ── Iris (単一ターミナル) ──┬── Codex (デフォルト coding agent)
                                    └── Claude Code (fallback coding agent)
```

- ユーザーは **Iris とだけ** 会話する
- Iris が Issue 作成 → agent 選択 → dispatch → 結果収集 → QA 判断 → クローズ を一貫して行う
- マルチターミナル不要。Dev Terminal / Patch Terminal は廃止
- ユーザーの介入は **人間チェックが必要な場合のみ**

### 主要な差分

| 項目 | v4.1.0 | v5.0.0 |
|------|--------|--------|
| ターミナル数 | 3 (Iris + Dev + Patch) | 1 (Iris のみ) |
| dispatch | ユーザーが手動起動 | Iris が自動 dispatch |
| coding agent | Claude Code のみ | Codex (デフォルト) + Claude Code |
| レビュー | code-reviewer subagent | クロスレビュー (別 agent が実施) |
| QA 判断 | qa-acceptance subagent + 人間 | Iris が自動判断 + 必要時のみ人間 |
| ステップ遷移 | `/next` でユーザー主導 | Iris が自動進行 |
| E2E テスト | オプション | Playwright デフォルト |

---

## 2. ユーザー体験フロー

### メインフロー

```
ユーザー: 「〇〇の機能を作りたい」
    │
    ▼
Iris: 要件を整理、Issue を作成
    │
    ▼
Iris: coding agent を選択 (Codex or Claude Code)
    │
    ├─── Codex に dispatch ──────────┐
    │    (非同期、sandbox 実行)       │
    │                                 │
    └─── Claude Code に dispatch ────┐│
         (同期、ローカル実行)         ││
                                      ▼▼
Iris: 結果を収集・統合
    │
    ▼
Iris: クロスレビュー dispatch
    │  (コーディングしなかった方の agent がレビュー)
    │
    ▼
Iris: QA 判断
    ├── PASS → PR 作成 → (人間チェック不要なら) マージ → クローズ
    └── FAIL → 修正を再 dispatch (最大 3 回)
    │
    ▼
ユーザー: 結果の報告を受ける
```

### 会話例

```
User: ダッシュボードにグラフを追加したい

Iris: 承知しました。要件を整理します。
      - 種類: 折れ線グラフ (日別アクセス数)
      - 配置: ダッシュボード右上
      - データソース: /api/stats/daily

      Issue #70 を作成しました。
      Codex に dispatch します。

      ... (自動実行中) ...

Iris: Codex が実装を完了しました。
      - src/components/DailyChart.tsx (新規)
      - src/pages/Dashboard.tsx (変更)
      - tests/components/DailyChart.test.tsx (新規)

      Claude Code によるクロスレビュー結果:
      - ✅ ロジック正常
      - ⚠️ レスポンシブ対応が未実装

      修正を Codex に再 dispatch します。

      ... (修正完了) ...

Iris: 全テスト PASS、E2E PASS。
      PR #71 を作成しました。
      UI の見た目確認が必要です。スクリーンショットを確認してください。
      [screenshot.png]

User: いい感じ、マージして

Iris: マージしました。Issue #70 をクローズします。
```

---

## 3. Iris の責務一覧

### 3.1 会話 (Conversation)
- ユーザーとの唯一のインターフェース
- 要件の聞き取り・整理・確認
- 進捗の報告
- ユーザー判断が必要な場面での質問

### 3.2 計画 (Planning)
- vision.md / spec.md / plan.md の維持
- タスクの分解・優先順位付け
- 依存関係の分析

### 3.3 Issue 管理 (Issue Lifecycle)
- GitHub Issue の自動作成 (テンプレート準拠)
- ラベル付与 (type, risk, qa)
- 完了時の自動クローズ

### 3.4 Agent Dispatch
- coding agent の選択 (§4 参照)
- タスクの agent への割り当て
- 並行 dispatch (独立タスクの場合)
- リトライ制御 (最大 3 回)

### 3.5 結果収集 (Result Collection)
- agent の出力 (diff, test results, logs) の収集
- 成果物の統合・コンフリクト解決
- STATUS.md の更新

### 3.6 QA 判断 (Quality Assurance)
- テスト結果の自動判定
- Acceptance criteria との照合
- Playwright E2E テストの実行・判定
- 人間チェックが必要かの判断 (§6 参照)

### 3.7 クロスレビュー調整 (Cross-Review)
- コーディングしなかった agent にレビューを dispatch
- レビュー結果の集約・判断
- 修正が必要な場合の再 dispatch

### 3.8 プロジェクト状態管理 (State Management)
- project_state.yaml の更新
- context/STATUS.md の維持
- references/ archive/ の管理

---

## 4. Coding Agent 選択ロジック

### デフォルト: Codex

Codex を第一選択とする理由:
- sandbox 環境で安全に実行
- 非同期実行が可能 (ユーザーを待たせない)
- 長時間タスクに適している

### Claude Code を使うケース

| 条件 | 理由 |
|------|------|
| ローカルファイルシステムへのアクセスが必要 | Codex sandbox では不可 |
| MCP サーバー連携が必要 | Claude Code のみ MCP 対応 |
| Playwright 操作が必要 | ローカルブラウザが必要 |
| Codex が 2 回失敗した | フォールバック |
| ユーザーが明示的に指定 | ユーザー優先 |

### 選択フロー

```
task_requires_local_fs?     → Claude Code
task_requires_mcp?          → Claude Code
task_requires_playwright?   → Claude Code
user_specified_agent?       → ユーザー指定に従う
codex_failed_twice?         → Claude Code (fallback)
else                        → Codex (default)
```

### Agent ラッパー

各 agent は統一インターフェースでラップする:

```
AgentWrapper:
  - dispatch(task: Task) → TaskHandle
  - poll(handle: TaskHandle) → Status
  - collect(handle: TaskHandle) → Result
  - cancel(handle: TaskHandle) → void
```

- **CodexWrapper**: Codex CLI (`codex` コマンド) をラップ。`--dangerously-skip-permissions` モードで実行
- **ClaudeCodeWrapper**: Claude Code CLI (`claude`) をラップ。`--dangerously-skip-permissions` モードで実行

---

## 5. クロスレビューの仕組み

### 原則

> コーディングしなかった方の agent がレビューする

これにより、単一 agent の盲点を補完し、品質を向上させる。

### フロー

```
1. Codex が実装 → Claude Code がレビュー
2. Claude Code が実装 → Codex がレビュー
```

### レビュー観点

レビュー agent は以下を検証する:

- **正確性**: 仕様 (Issue の acceptance criteria) との整合
- **テスト**: テストの十分性・正確性
- **セキュリティ**: OWASP Top 10, インジェクション系の脆弱性
- **パフォーマンス**: 明らかな N+1, 不要な再レンダリング
- **一貫性**: 既存コードベースとのスタイル整合

### レビュー結果のフォーマット

```yaml
review:
  verdict: pass | warn | fail
  items:
    - severity: error | warning | info
      file: src/components/Foo.tsx
      line: 42
      message: "..."
      suggestion: "..."
```

### Iris の判断

- `pass`: そのまま進行
- `warn`: 警告をユーザーに報告、進行は継続
- `fail`: 修正を元の coding agent に再 dispatch

---

## 6. 人間チェック判断基準

### 自動で完了できるケース (人間チェック不要)

- 全テスト PASS (unit + integration + E2E)
- クロスレビュー PASS
- diff が小さい (変更ファイル 5 以下、変更行 200 行以下)
- type ラベルが `fix` または `chore`
- risk ラベルが `low`

### 人間チェックが必要なケース

| 条件 | 理由 |
|------|------|
| UI/CLI の見た目・挙動変更 | スクリーンショットだけでは完全に判断できない |
| 完成度が主観的 | デザイン、文言、UX の良し悪し |
| risk ラベルが `high` | 影響範囲が大きい |
| セキュリティ関連の変更 | 認証、認可、暗号化 |
| 破壊的変更 (breaking change) | 後方互換性の確認 |
| E2E テストが存在しない画面 | 自動検証できない |
| 3 回目のリトライ | 自動修正の限界 |

### 人間チェックの方法

Iris がユーザーに以下を提示:
1. 変更の要約
2. スクリーンショット (UI 変更の場合)
3. 判断を求めるポイントの明示
4. `approve` / `reject` / `modify` の選択肢

---

## 7. セキュリティモデル

### `--dangerously-skip-permissions` の適用範囲

| Agent | 適用 | 理由 |
|-------|------|------|
| Codex | Yes | sandbox 内で実行されるため安全 |
| Claude Code (worker) | Yes | ユーザーが明示的に許可 (MEMORY.md に記載) |
| Iris (本体) | No | Iris は coding しない。誤操作防止 |

### ガードレール

#### Iris レベル
- src/ への書き込み禁止 (v4 から継承)
- dispatch 前に Issue の acceptance criteria を必ず確認
- リトライ上限 (3 回) を超えたらユーザーに判断を仰ぐ

#### Agent レベル
- 各 agent は指定されたブランチでのみ作業
- main/master への直接 push 禁止
- `rm -rf`, `git reset --hard` 等の破壊的コマンドは禁止リストで制御

#### プロジェクトレベル
- `.vibe/hooks/` による role-based access control は維持
- validate_access.py は引き続き有効
- ただし、v5 ではロールが Iris に集約されるため、ポリシーを簡素化

### 権限モデルの変更点

v4 では 5 ロール (Iris, PM, Engineer, QA, Infra) が分離していたが、v5 では:

- **Iris**: 計画・管理・QA判断 (src/ 書き込み禁止は維持)
- **Codex Worker**: コーディング + テスト (src/ 書き込み可)
- **Claude Code Worker**: コーディング + テスト + ローカル操作 (src/ 書き込み可)

ロールベースの厳密な分離から、**責務ベースの分離** に移行する。

---

## 8. アーキテクチャ全体図

```
┌─────────────────────────────────────────────────────┐
│                    ユーザー                           │
│                      │                               │
│                      ▼                               │
│  ┌───────────────────────────────────────────┐       │
│  │              Iris (単一ターミナル)           │       │
│  │                                           │       │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────┐ │       │
│  │  │ 会話管理  │  │ Issue管理 │  │ QA判断  │ │       │
│  │  └──────────┘  └──────────┘  └─────────┘ │       │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────┐ │       │
│  │  │ 計画策定  │  │ Dispatch │  │ 結果収集 │ │       │
│  │  └──────────┘  └──────────┘  └─────────┘ │       │
│  │                    │                      │       │
│  └────────────────────┼──────────────────────┘       │
│                       │                              │
│            ┌──────────┴──────────┐                   │
│            ▼                     ▼                   │
│  ┌──────────────────┐  ┌──────────────────┐         │
│  │   CodexWrapper    │  │ ClaudeCodeWrapper │         │
│  │                   │  │                   │         │
│  │  dispatch()       │  │  dispatch()       │         │
│  │  poll()           │  │  poll()           │         │
│  │  collect()        │  │  collect()        │         │
│  └──────────────────┘  └──────────────────┘         │
│            │                     │                   │
│            ▼                     ▼                   │
│  ┌──────────────────┐  ┌──────────────────┐         │
│  │  Codex (sandbox)  │  │  Claude Code     │         │
│  │  --dangerously-   │  │  --dangerously-  │         │
│  │  skip-permissions │  │  skip-permissions│         │
│  └──────────────────┘  └──────────────────┘         │
│                                                      │
│  ┌───────────────────────────────────────────┐       │
│  │           共有状態                         │       │
│  │  .vibe/project_state.yaml                 │       │
│  │  .vibe/context/STATUS.md                  │       │
│  │  GitHub Issues / PRs                      │       │
│  └───────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────┘
```

---

## 9. 移行計画サマリー

Issue #52〜#68 の 8 Wave で段階的に移行する。

| Wave | Issues | 内容 |
|------|--------|------|
| 1 | #52 | 本設計書 |
| 2 | #53, #54, #55 | Codex/Claude Code ラッパー + Playwright デフォルト化 |
| 3 | #56, #57, #58 | Agent 選択 + 結果収集 + Vision/Plan/Spec kickoff |
| 4 | #59, #60 | Issue 自動生成 + QA 判断 |
| 5 | #61, #62 | 依存分析 + 自動 dispatch |
| 6 | #63, #64 | クロスレビュー + 自動クローズ |
| 7 | #65, #66, #67 | CLAUDE.md→rules/ + /discuss 廃止 + マルチターミナル廃止 |
| 8 | #68 | README v5 同期 |

各 Wave は前の Wave が完了してから着手する。Wave 内の Issue は並行実施可能。
