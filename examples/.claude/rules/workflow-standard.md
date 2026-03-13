# Standard Workflow — 11 Steps

v5 では Iris が自動的にワークフローを進行します。ユーザーは Iris に指示するだけです。

## Steps

| Step | Description | Agent |
|------|------------|-------|
| 1. Issue Review | Issue の内容確認・要件整理・UI task 判定 | Iris |
| 2. Task Breakdown | タスク分解・計画策定 | Iris |
| 3. Branch Creation | feature branch 作成 | Coding Agent |
| 4. Test Writing | TDD: テスト先行で作成（UI task は Playwright E2E も） | Coding Agent |
| 5. Implementation | テストをパスする実装 | Coding Agent |
| 6. Refactoring | コード品質の改善 | Coding Agent |
| 7. Acceptance Test | テスト実行・結果検証（UI task は Playwright 必須） | Iris (QA) |
| 7a. Human Checkpoint | 必要な場合のみ人間確認 | Human |
| 8. PR Creation | Pull Request 作成 | Coding Agent |
| 9. Cross-Review | 別 agent によるコードレビュー | Review Agent |
| 10. Merge | PR マージ | Iris |
| 11. Close | Issue クローズ・状態更新 | Iris |

## Step 1: UI Task 判定

Iris は Issue Review 時に以下を判定する:

1. **UI task か否か**: 変更対象に UI ファイルが含まれるか、Issue に UI キーワードがあるか
2. UI task と判定した場合:
   - `qa:manual` ラベルを付与（原則）
   - Step 4 で Playwright テスト作成を必須化
   - Step 7 で Playwright 実行を必須化

判定基準の詳細は `rules/playwright.md` を参照。

## Step 4: Test Writing — AC-Test Binding

テストを先に書く。実装は書かない。

**AC-Test Binding ルール（必須）:**
- 各 Acceptance Criteria に対して **最低 1 つのテスト** を書くこと
- テストのコメントまたは describe/it に **AC 番号を明記** すること（例: `// AC-3: CIT → フレーム確認の順で進行する`）
- AC を検証しないユーティリティ単体テストだけでは **不十分**。AC の振る舞いを検証する結合テストが必要
- Step 5 完了時に「全 AC に対応するテストが GREEN」であることを確認

AC のないテストだけで「TDD やった」と言うことは禁止。

## Step 5: Implementation — 統合確認チェックリスト

テストをパスする最小限の実装を書く。

**Step 5 完了条件（全て満たすこと）:**
- [ ] 新規作成したモジュールが、対象コードから **実際に呼び出されている**（import だけで未使用は NG）
- [ ] AC のテストが **全て GREEN**
- [ ] `import` + `eslint-disable` の組み合わせがない（未使用 import を黙らせる行為の禁止）
- [ ] lint-disable / type-ignore は一時的な回避策として使わない。コードを修正して解決する

## Step 7: Acceptance Test — AC チェックリスト必須

### QA レポートフォーマット（必須）

Step 7 では以下のフォーマットで AC チェックリストを作成する:

```
📋 QA レポート — Issue #<NUMBER>
━━━━━━━━━━━━━━━━━━━

## AC チェックリスト
- [x] AC-1: <内容> → テスト名: <対応テスト>
- [ ] AC-2: <内容> → ❌ 未達成（理由: ...）
- [x] AC-3: <内容> → テスト名: <対応テスト>

## テスト結果
<テスト実行結果のサマリ>

## verdict: pass / fail
```

**1 つでも AC が未達成なら Step 4 に戻る。例外なし。**
AC を削除・縮小する場合は Issue 本文を更新し、理由をコメントすること。

### 非 UI task
- ユニットテスト + インテグレーションテスト全 PASS を確認

### UI task（Playwright 必須）
1. `bash scripts/playwright_smoke.sh` で E2E テスト実行
2. 必須 artifact の存在を確認（Playwright test / trace / screenshot / exploratory log のうち 1 つ以上）
3. E2E テスト FAIL → verdict は `fail`、coding agent に修正を再 dispatch

## Step 7a 判断基準

### 人間チェック不要 (auto_pass)
- 全テスト PASS + クロスレビュー PASS
- diff が小さい (files ≤ 5, lines ≤ 200)
- `type:fix` or `type:chore` + `risk:low`
- **UI task ではない**

### 人間チェック必要 (needs_human)
- **UI task**（UI 変更は原則 needs_human）
- `risk:high`
- `qa:manual`
- セキュリティ関連
- 3 回目のリトライ

## Step 9: Cross-Review — warn 対応の義務化

レビュー結果による対応:

| verdict | アクション |
|---------|-----------|
| `pass` | → Step 10 へ |
| `warn` | → **各指摘に対して「修正」か「対応不要の技術的理由」を記録** してから Step 10 へ。`eslint-disable` や `// TODO` で先送りすることは禁止。warn を全て解消するか、技術的理由を明記すること |
| `fail` | → Step 4 に戻ってリトライ |

**禁止事項:**
- レビュー指摘を `eslint-disable` / `@ts-ignore` / `// TODO` で握りつぶすこと
- 「軽微だから」という理由で warn を無視すること
- 未使用 import の指摘に対して disable コメントで対応すること（コードを削除して対応）

## TDD Enforcement

Step 4→5→6 は必ず TDD (Red-Green-Refactor) で実行:
1. テストを先に書く (Red)（UI task は Playwright E2E テストも含む）
2. テストをパスする実装 (Green)
3. リファクタリング (Refactor)
