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

## Step 7: QA 判定（Iris）— 暫定トリアージ

**確定判定は Step 9.5（クロスレビュー後）で行う。** Step 7 は「テストが
本当に通っているか」と「人間確認が必要な種類の変更か」のトリアージ。

### 7-1. テスト全実行 — 証拠を残す

テスト出力と exit code を**ファイルに保存する**（qa_judge はこの証拠
ファイルを検証する。会話内の「通りました」という主張は証拠にならない）:

```bash
mkdir -p .vibe/reports/<NUMBER>
(npm test || pytest || bash tests/run_tests.sh) 2>&1 | tee .vibe/reports/<NUMBER>/test.log
echo "${PIPESTATUS[0]}" > .vibe/reports/<NUMBER>/test.exit
```

### 7-2. UI task の場合: Playwright 実行

```bash
bash scripts/playwright_smoke.sh
```

### 7-3. qa_judge で暫定判定

以下の情報を集めて `qa_judge.judge()` を呼ぶ:

```python
# Iris が Python で実行する（.vibe/runtime/ にモジュールがある）
import sys, json
sys.path.insert(0, '.vibe/runtime')
from qa_judge import judge, is_ui_task

# 各値は Step 7-1, 7-2 の結果と git diff から取得
context = {
    'labels': ['type:dev', 'risk:low', 'qa:auto'],  # ← gh issue view で取得
    'tests_passed': True,       # ← 7-1 のテスト結果
    'review_verdict': 'pending',  # ← クロスレビューは Step 9。捏造しない
    'files_changed': 5,         # ← git diff --stat から算出
    'lines_changed': 120,       # ← git diff --shortstat から算出
    'has_ui_changes': False,    # ← UI ファイルの有無を確認
    'playwright_passed': None,  # ← UI task なら 7-2 の結果、非 UI なら None
    'has_playwright_artifact': False,  # ← artifact の有無
    'evidence': {               # ← 7-1 で保存した証拠ファイル
        'test_log': '.vibe/reports/<NUMBER>/test.log',
        'test_exit': '.vibe/reports/<NUMBER>/test.exit',
    },
}
result = judge(context)
# result['verdict']: 'auto_pass' | 'needs_human' | 'fail'
```

**値の取得方法:**
- `labels`: `gh issue view <NUMBER> --json labels --jq '[.labels[].name]'`
- `files_changed`: `git diff --stat main...HEAD | tail -1` からファイル数を抽出
- `lines_changed`: `git diff --shortstat main...HEAD` から行数を抽出
- `has_ui_changes`: 変更ファイルに `.tsx`, `.jsx`, `.vue`, `.css` 等が含まれるか
- `playwright_passed`: UI task なら `scripts/playwright_smoke.sh` の exit code
- `has_playwright_artifact`: `tests/e2e/` や `.vibe/artifacts/` にファイルがあるか

### 判定結果による分岐（暫定）

`review_verdict='pending'` のため、この時点で `auto_pass` は出ない（仕様）。

| 結果 | アクション |
|---------|-----------|
| `fail` | → Step 4 に戻ってリトライ（最大 3 回） |
| `needs_human`（理由が「review not executed」**のみ**） | → レビュー待ちの正常状態。Step 8 へ進む |
| `needs_human`（UI / risk:high / qa:manual / 大 diff 等を含む） | → Step 7a を先に通してから Step 8 へ |

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

**レビュー結果は必ず `.vibe/reports/<NUMBER>/review.md` に保存する**
（verdict と指摘一覧を含める）。Step 9.5 と Step 10 がこのファイルを参照する。

**失敗時の扱い（fail-closed）:**
- verdict `fail` → Step 4 に戻ってリトライ（最大 3 回）
- verdict `warn` → 各指摘に「修正」または「対応不要の技術的理由」を
  review.md に記録してから Step 9.5 へ（記録なしの warn は auto_pass 不可）
- サブエージェントの実行失敗・verdict 抽出不能 → レビューをリトライ。
  リトライ上限に達したら `needs_human` として PO にエスカレーション
  （壊れているのはコードではなくレビュー基盤なので、再実装はしない）

## Step 9.5: 確定判定（Iris）

クロスレビューの**実際の** verdict で qa_judge を再実行し、確定 verdict を得る。
`auto_pass` はこの確定判定でのみ成立する。

```python
import sys
sys.path.insert(0, '.vibe/runtime')
from qa_judge import judge

context = {
    # Step 7-3 と同じ値に、レビュー結果を反映:
    'review_verdict': 'pass',   # ← review.md の実 verdict（捏造禁止）
    'warn_responses_recorded': True,  # ← warn の場合、全指摘の対応記録があるか
    # evidence は Step 7-1 のファイルをそのまま渡す
    # ... 残りのキーは Step 7-3 と同じ
}
result = judge(context)
```

| 確定 verdict | アクション |
|---------|-----------|
| `auto_pass` | → Step 10 へ |
| `needs_human` | → Step 7a（未承認なら）→ 承認後 Step 10 へ |
| `fail` | → Step 4 に戻ってリトライ（最大 3 回） |

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

ユーザーに完了報告。**チェックマークだけの主張は禁止 — 証拠を添える:**

```
✅ Issue #<NUMBER> 完了
━━━━━━━━━━━━━━━━━━━━━
Agent: Claude Code
PR: #<PR_NUMBER>

テスト: <test.exit の値> — 実行コマンド: <Step 7-1 で使ったコマンド>
  <test.log の末尾サマリ（例: "All 42 tests passed"）>
  ログ: .vibe/reports/<NUMBER>/test.log
レビュー: <review.md の verdict>（指摘 N 件 / 対応記録あり）
  レビュー: .vibe/reports/<NUMBER>/review.md
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
