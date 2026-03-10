---
name: vibeflow-execute-all
description: Execute all open GitHub Issues in dependency order. Iris picks up Issues one by one, runs the 11-Step workflow for each, and reports progress.
---

# 全 Issue 一括実行

## 使い方

```
/execute-all
```

Iris が open な Issue を依存順に並べ、1 つずつ 11-Step ワークフロー (`/execute-issue`) で完遂します。

---

## 手順

### 1. Open Issue 一覧を取得

```bash
gh issue list --state open --json number,title,body,labels --limit 100
```

### 2. 依存関係を分析して実行順序を決定

```bash
python3 -c "
import sys, json
sys.path.insert(0, '.')
from core.runtime.dependency_analyzer import analyze, execution_order

issues = json.loads('''$(gh issue list --state open --json number,title,body,labels --limit 100)''')
result = analyze(issues)

print('=== 実行バッチ ===')
for i, batch in enumerate(result['batches'], 1):
    nums = ', '.join(f'#{n}' for n in batch)
    print(f'  Batch {i}: {nums}')

if result['warnings']:
    print('⚠️ 警告:')
    for w in result['warnings']:
        print(f'  {w}')

ordered = execution_order(issues)
print('\\n=== 実行順序 ===')
for issue in ordered:
    print(f'  #{issue[\"number\"]}: {issue[\"title\"]}')
"
```

### 3. ユーザーに実行計画を提示

```
📋 実行計画
━━━━━━━━━━━━━━━━━━━━━
Open Issues: N 件

実行順序:
  1. #10: ○○機能の追加
  2. #11: △△のリファクタリング
  3. #12: □□バグ修正 (depends on #10)
  ...

この順序で実行します。よろしいですか？
```

### 4. Issue を順次実行

各 Issue に対して `/execute-issue <NUMBER>` を実行:

```
for each issue in execution_order:
    /execute-issue <issue.number>
```

- 各 Issue 完了後に進捗を報告
- `needs_human` の場合のみユーザーに確認を求める
- Issue が fail して 3 回リトライしても解決しない場合 → スキップしてユーザーに報告、次の Issue へ

### 5. 完了サマリを報告

全 Issue 完了後（またはスキップ含む完了後）:

```
📊 実行結果サマリ
━━━━━━━━━━━━━━━━━━━━━
完了: X 件
スキップ: Y 件
残り: Z 件

完了した Issue:
  ✅ #10: ○○機能の追加 (PR #15)
  ✅ #11: △△のリファクタリング (PR #16)

スキップした Issue:
  ⚠️ #12: □□バグ修正 — テスト失敗（3回リトライ済み）

次のアクション:
  - スキップした Issue について相談してください
```

---

## 中断と再開

- ユーザーが途中で止めたい場合 → 現在の Issue を完了後に停止
- 再開時は `/execute-all` を再実行 → 完了済み（closed）Issue はスキップされる

## 注意事項

- 依存関係のある Issue は、依存先が完了してから実行
- 循環依存がある場合は警告を出し、ユーザーに判断を仰ぐ
- 大量の Issue（10件以上）がある場合は、バッチごとに進捗を報告
