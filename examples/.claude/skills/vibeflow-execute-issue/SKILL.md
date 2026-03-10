---
name: vibeflow-execute-issue
description: Execute a single GitHub Issue through the full 11-Step workflow. Iris handles everything — Issue Review, TDD, implementation, QA judgment, PR, cross-review, merge, close.
---

# Issue 実行 — 11-Step ワークフロー

## 使い方

```
/execute-issue <Issue番号>
```

Iris が 1 つの Issue を 11 Step で完遂します。ユーザーは `needs_human` の場合のみ確認を求められます。

---

## Step 1: Issue Review（Iris）

```bash
gh issue view <NUMBER> --json number,title,body,labels
```

1. Issue の内容を読み、要件を整理する
2. **UI task 判定**: 以下に該当するか確認
   - 変更対象に UI ファイル (`.tsx`, `.jsx`, `.vue`, `.svelte`, `.html`, `.css`, `.scss`) を含む
   - Issue タイトル/本文に UI キーワード（画面、表示、UI、デザイン、コンポーネント等）がある
3. ラベル確認: `risk:low/medium/high`, `qa:auto/manual`, `type:dev/fix/patch`
4. UI task の場合: `qa:manual` ラベルを付与（未付与なら）

```bash
# UI task の場合
gh issue edit <NUMBER> --add-label "qa:manual"
```

## Step 2: Task Breakdown（Iris）

1. Acceptance Criteria を明確化
2. 必要なファイル・テストを洗い出す
3. 実装方針を決定

## Step 3: Branch Creation

```bash
git checkout -b vf/issue-<NUMBER>
```

## ── ロール切替: Iris → Coding Agent ──

**state.yaml の `current_role` を切り替える:**

```bash
mkdir -p .vibe
cat > .vibe/state.yaml << 'YAML'
current_role: "Coding Agent (Claude Code / Codex)"
current_issue: "<NUMBER>"
current_step: "4_test_writing"
YAML
```

これにより `validate_access.py` が `src/*`, `tests/*` への書き込みを許可します。

## Step 4: Test Writing — TDD Red（Coding Agent）

**テストを先に書く。実装は書かない。**

1. acceptance criteria からテストケースを作成
2. ユニットテスト: `tests/` または `src/**/__tests__/`
3. UI task の場合: Playwright E2E テスト (`tests/e2e/`) も作成
4. テスト実行 → **全て失敗することを確認** (Red)

```bash
# テスト実行（プロジェクトに応じて）
npm test || pytest || bash tests/run_tests.sh
```

5. コミット: `test: add failing tests for #<NUMBER>`

## Step 5: Implementation — TDD Green（Coding Agent）

1. テストをパスする**最小限の**実装を書く
2. テスト実行 → **全て通ることを確認** (Green)
3. テストは変更しない
4. コミット: `feat: implement #<NUMBER>`

## Step 6: Refactoring（Coding Agent）

1. コード品質の改善（重複排除、命名改善等）
2. テスト実行 → **GREEN を維持**
3. 必要な場合のみコミット: `refactor: improve #<NUMBER>`

## ── ロール切替: Coding Agent → Iris ──

```bash
cat > .vibe/state.yaml << 'YAML'
current_role: "Iris"
current_issue: "<NUMBER>"
current_step: "7_acceptance_test"
YAML
```

## Step 7: QA 判定（Iris）

### 7-1. テスト全実行

```bash
npm test || pytest || bash tests/run_tests.sh
```

### 7-2. UI task の場合: Playwright 実行

```bash
bash scripts/playwright_smoke.sh
```

### 7-3. qa_judge で自動判定

```bash
python3 -c "
import sys, json
sys.path.insert(0, '.')
from core.runtime.qa_judge import judge, is_ui_task

context = {
    'labels': $(gh issue view <NUMBER> --json labels --jq '[.labels[].name]'),
    'tests_passed': True,  # ← 7-1 の結果
    'review_verdict': 'pass',  # ← 初回は仮 pass
    'files_changed': $(git diff --stat main...HEAD | tail -1 | grep -oE '[0-9]+ file' | grep -oE '[0-9]+'),
    'lines_changed': $(git diff --shortstat main...HEAD | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+'),
    'has_ui_changes': $(# UI ファイルの有無),
    'playwright_passed': $(# Playwright の結果),
    'has_playwright_artifact': $(# artifact の有無),
}
result = judge(context)
print(json.dumps(result, indent=2))
"
```

### 判定結果による分岐

| verdict | アクション |
|---------|-----------|
| `auto_pass` | → Step 8 へ（人間チェック不要） |
| `needs_human` | → Step 7a へ |
| `fail` | → Step 4 に戻ってリトライ（最大 3 回） |

## Step 7a: Human Checkpoint（必要な場合のみ）

**`needs_human` の場合、ユーザーに確認を求める:**

1. テスト結果のサマリを表示
2. diff の概要を表示
3. UI task の場合: スクリーンショットを提示
4. **ユーザーの OK を待つ**

```
📋 QA レポート — Issue #<NUMBER>
━━━━━━━━━━━━━━━━━━━━━
テスト: ✅ 全 PASS
diff: X files, Y lines
理由: <qa_judge の reason>

確認をお願いします。OK / NG を教えてください。
```

5. OK の場合: checkpoint 作成

```bash
mkdir -p .vibe/checkpoints
echo "approved" > .vibe/checkpoints/<NUMBER>-qa-approved
```

6. NG の場合: フィードバックを反映して Step 4 に戻る

**注意**: アルゴリズム変更やデータ構造作成など、目視確認が不可能な場合は `qa:auto` ラベルが付いているはずなので、このステップはスキップされます。

## Step 8: PR Creation

```bash
gh pr create \
  --title "feat: <Issue タイトルの要約>" \
  --body "Closes #<NUMBER>

## Summary
- <変更内容>

## Test Plan
- [x] Unit tests
- [x] Integration tests$(# UI task なら)
- [x] Playwright E2E tests"
```

`validate_step7a.py` が checkpoint をチェックし、未承認なら PR 作成をブロックします。

## Step 9: Cross-Review（Iris がサブエージェントに依頼）

```bash
# diff を取得
DIFF=$(git diff main...HEAD)
```

Iris は Agent tool を使ってクロスレビュー用サブエージェントを起動:

```
Agent tool で code-reviewer サブエージェントを起動:
- diff を渡す
- acceptance criteria を渡す
- verdict: pass / warn / fail を返してもらう
```

レビュー結果が `fail` の場合 → Step 4 に戻ってリトライ（最大 3 回）

## Step 10: Merge（Iris）

```bash
gh pr merge --squash --delete-branch
```

## Step 11: Close & Report（Iris）

```bash
gh issue close <NUMBER>
```

state.yaml を更新:

```bash
cat > .vibe/state.yaml << 'YAML'
current_role: "Iris"
current_issue: null
current_step: "idle"
YAML
```

ユーザーに完了報告:

```
✅ Issue #<NUMBER> 完了
━━━━━━━━━━━━━━━━━━━━━
Agent: Claude Code
PR: #<PR_NUMBER>
テスト: ✅
レビュー: ✅ (pass)
```

---

## リトライポリシー

- テスト失敗 or レビュー fail → Step 4 に戻る
- **最大 3 回**まで自動リトライ
- 3 回失敗したら `needs_human` としてユーザーに相談

## エラーハンドリング

- ブランチ競合 → `git rebase main` で解決を試みる
- テストが不安定 → 2 回実行して確認
- 予期しないエラー → ユーザーに状況を報告して判断を仰ぐ
