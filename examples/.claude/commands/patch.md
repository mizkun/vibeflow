---
description: Start Patch Loop for a parent Issue
---

# Patch Loop を開始する

IMPORTANT: 親 Issue 番号が必須です。`/patch <issue番号>` の形式で呼び出してください。
IMPORTANT: 対象テストの指定が必須です。テストを指定できない修正は Standard Issue を検討してください。

## 使い方

```
/patch <issue番号>
```

例: `/patch 42` — Issue #42 に紐づく軽微修正を開始

## 前提条件

1. **親 Issue が必須**: Patch Loop は standalone では動作しません。必ず親 Issue を指定してください
2. **対象テストが必須**: 修正対象のテストファイルを指定してください。テストがない場合は先にテストを書くか、Standard Issue に切り替えてください
3. **スコープは小さく**: Patch Loop は軽微修正専用です。大きな変更は Standard Issue に昇格してください

## 処理フロー

### Step 1: Scope Review
1. `gh issue view <issue番号>` で親 Issue を確認
2. 関連 PR があれば自動検出する
3. 修正対象のファイルとテストをユーザーと確認
4. ファイル数が上限（10）を超える場合は Standard Issue への昇格を提案

### Step 2: Fix Implementation
1. Engineer ロールで修正を実施
2. 対象ファイルのみを編集（スコープ外のファイルは触らない）
3. 大きな仕様変更が必要になった場合は停止し、Standard Issue への昇格を提案

### Step 3: Targeted Test
1. 指定されたテストのみを実行
2. テストが通らない場合は Step 2 に戻る
3. 全テストパスを確認

### Step 4: Commit
1. 修正内容をコミット
2. 親 Issue / PR にコメントで報告
3. Patch Loop を完了

## エスカレーション

以下の場合は Patch Loop を中断し、Standard Issue への昇格を提案してください:

- 対象ファイルが 10 個を超える
- 大きな仕様変更が必要
- 新しい依存関係の追加が必要
- テストの大幅な書き換えが必要

エスカレーション時は:
1. 現在の変更を stash またはブランチに保存
2. Standard Issue を作成するよう案内
3. Patch Loop のステータスを `escalated` に更新

## 制約

- 親 Issue / PR が必須（standalone の修正は不可）
- 対象テストの指定が必須
- 大きな仕様変更は禁止（必要なら Standard Issue に昇格）
- Safety Rules は適用される
- ファイル数上限: 10
