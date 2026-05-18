# Structured Spec Architecture v6 設計書

VibeFlow v6 の設計ドキュメント。v6 の本質的な変更は 1 つだけ — 緩い `spec.md` を
**構造化 spec（Story / Contract）** に置き換えることである。

## 1. v6 で変えたもの / 変えていないもの

### 変えていない（v5 から継承）

v5 の Iris-Only アーキテクチャはそのまま継承する。詳細は
[`architecture-v5.md`](architecture-v5.md) を参照。

- **Iris-Only**: ユーザーは Iris とだけ会話する。単一ターミナル
- **Issue 駆動**: すべての作業は GitHub Issue に紐づく
- **Standard Workflow（11 Steps）**: Issue Review → TDD → QA → PR → Cross-Review → Merge
- **Agent Dispatch**: Claude Code（デフォルト実装）+ Codex（レビュー / フォールバック）
- **Cross-Review / 自動 QA 判断 / Playwright デフォルト**

### 変えた（v6 の唯一の変更）

| 項目 | v5 | v6 |
|------|-----|-----|
| 仕様の表現 | 緩い `spec.md`（穴埋めテンプレ、書式自由） | 構造化 spec（`.vibe/spec/` 配下の Story / Contract YAML） |
| 仕様とコードの対応 | 暗黙。改修のたびに乖離 | invariant 単位で `source_ref` / `test` に紐づく |
| 仕様の検証 | なし | `vibeflow spec-verify`（drift 検出）+ Spec Gate（PR ゲート） |
| 仕様の更新単位 | 自由記述 | Issue = Spec 差分（As-Is → To-Be の git diff） |

---

## 2. なぜ構造化 spec か

v5 の `spec.md` は書式が決まっていない穴埋めテンプレートだった。改修のたびに
実装と乖離し、やがて誰も信用しないドキュメントになる。**これが VibeFlow の
保守の弱さの根本原因だった。**

構造化 spec が目指すのは、次の 4 性質を持つ仕様である。

1. **再現性が高い** — 同じ入力から同じ spec が導ける
2. **解釈の余地がない** — invariant は平易な 1 文で言い切る
3. **コードと 1:1 対応する** — invariant は `source_ref` で実装位置を指す
4. **検証できる** — `test` を持つ invariant は CI で真偽が判定できる

ドキュメントを「正しく保て」と祈るのではなく、**ずれたら検出される構造**にする。

---

## 3. spec を構成する 2 つのデータ型

spec は 2 種類のデータ型だけで構成する。スキーマの正本は
`core/schema/spec.yaml`。

### 3.1 Story — 1 ドメインの説明

1 つのドメインが「何であるか」と「何を必ず守るか（invariants）」を書く。
コードで表現できる詳細は書かない。コードから導出できない意図だけを書く。

- 配置: `.vibe/spec/stories/<story-id>.yaml`（1 ドメイン 1 ファイル）
- 「1 ドメイン」= 一貫した責務を持つコードのまとまり。通常はコードの 1
  ディレクトリに対応する
- 主要フィールド: `id` / `one_liner` / `invariants` / `source_files` / `depends_on`

**invariant（不変条件）** が Story の核である。各 invariant は:

| フィールド | 必須 | 内容 |
|-----------|------|------|
| `id` | ✓ | 不変条件 ID（kebab-case） |
| `text` | ✓ | 不変条件を平易な言葉で 1 文 |
| `test` | — | 検証テストのパス。無ければ省略 |
| `source_ref` | — | 担保するコード位置（`file` または `file:symbol`） |
| `rationale` | — | なぜこの不変条件か |

`verified` / `pending` の状態は spec ファイルに **保存しない**（計算で求める）:

- `test` 省略 → **pending**（まだテストで裏付けられていない invariant）
- `test` 有り → その test の参照先が実在するかを検査。実在すれば「テストで
  裏付けられた invariant」とみなす

ただし `spec_verify.py` 自体はテストを**実行しない**。静的に「`test` パスが
設定されているか」「参照先（`test` / `source_ref`）が実在するか」を検査し、
pending 数と drift を報告するだけである。invariant が実際に守られているか
（通過 / 失敗）の最終判定は、TDD / CI のテスト実行が担う。

未テストの invariant も Story に必ず記録する（欠落させない）。

### 3.2 Contract — モジュール間を渡るデータの形

モジュール間 / プロダクト境界を渡るデータの形を登録する。型そのものは
再宣言しない（二重管理を作らない）。host 言語ネイティブの型を `schema_ref`
で指すだけの薄い登録層。

- 配置: `.vibe/spec/contracts/<contract-id>.yaml`
- 主要フィールド: `id` / `schema_ref` / `producers` / `consumers` / `story`
- `schema_ref` の文法は host 言語に合わせる（Python はドット区切りパス、
  TS は `module#型名`）

Module は独立データ型にしない（コードのディレクトリ構造から導出する）。

---

## 4. ループモデル — Issue = Spec 差分

v6 の中核となる開発ループ。

```
Iris と会話
  → Spec の As-Is（今のコードの仕様）と To-Be（変更後）を作る
  → As-Is → To-Be の差分 = Issue
  → TDD でコードを To-Be に合わせる → Cross-Review
  → マージ後、Spec の As-Is が To-Be に進む
```

- **As-Is** = base ブランチに commit 済みの spec ファイル群
- **To-Be** = Issue ブランチ上で編集した spec ファイル群
- `git diff(As-Is, To-Be)` が、そのまま Issue の中身になる
- マージ後、As-Is が To-Be に進む。**追加の As-Is/To-Be 機構は持たない**
  （git のブランチ機構をそのまま使う）
- 大きな Spec 変更は Plan（ロードマップ）も動かしうる → 同じ Issue 内で
  Plan も更新する

---

## 5. バグ改修の 3 分類

バグに対応するとき、必ず以下のどれかに分類する。判定基準は
**「このバグに対応する invariant が spec にあるか？」**。

| 種別 | 状況 | 対応 |
|------|------|------|
| (i) コード違反 | spec の invariant は正しい。コードが違反している | To-Be == As-Is。**コードだけ直す** |
| (ii) spec 誤り | spec の invariant 自体が間違っていた | To-Be ≠ As-Is。**invariant も直す** + コード |
| (iii) spec 欠落 | そのルールが invariant としてどこにも記録されていなかった | To-Be = As-Is + 新 invariant。**invariant を追加し test を付ける** + コード |

**(iii) が最重要。** 「誰も記録していなかったルールを踏み抜いた」結果のバグは、
その場で invariant を Story に書き足す。これをやらないと同じバグを二度踏む。
**spec を完成へ収束させるエンジンは (iii) である。**

Bootstrap 直後の spec は不完全（既存コードから拾える invariant は一部）。
運用の中で (iii) を積み重ねることで、spec は使うほど賢くなる。

---

## 6. 検証 — drift を検出する仕組み

構造化しただけでは drift する。検証フローが伴って初めて意味を持つ。
検証は 2 層ある。

### 6.1 日常検証 — `vibeflow spec-verify`

`core/runtime/spec_verify.py` が `.vibe/spec/` を静的検査する。HealthCheck
（`vibeflow-healthcheck` skill）の項目 #8 にも統合されている。

検出するもの:

- **スキーマ違反**: 必須フィールド欠落、YAML パースエラー、型不整合
- **drift**: `source_ref` / `source_files` の参照先ファイル・シンボルの消失
- **Contract の参照不整合**: `schema_ref` が解決できない（best-effort、
  warning に留める — 非標準レイアウトでの誤検知を避けるため）
- **pending invariant 数**: `test` 未設定の invariant の集計

エラーがあれば FAIL、参照解決失敗などは WARNING。

### 6.2 PR ゲート — Spec Gate

`examples/.vibe/hooks/validate_step7a.py` が PreToolUse hook として動作する。

- `.vibe/spec/` を変更した PR は **Human Checkpoint（Step 7a）を必ず通る**
- `qa:auto` では自動承認できない。明示的な人間の `approved` checkpoint
  （`.vibe/checkpoints/<issue>-qa-approved`）がない限り `gh pr create` が
  ブロックされる
- spec の As-Is → To-Be 差分をユーザーに提示し、承認を得てから進む

spec 変更時の人間チェックは honor-system ではなく **hook で強制される**。

---

## 7. Bootstrap — 既存コードから As-Is spec を生成

新規プロジェクトと既存プロジェクトで入口が異なる（`vibeflow-kickoff` skill）。

- **新規プロジェクト**: Interview から Vision を作る。`.vibe/spec/` は最初は
  空。あるドメインの最初のコードを書く Issue で、その Story を起こす
- **既存プロジェクト**: **Bootstrap** で As-Is の構造化 spec をコードから
  生成する。各ドメイン（≒ ディレクトリ）について Story を作り、コードから
  推定した invariant を写す

Bootstrap の原則:

- **As-Is をそのまま正直に写す**。密結合な repo でも正直に写す。先に
  疎結合化しない
- 推定した invariant の多くは `test` 省略の **pending** で構わない。
  pending を verified に押し上げるのは後続の Issue
- spec は Agent が書く。PO は書かない（PO が書くのは Vision）

---

## 8. ワークフローへの統合

構造化 spec は Standard Workflow（11 Steps）の中に組み込まれる。
ルールの正本は `examples/.claude/rules/spec-loop.md`。

- **Step 1-2（Issue Review / Task Breakdown）**: Issue を Spec の As-Is → To-Be
  差分として捉える。Story / Contract の編集も Issue ブランチ上で行う
- **Step 4（Test Writing）**: 新規 invariant には test を付ける（TDD）
- **Step 7（Acceptance Test）**: `spec-verify` で drift がないか確認
- **Step 7a（Human Checkpoint）**: `.vibe/spec/` を変更した PR は Spec Gate
  により人間承認が必須
- **マージ後**: Spec の As-Is が To-Be に進む

---

## 9. ファイル配置とコンポーネント

### フレームワーク側（VibeFlow リポジトリ）

| パス | 役割 |
|------|------|
| `core/schema/spec.yaml` | Story / Contract スキーマの正本 |
| `core/runtime/spec_verify.py` | 検証エンジン（drift / pending 検出） |
| `examples/.claude/rules/spec-loop.md` | ループモデル・バグ 3 分類のルール |
| `examples/.vibe/hooks/validate_step7a.py` | Spec Gate（PR ゲート hook） |
| `bin/vibeflow`（`spec-verify` サブコマンド） | CLI エントリポイント |

### プロジェクト側（VibeFlow を導入したプロジェクト）

| パス | 役割 |
|------|------|
| `.vibe/spec/stories/<id>.yaml` | Story インスタンス（1 ドメイン 1 ファイル） |
| `.vibe/spec/contracts/<id>.yaml` | Contract インスタンス（1 Contract 1 ファイル） |
| `.vibe/runtime/spec_verify.py` | 配備された検証エンジン |
| `.claude/rules/spec-loop.md` | 配備されたルール |

---

## 10. アーキテクチャ全体図

```
┌──────────────────────────────────────────────────────────┐
│                       ユーザー                            │
│                          │                                │
│                          ▼                                │
│         ┌────────────────────────────────────┐            │
│         │      Iris（単一ターミナル）          │            │
│         │  会話 / Issue 管理 / Dispatch / QA   │            │
│         └────────────────┬───────────────────┘            │
│                          │                                │
│        ┌─────────────────┼──────────────────┐             │
│        ▼                                    ▼             │
│  ┌───────────┐                      ┌───────────────┐     │
│  │ Coding    │  As-Is → To-Be       │ 構造化 spec    │     │
│  │ Agent     │◄────diff = Issue────►│ .vibe/spec/    │     │
│  │ (TDD)     │                      │  stories/      │     │
│  └─────┬─────┘                      │  contracts/    │     │
│        │                            └───────┬───────┘     │
│        │ コード                              │ invariant   │
│        ▼                                    ▼ 検証         │
│  ┌───────────┐                      ┌───────────────┐     │
│  │  src/     │◄──source_ref / test──│ spec_verify.py │     │
│  │  tests/   │      で 1:1 対応       │ (drift 検出)   │     │
│  └───────────┘                      └───────┬───────┘     │
│                                             │             │
│                                             ▼             │
│                                   ┌───────────────────┐   │
│                                   │ Spec Gate          │   │
│                                   │ (validate_step7a)  │   │
│                                   │ spec 変更 PR は     │   │
│                                   │ 人間承認を強制      │   │
│                                   └───────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## 11. スコープ外 — 意図的に持ち込まないもの

設計議論の母体（akasha v2）には、より重い機構が存在した。v6 では
**基本ループが動くこと**を優先し、以下は意図的に持ち込まない。

- stake 軸 / Decision Card
- drift 検出専用の CI パイプライン
- Iris Session の独立データ型 / Atlas
- 言語アダプタ（`define_contract` ランタイム）
- Contract の per-consumer subset スキーマ

これらは過剰な機械である。基本ループ（Issue = Spec 差分 + 検証 + バグ 3 分類）
が回ってから、必要なら上に載せる。**ゼロから作り直さず、VibeFlow を進化させる。**

---

## 移行

v5.0.0 から v6.0.0 への移行は `migrations/v5.0.0_to_v6.0.0.sh` が自動化する
（`spec-loop` ルール / `.vibe/spec/` 構造 / `spec_verify` ランタイム /
Spec Gate の配備、CLAUDE.md のバックアップ、バージョン更新）。移行後は
`vibeflow-kickoff` の Bootstrap で既存コードから As-Is spec を生成する。
