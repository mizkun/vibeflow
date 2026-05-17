---
name: vibeflow-kickoff
description: プロジェクトのキックオフ。新規プロジェクトは Interview から Vision を作り、既存コードのプロジェクトは Bootstrap で As-Is の構造化 spec (Story/Contract) をコードから生成する。
---

# vibeflow-kickoff

VibeFlow v6 のキックオフ。プロジェクトの状態に応じて 3 モードで動く。
構造化 spec の考え方は `.claude/rules/spec-loop.md` を参照。

## When to Use

- 新規プロジェクトの初回セットアップ時
- VibeFlow を既存リポジトリに導入した直後（Bootstrap）
- Iris 起動時にプロジェクト状態を判定して自動実行

## モード判定

順に判定する:

1. **structured（spec あり）**: `.vibe/spec/stories/` に 1 つ以上の Story がある
   → 読み込みモード。spec をロードし現状をサマリ報告して終了。
2. **Bootstrap（既存コード・spec なし）**: ソースコードが存在する
   （`src/`, `lib/`, `app/`, `*.py`/`*.ts` 等）のに `.vibe/spec/stories/` が
   空または無い → **Bootstrap 手順**へ。
3. **scratch（新規）**: コードも spec も無い → **新規プロジェクト手順**へ。

---

## Bootstrap 手順（既存コード → As-Is 構造化 spec）

目的: 今のコードの仕様を構造化 spec として**そのまま正直に写す**。

> **原則（重要）**
> - **As-Is をそのまま写す。** 密結合・汚いコードでも正直に写す。先に
>   疎結合化しない。疎結合は目標であって前提ではない。Bootstrap で結合の
>   絡まりが見える化され、「ここを疎結合にする」が普通の Issue になる。
> - **完璧を目指さない。** 既存コードから拾える invariant は一部。残りは
>   運用の中でバグ改修 (iii)（`spec-loop.md`）として積み上がる。
>   「不完全だが正直な spec」が出発点。
> - **PO に YAML を書かせない。** Story/Contract は Agent が書く。

### Step B1: コードベースの俯瞰

1. ディレクトリ構造を調べる（`src/`, `lib/`, `app/` 配下など）。
2. **ドメイン**を特定する。1 ドメイン = 一貫した責務を持つコードのまとまり。
   通常はコードの 1 ディレクトリに対応（例: `pneuma_core/memory/`,
   `pneuma_core/models/`）。**ディレクトリが大きく密結合でも、分割せず
   1 Story として正直に写す**（疎結合化は後の Issue。先にやらない）。
3. ドメイン間の依存（import 関係）を把握する。

### Step B2: ドメインごとに Story を書く

各ドメインについて `.vibe/spec/stories/<id>.yaml` を作成（スキーマは
framework の `core/schema/spec.yaml`）。**必須フィールドは
`id` / `one_liner` / `invariants` / `source_files` の 4 つ — どれか欠けると
spec-verify が失敗する。全 Story に必ず書く**:

- `id` — ドメイン ID（kebab-case、ファイル名と一致）
- `one_liner` — このドメインが何かを 1 行で
- `source_files` — 実装を含むディレクトリ / ファイル。**どのドメイン
  ディレクトリにも属さないパッケージ直下のファイル**（例: `pkg/utils.py`）は、
  最も関連の深い Story の `source_files` に含める。取りこぼさない。
- `depends_on` — 依存する他ドメインの id
- `invariants` — コードを読んで不変条件を**推定して**書く。各 invariant:
  - `id` / `text`（平易な 1 文）
  - `test` — その不変条件を検証する**既存テスト**があればパス。無ければ省略。
  - `source_ref` — その不変条件を担保するコード位置（`file` or `file:symbol`）。
    モジュール全体に渡る不変条件で単一 symbol が無ければ `file` だけでよい。
    symbol を付ける場合はリファクタに強い位置（クラス・公開関数）を選ぶ。
  - テストの無い invariant も**必ず記録する**（欠落させない）。多くは
    `test` 省略の pending で構わない。

### Step B3: 境界を渡る型を Contract に書く

**判定ルール（迷わず機械的に適用する）**: ある型を、定義元ドメイン以外の
ドメインが import / 使用していれば Contract にする。すなわち producers の
ドメインと、consumers に含まれるドメインが 1 つでも異なれば該当。自ドメイン
内でしか使われない型は Contract にしない。**越境する型は sprawl を恐れず
全て記録する**（「数が多いから」で間引かない — 判断は入れない）。

該当する型について `.vibe/spec/contracts/<id>.yaml` を作成:

- `id` / `story` — 属するドメイン。型が複数ドメインで生成される場合、
  `story` は**型の定義元ドメイン**にする。
- `schema_ref` — host 言語の型への参照（型は再宣言しない。Python は
  ドット区切り `pkg.module.Type`、TS は `path#Type`）
- `producers` / `consumers` — 生成側・消費側のソースファイル

### Step B4: 検証

`vibeflow spec-verify` を実行し、書いた spec がコードと整合しているか
（参照先が実在するか、story 参照が解決するか）を確認する。ERRORS が
出たら spec を直す。これで As-Is spec が内部整合した状態になる。

`vibeflow` が PATH に無ければ直接:
`python3 <framework>/core/runtime/spec_verify.py .vibe/spec .`

### Step B5: PO へ報告

ユーザーに会話で（チャットで）以下を報告する:

- 検出したドメイン一覧（Story 数 / Contract 数）
- invariant 総数と pending 数（テスト未整備の数 = 今後の検証対象）
- 目立つ密結合や設計上の気づき（疎結合化は Issue 候補として提示）

その後、必要なら Vision を Interview で作る（無ければ）。

---

## 新規プロジェクト手順（scratch）

コードがまだ無いので As-Is spec は空。Vision と Plan を作り、構造化 spec は
最初の Issue でコードと一緒に育てる。

### Step N1: Interview → Vision

ユーザーと対話し `vision.md` を作る（PO が書く唯一のアーティファクト）:
- なぜこのプロダクトが存在するか / 主要ユーザー / 成功の定義 /
  絶対に守ること・やらないこと / 用語集
- PO に YAML や構造化 spec は書かせない。Vision は自然言語。

### Step N2: Plan

Vision からロードマップ `plan.md` を作る。各項目は将来 Issue 化され
Issue = Spec 差分になる（`spec-loop.md`）。想定ドメインを併記する。

### Step N3: 構造化 spec はコードと共に生まれる

新規プロジェクトでは `.vibe/spec/` は最初は空。あるドメインの最初のコードを
書く Issue の中で、そのドメインの Story を新規作成する（As-Is = 今書いた
コードの仕様）。空の Story をコード無しで先に作らない（検証が通らない）。

---

## 既存（structured）手順

`.vibe/spec/` の Story/Contract、`vision.md`/`plan.md`、`.vibe/context/STATUS.md`、
GitHub open Issues を読み込み、現状サマリ（直近の動き / 未完了 Issue /
次のアクション候補）を報告する。

## 生成後の振る舞い

- 構造化 spec を常に参照しながら行動する
- Issue 作成時は Plan の項目と紐付け、Issue = Spec 差分として書く
- 技術判断は Story の invariant / Contract を根拠にする
