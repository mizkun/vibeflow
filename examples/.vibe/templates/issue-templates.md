# Issue Template

## Overview
[1-2 sentence description of the task]

## Spec 変更（Issue = Spec 差分）
この Issue が動かす構造化 spec を記述する。詳細は `.claude/rules/spec-loop.md`。
- 対象 Story / Contract: [`.vibe/spec/stories/<id>.yaml` など / spec 変更なし]
- As-Is → To-Be: [今の仕様 → 変更後の仕様の要約]
- バグ改修の場合の分類: [(i) コード違反 / (ii) spec 誤り / (iii) spec 欠落 → invariant 追加 / 該当なし]

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

## Acceptance Criteria
- [ ] Criterion 1 (specific, testable)
- [ ] Criterion 2 (specific, testable)
- [ ] Criterion 3 (specific, testable)

## Technical Details
- Implementation approach: [description]
- Key components affected: [list]
- API changes: [if any]

## File Locations
- `src/[path]` - [description]
- `tests/[path]` - [description]

## Testing Requirements
- Unit tests: [specific tests needed]
- Integration tests: [if applicable]
- E2E tests: [if applicable]

## Dependencies
- Depends on: [other issues or external deps]
- Blocks: [issues that depend on this]

## Non-goals (optional)
- [What is explicitly out of scope]

## Implementation Plan
（Engineer が Step 4 開始時にここに記述）
- 対象ファイル: [src/..., tests/...]
- テスト対象: [tests/...]
- 依存 issue: [なし / Issue-XXX]
- 並列実行可否: [可 / 不可（理由: ...）]

## Progress
- [ ] テスト作成
- [ ] 実装
- [ ] リファクタリング

