---
description: Conclude Iris session and update STATUS.md
---

# Iris セッションを終了する

`/conclude` でセッションの成果をまとめ、STATUS.md を更新して開発フェーズに戻ります。

## 処理フロー

### 1. 状態確認
`.vibe/state.yaml` を読み込み、phase が `discovery` であることを確認する。
- `discovery` でない場合: 「現在セッション中ではありません」と表示

### 2. セッション成果のまとめ
セッション中の活動を振り返り、以下を整理:
- 作成・更新した GitHub Issues
- vision.md / spec.md / plan.md への変更
- 重要な意思決定事項
- references/ に保存した情報

### 3. STATUS.md 更新
`.vibe/context/STATUS.md` を更新:
- Current Focus を最新化
- Active Issues を更新（`gh issue list --state open`）
- Recent Decisions に新しい決定事項を追加
- Blockers があれば記録

### 4. 必要に応じてアーカイブ
- references/ 内の古い情報を archive/ に移動
- archive/ のファイル名: `YYYY-MM-DD-type-topic.md`

### 5. Phase 復帰
```yaml
phase: development
current_role: "Iris"
discovery:
  active: false
  last_session: "YYYY-MM-DD"
```

### 6. 完了バナー表示
```
========================================
✅ SESSION COMPLETE
Changes:
- Issues created/updated: N
- Documents updated: [list]
- STATUS.md: Updated
Returning to: Development Phase
========================================
```
