# VibeFlow v6 — 引き継ぎ資料

作成: 2026-05-17 / 前セッション（`akasha` リポで実施した設計議論）からの handoff

新セッションはこれを最初に読む。v6 開発を続けるのに必要な決定事項・方針・次の手が全部ここにある。

---

## 1. 何を作るか

**VibeFlow の次バージョン（v6）。** リポ: `/Users/kyohei/vibe/vibeflow`（現在 v5.0.0, `main`）。

「Akasha」という別ハーネスを作るのは **やめた**。Akasha はゼロから作り直しに走って複雑になりすぎた。
結論: **VibeFlow を作り直さず、進化させる。**

## 2. 唯一の変更

VibeFlow v5 の設計（Iris-Only / Issue 駆動 / standard 10 ステップ / TDD / Cross-Review / QA）は **そのまま**。

変えるのは 1 箇所だけ:

> **緩い `spec.md` を、構造化された仕様（Story / Contract）に置き換える。**

v5 の `spec.md` は書式が決まっておらず（`[technology]` の穴埋めテンプレ）、改修のたびに実装と乖離して壊れた。これが VibeFlow が保守に弱かった根本原因。構造化 spec は「再現性が高く、解釈の余地がなく、コードと 1:1 対応し、検証できる」仕様。

## 3. ループモデル

```
Iris と会話
  → Spec の As-Is（今のコードの構造化仕様）と To-Be（変更後）を作る
  → As-Is → To-Be の差分 = Issue
  → コードを To-Be に合わせる（TDD → レビュー）
  → マージ後、Spec の As-Is が To-Be に進む
```

- **Issue = Spec 差分。**
- 大きな Spec 変更は Plan（ロードマップ）も動かしうる → 同じ Issue 内で Plan も更新する経路を持つ。
- バグ改修は 2 種類:
  - (i) Spec は正しくコードが違反 → To-Be == As-Is、コードだけ直す
  - (ii) Spec 自体が誤り → To-Be ≠ As-Is、Spec も直す

## 4. 構造化 spec（Story / Contract）の骨子

詳細スキーマ案は `akasha` リポの `docs/v2-data-model.md` にある。
**slim 版の良い部分だけ salvage する。** stake 軸 / drift CI / Decision Card インフラ等の過剰な機械は持ち込まない。

- **Story** — 1 ドメイン 1 ファイル。`one_liner` / `invariants`（+ test path、未テストは `pending` 可）/ `source_files` / `depends_on`。
- **Contract** — モジュール間を渡るデータの形。ホスト言語ネイティブの型を参照する（Python は Pydantic/dataclass、TS は zod/型）。**zod 固定にしない**（二重管理を避ける）。`id` / `schema_ref` / `producers` / `consumers` / `story`。
- Module は概念としては残るが、独立データ型にはしない（コードのディレクトリ構造から導出する）。

## 5. 既存リポのオンボーディング方針

Story/Contract は **As-Is をそのまま写す**。密結合な repo でも正直に写す。
**先に疎結合化する必要はない。** 疎結合は目標であって前提ではない。
Bootstrap で As-Is を写す → 結合の絡まりが見える化される → 「ここを疎結合にする」が普通の Issue になる。

## 6. PO UX の方向（一部は後回し）

PO は基本 Iris とだけ話す。望み:
- **超並列**で開発を流す
- **徹底レビュー**（構造化 spec が客観的な判定基準を与える）

ただし「超並列」「徹底レビュー」は **基本ループが動いてから上に載せる**。先に設計しない。

VibeFlow の Human Checkpoint (Step 7a) は普段スキップされる（小さい PR は auto_pass）。
→ **「Spec が変わった PR は必ず Checkpoint を通す」ルールを足す**必要がある。

## 7. ケース構造（紙で全部設計しない）

- 入口 2 つ: ① 新規リポに VibeFlow インストール / ② 既存リポにインストール（Bootstrap）
- 運用 3 つ: 新規開発 / バグ改修 / 新規機能追加
- オンボーディング後の運用ループは共通。
- 5 ケースを紙で完璧に設計せず、1 サイクル実際に回して学ぶ。

## 8. Step プラン

- **Step 1**: vibeflow に `v6` ブランチを切る
- **Step 2**: 構造化 spec スキーマ（Story/Contract）の確定版を 1 ファイルで定義（slim、過剰な機械なし）
- **Step 3**: kickoff スキルを構造化 spec 対応にする（Interview → Story/Contract 生成、既存コードは Bootstrap）
- **Step 4**: Pneuma に VibeFlow を入れて 1 サイクル回す

## 9. やってはいけないこと

- ゼロから作り直さない。VibeFlow を進化させる
- PO に YAML / 構造化 spec を手書きさせない（PO が書くのは Vision、構造化 spec は Agent が書く）
- Dashboard / Cockpit を作らない
- akasha の過剰な機械（stake 軸 / drift CI / Decision Card インフラ / Atlas / Meta-Constitution の大仕掛け）を持ち込まない
- 5 ケースを紙で完璧設計しない

## 10. 関連リソース

- **VibeFlow リポ**: `/Users/kyohei/vibe/vibeflow`（v5.0.0, `main`）。
  未追跡の `package.json` / `package-lock.json` あり（Python コアのリポなので要確認、ただしブロッカーではない）。
  v5 構造: workflow は standard(10 step)/patch/spike/ops。Iris はコードを書かない。
  詳細は `core/schema/workflow.yaml`、`examples/.claude/rules/`。
- **Pneuma（テスト台）**: `/Users/kyohei/vibe/pneuma-core`。pre-Akasha 状態にリセット済み（pure Python ライブラリ）。
  models / emotion / memory / runtime / llm / storage / protocols とドメインが分かれていて整っている
  → Bootstrap が境界を拾いやすい易しいケース。
- **akasha リポ（凍結・参考資料、触らない）**: `/Users/kyohei/akasha`、`v2-rebuild` ブランチに設計ドキュメント:
  - `docs/v2-data-model.md` — Story/Contract 等のスキーマ案（slim 版の良い部分だけ使う）
  - `docs/v2-po-experience.md` — PO が触る 3 surface の体験シート
  - `docs/v2-interview-questions.md` — Vision Interview の質問構造（将来 Skill 化候補）
  - `docs/v2-plan.md` — 旧 Phase プラン（参考のみ）

## 11. 制約

- AI 時間は無制限（並列・夜通し OK）、人間時間は最小化（PO 介入は短く、各 30 分未満が目標）
- PO surface は Vision + 判断（Human Checkpoint で spec 差分を見る）+ Iris 会話 の 3 つ

## 12. 次にやること

**Step 1 から。** vibeflow に `v6` ブランチを切り、Step 2（構造化 spec スキーマの確定版を 1 ファイルで定義）に着手する。
