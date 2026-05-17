---
name: Standard Issue
about: 通常の開発タスク（機能追加・バグ修正・リファクタリング）
labels: type:dev, workflow:standard
---

## Overview
[1-2文で概要を記述]

## Background
[このタスクが必要な背景・理由]

## Spec 変更（Issue = Spec 差分）
- 対象 Story / Contract: [`.vibe/spec/...` / spec 変更なし（コードのみ）]
- As-Is → To-Be: [今の仕様 → 変更後の仕様の要約]
- バグ修正の場合の分類: [(i) コード違反 / (ii) spec 誤り / (iii) spec 欠落 → invariant 追加]
  ※ 詳細は `.claude/rules/spec-loop.md`

## Acceptance Criteria
- [ ] 具体的・テスト可能な基準1
- [ ] 具体的・テスト可能な基準2
- [ ] 具体的・テスト可能な基準3

## File Locations
- `src/[path]` - [説明]
- `tests/[path]` - [説明]

## Testing Requirements
- ユニットテスト: [必要なテスト]
- 統合テスト: [該当する場合]
- E2Eテスト: [該当する場合]

## Risk Assessment
- risk: [low / medium / high]
- 理由: [リスク判定の根拠]

## Dependencies
- 依存: [他のIssue]
- ブロック: [このIssueに依存するIssue]
