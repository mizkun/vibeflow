---
name: vibeflow-conclude
description: Conclude Iris session and update STATUS.md. Use when ending a Discovery session and returning to development phase.
---

# VibeFlow Session Conclude

## When to Use
- When ending a Discovery (Spike workflow) session
- When wrapping up a brainstorming discussion
- When ready to return to development phase

## Instructions

### 処理フロー

#### 1. 状態確認
`.vibe/project_state.yaml` を読み込み、`current_phase` が `discovery` であることを確認する。
- `discovery` でない場合: 「現在セッション中ではありません」と表示

> **Note**: `.vibe/state.yaml` が存在する場合は旧形式の fallback として参照してもよいが、正本は `project_state.yaml` + `sessions/*.yaml` です。

#### 2. セッション成果のまとめ
セッション中の活動を振り返り、以下を整理:
- 作成・更新した GitHub Issues
- vision.md / spec.md / plan.md への変更
- 重要な意思決定事項
- references/ に保存した情報

#### 3. STATUS.md 更新
`.vibe/context/STATUS.md` を更新:
- Current Focus を最新化
- Active Issues を更新（`gh issue list --state open`）
- Recent Decisions に新しい決定事項を追加
- Blockers があれば記録

#### 4. 必要に応じてアーカイブ
- references/ 内の古い情報を archive/ に移動
- archive/ のファイル名: `YYYY-MM-DD-type-topic.md`

#### 5. State 復帰
`.vibe/project_state.yaml`:
```yaml
current_phase: development
```

`.vibe/sessions/iris-main.yaml` は変更不要（Iris セッションは常駐）。

#### 6. 完了バナー表示
```
========================================
SESSION COMPLETE
Changes:
- Issues created/updated: N
- Documents updated: [list]
- STATUS.md: Updated
Returning to: Development Phase
========================================
```

## State 更新の対象

| ファイル | フィールド | 値 |
|---------|-----------|-----|
| `.vibe/project_state.yaml` | `current_phase` | `development` |

## Examples
- "セッションを終了して開発に戻る"
- "/conclude"
