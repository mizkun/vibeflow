# Patch Loop Workflow

QA フィードバック・レビュー指摘など、親 Issue に紐づく軽微修正のための 4 Step ワークフロー。

## Steps

| Step | Description |
|------|------------|
| 1. Scope Review | 対象ファイル・テストの確認 |
| 2. Fix Implementation | 限定スコープで修正 |
| 3. Targeted Test | 対象テストのみ再実行 |
| 4. Commit | 修正をコミット |

## 制約

- 親 Issue / PR が必須
- 対象ファイル数に上限あり
- 大きな仕様変更は禁止（Standard Issue に昇格）
- Safety Rules は適用
