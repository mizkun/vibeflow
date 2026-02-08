---
description: Conclude a discovery discussion and return to development
---

# 議論を終了し開発フェーズに戻る

`/conclude` で現在の Discovery Discussion を終了します。

## 処理フロー

### 1. 状態確認
`.vibe/state.yaml` を読み込み、phase が `discovery` であることを確認する。
- `discovery` でない場合: 「現在議論中ではありません」とエラー表示

### 2. 議論の要約
1. 現在の議論ファイル（`.vibe/discussions/DISC-XXX-*.md`）を読み込む
2. 議論内容を要約し、以下をまとめる:
   - **合意事項（Agreements）**: 議論で合意した内容
   - **未解決事項（Open Issues）**: まだ結論が出ていない論点
   - **結論（Conclusion）**: 議論全体の結論
   - **アクションアイテム**: vision.md / spec.md / plan.md への反映事項

### 3. ユーザー承認
要約とアクションアイテムをユーザーに提示し、承認を求める:
```
📋 議論の要約

## 合意事項
- [合意1]
- [合意2]

## アクションアイテム
- [ ] vision.md に [内容] を追記
- [ ] spec.md に [内容] を追記
- [ ] plan.md に [内容] を追記

この内容で反映してよろしいですか？
```

### 4. 承認後の反映
ユーザーが承認した場合:
1. **ロール遷移**: Product Manager に切り替え
2. **ファイル反映**: 承認されたアクションアイテムを各ファイルに反映
   - vision.md への追記・修正
   - spec.md への追記・修正
   - plan.md への追記・修正
3. **議論ファイル更新**: Status を `concluded` に変更、Conclusion セクションを記入

### 5. Phase 復帰
```yaml
phase: development
current_role: "Product Manager"
discovery:
  id: null
  started: null
  topic: null
  sessions: []
```

### 6. 完了バナー表示
```
========================================
✅ DISCOVERY COMPLETE
Topic: [トピック名]
Discussion ID: DISC-XXX
Agreements: N items
Action items applied: N items
Returning to: Development Phase
========================================
```

IMPORTANT: 反映は必ずユーザーの承認を得てから行う。承認がない場合はファイル変更を行わず、議論ファイルの Status のみ更新する。
