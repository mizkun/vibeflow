# VibeFlow v6 開発ガイド（状況別）

「いまこの状況だ」と思ったら、対応する節を読んでそのとおり進めれば良い、
という実務マニュアル。

---

## 0. 基本（全状況で共通）

- **PO は Iris と会話するだけ。** コードも YAML も書かない。PO が書くのは Vision。
- **仕様 = 構造化 spec。** `.vibe/spec/stories/`（Story）と `.vibe/spec/contracts/`
  （Contract）。**Story/Contract は Agent が書く。**
  - Story = 1 ドメインの不変条件 (invariants)。
  - Contract = ドメイン境界を渡るデータの形。
- **Issue = Spec 差分。** 今の仕様 (As-Is) と変更後 (To-Be) の差が Issue。
- **検証は 2 層:**
  - 日常 — `vibeflow spec-verify`（spec とコードの drift を検出）
  - PR ごと — Spec Gate（spec を変える PR は人間承認を必ず通る）

共通ループ:

```
Iris と会話
  → Spec の As-Is と To-Be を作る
  → 差分 = Issue
  → TDD でコードを To-Be に合わせる → レビュー
  → マージ後、As-Is が To-Be に進む
```

詳細ルールは `.claude/rules/spec-loop.md`。

---

## 状況1: 新しいプロジェクトを始める

コードがまだ無い。ゼロから作る。

1. プロジェクトディレクトリで `vibeflow setup` を実行。
2. Iris に「プロジェクトを始めたい」と話す → Iris が `vibeflow-kickoff` を実行。
3. Iris の Interview に答える → `vision.md`（なぜ・誰に・成功の定義）が出来る。
4. Iris が `plan.md`（ロードマップ）を作る。
5. **構造化 spec はまだ空。** 最初の機能を作る Issue の中で、その
   ドメインの Story がコードと一緒に生まれる（→ 状況3 へ）。

ポイント: 新規ではコードが無いので As-Is spec は空。空の Story を先に
作らない。spec はコードと共に育つ。

---

## 状況2: 既存のリポジトリに VibeFlow を入れる（Bootstrap）

コードはもうある。VibeFlow を後から導入する。

1. リポジトリで `vibeflow setup` を実行（既存ファイルは自動バックアップ）。
2. Iris に「VibeFlow を始めたい」と話す → Iris が `vibeflow-kickoff` を実行。
   コードがあって `.vibe/spec/` が無いので **Bootstrap モード**になる。
3. Iris（Agent）がコードを読み、**As-Is の Story/Contract を自動生成**する。
   - 1 ディレクトリ = 1 Story。invariants はコードから推定。
   - 密結合・汚いコードも**そのまま正直に写す**（先に直さない）。
4. `vibeflow spec-verify` で spec とコードの整合を確認（自動で実行される）。
5. Iris が報告: ドメイン一覧 / invariant 数 / pending（テスト未整備）数 /
   目立つ密結合。

ポイント:
- Bootstrap で出来る spec は**不完全だが正直**。テストの無い invariant は
  `pending` のまま記録される。それで良い。
- 密結合が spec で見える化される → 「ここを疎結合にする」が普通の Issue に
  なる。先にきれいにしようとしない。

---

## 状況3: 新しい機能を追加する

一番よく使う。「○○ができるようにしたい」。

1. Iris に「○○を作りたい」と話す。
2. Iris が **To-Be spec** を作る: どの Story/Contract が増える・変わるか。
3. As-Is → To-Be の差分が **Issue** になる（Spec 変更セクション付き）。
4. Coding Agent が TDD で実装（テスト先行 → 実装 → リファクタ）。
5. **Spec Gate**: spec を変更した PR なので、必ず Human Checkpoint を通る。
   Iris が As-Is → To-Be の差分を PO に提示 → PO が承認。
6. クロスレビュー → マージ。As-Is spec が To-Be に進む。

ポイント: 既存コードも触るので、既存の invariant を壊していないかを
Step 7 の検証とクロスレビューで必ず確認する（→ 壊していたら状況4へ）。

---

## 状況4: バグを直す

バグに当たったら、まず **3 分類のどれか**を判定する。判定基準は
「このバグに対応する invariant が spec にあるか？」。

| 種別 | 状況 | 対応 |
|---|---|---|
| (i) コード違反 | invariant は正しい。コードが違反 | コードだけ直す（To-Be == As-Is）|
| (ii) spec 誤り | invariant 自体が間違っていた | invariant も直す + コード |
| (iii) spec 欠落 | そのルールがどこにも記録されていなかった | **invariant を追加** + test + コード |

手順:
1. Iris にバグを報告。
2. Iris が 3 分類を判定。
3. (i) → Coding Agent がコードを修正。spec は変えない。
   (ii) → invariant を訂正し、コードも直す。spec 変更なので Spec Gate を通る。
   (iii) → **不足していた invariant を Story に書き足し、test を付け、コードを直す。**
4. TDD → レビュー → マージ。

ポイント: **(iii) が一番大事。** 「誰も書いていなかったルールを踏み抜いた」
バグは、その場で invariant を追加する。これをやらないと同じバグを二度踏む。
**spec を完成へ収束させるエンジンは (iii)。** Bootstrap 直後は spec が
不完全なので (iii) が多い。それが正常。

---

## 状況5: 既存機能を改修する

「動いてるけど○○の挙動を変えたい」。一番壊しやすい状況。

1. Iris に改修内容を話す。
2. Iris が To-Be spec を作る。**既存の invariant のどれが変わるか**を明示。
3. 差分 = Issue。
4. Coding Agent が TDD で実装。
5. **検証で「他の invariant を壊していないか」を必ず確認**:
   - 既存の invariant test が全て GREEN か。
   - Contract（データの形）を変えたなら、その consumer が壊れていないか。
6. spec 変更を含むので Spec Gate → Human Checkpoint → マージ。

ポイント: 改修で既存の不変条件を壊すのが「改修すると壊れる」の正体。
invariant test が壊れたら、それは想定どおりの変更か（→ invariant を更新）、
事故か（→ 直す）を必ず切り分ける。

---

## 日常メンテナンス: HealthCheck

週次・気づいたときに実行する。

- `vibeflow spec-verify`（または `/healthcheck`）を実行。
- **ERRORS が出たら** spec がコードから drift している（参照先が消えた等）→
  直す。
- **pending invariant 数**を見る。多いほど「構造化されているが未検証」の
  リスク。後続 Issue で test を付けて減らしていく（状況4 (iii) の蓄積）。

---

## 困ったとき

| 症状 | 意味 / 対処 |
|---|---|
| `spec-verify` が ERROR | spec とコードがズレた。spec を直すか、コードを直す |
| `gh pr create` が Spec Gate でブロック | spec を変更した PR。As-Is→To-Be 差分を PO に提示し、承認 checkpoint を作る |
| `vibeflow doctor` が warn/error | フレームワークファイルの不整合。`vibeflow generate` で再生成 |
| バグの 3 分類が判らない | spec に対応 invariant があるか grep。無ければ (iii) |

---

## 入口と運用の地図

```
  ┌─ 入口（1回だけ）──────────────┐
  │  状況1: 新規プロジェクト        │
  │  状況2: 既存リポに導入(Bootstrap)│
  └───────────┬──────────────────┘
              ▼
  ┌─ 運用（くり返す）────────────┐
  │  状況3: 新規機能追加           │
  │  状況4: バグ改修 (i)(ii)(iii)  │
  │  状況5: 既存機能の改修         │
  │  日常:  HealthCheck            │
  └──────────────────────────────┘
```

入口は一度だけ。あとは運用 3 状況 + 日常を回し続ける。
全状況で共通するのは「§0 の共通ループ」— Issue は常に Spec の差分。
