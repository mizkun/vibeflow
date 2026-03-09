---
description: Start Patch Loop (compatibility alias for /patch)
---

# Patch Loop を開始する（/quickfix は /patch の互換 alias）

IMPORTANT: `/quickfix` は Patch Loop の互換 alias です。今後は `/patch` の使用を推奨します。
IMPORTANT: Patch Loop は親 Issue が必須です。引数で Issue 番号を指定してください。Issue 番号なしで呼ばれた場合は、親 Issue を指定するよう案内してください。

## 処理フロー

### 1. 状態確認
`.vibe/state.yaml` を読み込み、現在の phase を確認する。
- `quickfix` の場合: 「既に Quick Fix モード中です」と表示
- `discovery` の場合: 「Iris セッション中です。先に /conclude してください」と表示

### 2. コンテキスト読み込み
1. `.vibe/context/STATUS.md` を読み込み、プロジェクトの現状を把握
2. `spec.md` で技術仕様を確認
3. 対象領域のソースコードを確認

### 3. モード開始
1. **Phase 切り替え**: `phase: quickfix` に更新
2. **Role 切り替え**: `current_role: "Engineer"` に更新
3. **current_step**: `null` のまま（ステップワークフロー不使用）
4. **Quickfix 更新**:
   - `quickfix.active: true`
   - `quickfix.description: [引数またはユーザーの説明]`
   - `quickfix.started: [今日の日付]`
5. **バナー表示**:
   ```
   ========================================
   🔧 QUICK FIX MODE
   [説明があれば表示]
   Ready for: 探索的な変更（UI調整・アルゴリズム調整など）
   ========================================
   ```

### 4. モード中の動作

#### ワークフロー
Issue 不要、11 ステップ不要。ユーザーの指示に直接対応する:

```
ユーザー: 「ここの色変えて」
AI: (変更実行、結果を報告)
ユーザー: 「いいね、あとここのマージンも」
AI: (変更実行)
ユーザー: 「やっぱ戻して」
AI: (リバート)
ユーザー: 「OK、コミットして」
AI: (コミット作成、Quick Fix モード終了)
```

#### ルール
- **直接対話**: ユーザーの指示に即座に対応する
- **リバート対応**: 「戻して」と言われたら即座にリバートできるようにする
- **Safety Rules は適用**: UI/CSS atomic commit、破壊的操作確認など
- **src/ への書き込み可**: Engineer ロールと同じ Write scope
- **plan.md / vision.md / spec.md への書き込み不可**

#### 終了条件
ユーザーが満足を表明したら（「コミットして」「OK これで」など）:
1. 変更内容をまとめた atomic commit を作成
2. state.yaml を復帰:
   - `phase: development`
   - `current_role: "Iris"`
   - `quickfix.active: false`
3. 完了バナー表示:
   ```
   ========================================
   ✅ QUICK FIX COMPLETE
   Changes: [変更したファイルリスト]
   Commit: [コミットハッシュ]
   Returning to: Development Phase
   ========================================
   ```
