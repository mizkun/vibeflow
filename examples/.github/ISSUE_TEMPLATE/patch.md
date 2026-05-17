---
name: Patch
about: 軽微な修正（QAフィードバック・PRレビュー指摘・Step 7a修正）
labels: type:patch, workflow:patch
---

## Parent Issue / PR
- parent issue: #[番号]
- parent PR: #[番号 or なし]

## Problem
[何を修正する必要があるか]

## バグ改修分類
詳細は `.claude/rules/spec-loop.md`。1 つ選ぶ。
- [ ] (i) コード違反 — spec の invariant は正しい。コードだけ直す
- [ ] (ii) spec 誤り — invariant 自体が誤り。invariant も直す
- [ ] (iii) spec 欠落 — ルールが記録されていなかった。invariant を追加し test を付ける

## Scope
### 対象ファイル
- `[path]` - [修正内容]

### 対象テスト
- `[path]` - [検証内容]

## Fix Description
[修正方針の概要]

## Acceptance Criteria
- [ ] 修正が正しく適用されている
- [ ] 対象テストが通る
- [ ] 既存テストが壊れていない

## Notes
- 発見元: [Step 7a / QA report / PR review / etc.]
