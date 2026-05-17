# Spec Loop — v6 構造化 spec

VibeFlow v6 の中核ルール。プロジェクトの仕様は構造化 spec（Story / Contract）で
表現し、コードと 1:1 で対応させ続ける。緩い `spec.md` は使わない。

## spec の置き場所

- `.vibe/spec/stories/<id>.yaml` — 1 ドメイン 1 ファイル。不変条件 (invariants) を持つ
- `.vibe/spec/contracts/<id>.yaml` — モジュール間を渡るデータの形（host 言語の型を参照）
- スキーマ定義は VibeFlow framework の `core/schema/spec.yaml`
- spec は **Agent が書く**。PO は書かない（PO が書くのは Vision）

## ループモデル — Issue = Spec 差分

```
Iris と会話
  → Spec の As-Is（今のコードの仕様）と To-Be（変更後）を作る
  → As-Is → To-Be の差分 = Issue
  → TDD でコードを To-Be に合わせる → レビュー
  → マージ後、Spec の As-Is が To-Be に進む
```

- As-Is = base ブランチに commit 済みの spec ファイル群
- To-Be = Issue ブランチ上で編集した spec ファイル群
- `git diff(As-Is, To-Be)` が、そのまま Issue の中身になる
- 大きな Spec 変更は Plan（ロードマップ）も動かしうる → 同じ Issue 内で Plan も更新する

## バグ改修の 3 分類

バグに対応するとき、必ず以下のどれかに分類する。判定基準は
**「このバグに対応する invariant が spec にあるか？」**。

| 種別 | 状況 | 対応 |
|---|---|---|
| (i) コード違反 | spec の invariant は正しい。コードが違反している | To-Be == As-Is。**コードだけ直す** |
| (ii) spec 誤り | spec の invariant 自体が間違っていた | To-Be ≠ As-Is。**invariant も直す** + コード |
| (iii) spec 欠落 | そのルールが invariant としてどこにも記録されていなかった | To-Be = As-Is + 新 invariant。**invariant を追加し test を付ける** + コード |

**(iii) が最重要。** 「誰も記録していなかったルールを踏み抜いた」結果のバグは、
その場で invariant を Story に書き足す（できれば test も）。これをやらないと
同じバグを二度踏む。**spec を完成へ収束させるエンジンは (iii) である。**

Bootstrap 直後の spec は不完全（既存コードから拾える invariant は一部）。
運用の中で (iii) を積み重ねることで spec は使うほど賢くなる。

## 検証 — spec を厳格にする意味はここにある

構造化しただけでは drift する。検証フローが伴って初めて意味を持つ。

- **日常**: `vibeflow spec-verify`（HealthCheck #8）。spec とコードの drift
  （参照先の消失等）と pending invariant 数を検出する。
- **PR ごと**: Spec Gate。`.vibe/spec/` を変更した PR は Human Checkpoint
  （Step 7a）を必ず通る。`validate_step7a.py` hook で強制され、qa:auto では
  自動承認できない。詳細は `workflow-standard.md` の Step 7a 判断基準。
