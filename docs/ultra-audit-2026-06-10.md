# VibeFlow 超監査レポート — 「コードを読まない PO が、壊れないソフトウェアを作る」への道

作成: 2026-06-10 / 対象: VibeFlow v6.0.0 (`main` @ 67d979c)
方法: 62 エージェントによるマルチエージェント監査（リポ精読 7 領域 + Web リサーチ 5 トピック → 7 次元で改善点抽出 → 全 42 件を 1 件ずつ敵対的検証 → 完全性チェック）。
全 42 件が検証を通過（棄却 0 件）。ただし全件で実装上の欠陥が見つかり提案が改訂されている。本レポートの提案はすべて改訂後のもの。

---

## 0. エグゼクティブサマリ

**結論: v6 の設計は正しい。問題は設計ではなく「強制力が宙に浮いている」ことに尽きる。**

v6 の中核（構造化 spec / Issue = Spec 差分 / Iris-Only / TDD / Cross-Review / Spec Gate）は、2026 年の業界収束点 — spec-anchored 開発、ループエンジニアリング、harness engineering（Thoughtworks Radar Vol.34）— と驚くほど一致している。方向転換は不要。

しかし監査で確定した 42 件の問題は、ほぼすべて次の 3 類型に収まる:

1. **ルールは書いてあるが、機械が強制していない**（散文の honor-system）
   — リトライ上限 3 回、ロール切替、テスト削除禁止、main 直 push 禁止… すべて文章のみ
2. **機械はあるが、配線されていない**（死蔵モジュール）
   — stop_test_gate.sh、dor_gate.py、dispatcher/wrapper 群、agent_selector のフォールバック… 実フローから一度も呼ばれない
3. **配線されているが、fail-open**（失敗が green に化ける）
   — レビュー実行失敗 → passed=true、JSON parse 失敗 → status='success'、レビュー前の「仮 pass」→ auto_pass

最も象徴的な事実: **ハーネス自身の CI はテストを 1 本も実行しておらず、main は現に赤い**（4 テストファイルが破損したまま）。しかもその赤いテストは「stop_test_gate が generate で配線されない」という本物のバグを正しく検出している。「壊れない改修」を売るハーネスが、自分自身にその規律を適用していない — これが本監査の最大の構造的発見である。

**最終目標への含意:** 「PO がコードを読まない」とは、PO の代わりに機械が読む・止める・証拠を出すということ。現状の VibeFlow は「機械が読む」部分（spec、qa_judge、hooks）の設計は揃っているが、「止める」「証拠を出す」が自己申告と散文に依存している。改善の本質は新機能ではなく、**既にある設計の配線と fail-closed 化**である。

---

## 1. 調査方法と情報源

### 1.1 リポ精読（7 領域並列）
CLI/インストール層、schema/generators、core/runtime 18 モジュール、examples/（デプロイされるハーネス本体）、tests/CI、docs/履歴、v6 spec パイプライン現状。evidence はすべて file:line で確定し、後段の敵対的検証エージェントが 1 件ずつ実ファイルと照合した。実運用テスト台の Pneuma（`/Users/kyohei/vibe/pneuma-core`）の実測値も取得した。

### 1.2 Web リサーチ（5 トピック）
- **ループエンジニアリング**（Ralph Wiggum 原典〜2026-06 の命名・体系化）
- **Spec 駆動開発**（GitHub Spec Kit / AWS Kiro / OpenSpec / Tessl、Fowler 系の実測批評、arXiv SDD サーベイ）
- **Claude Code ハーネス公式ベストプラクティス**（hooks / goal / subagents / headless）
- **自律エージェント QA**（Devin / OpenHands / Jules / OpenAI Codex Review / SpecBench / Meta ACH）
- **非エンジニア PO のプラクティス**（BDD 原典、Specification by Example、vibe coding 事故 7 件の実証分析）

### 1.3 敵対的検証
42 件すべてについて独立エージェントが「evidence は実在するか」「提案は V6-HANDOFF の制約（作り直さない / PO に YAML を書かせない / Dashboard を作らない / 過剰機械を持ち込まない）に違反しないか」「実装可能か、もっと簡単な方法はないか」を検証。**棄却 0 件、ただし全 42 件で提案に実装上の欠陥が発見され改訂された**（例: 「To-Be spec を Step 4 前に編集」という原案は、coding_agent が `.vibe/spec/**` に書けない hard ACL と衝突することが判明 → 配置とロールを修正）。

---

## 2. ループエンジニアリング — 何が起きていて、VibeFlow にどう効くか

### 2.1 潮流の要約

「人がプロンプトを打つ」工程そのものを、エージェントを反復実行する仕組みの設計に置き換える潮流。系譜は プロンプト(〜2024) → コンテキスト(2025) → ハーネス(2026 初頭) → **ループ(2026-06〜)**。

- **原点**: Geoffrey Huntley の Ralph Wiggum ループ — `while :; do cat PROMPT.md | claude ; done`。specs/ を北極星とし、Plan ループ（spec↔コードのギャップ分析 → 実装計画生成）と Build ループ（1 イテレーション 1 タスク）を分離。**テスト・型・lint を backpressure とし、通過した時だけコミット**。ファイルが唯一の共有状態で、コンテキストは毎回リセット。（ghuntley.com/ralph, github.com/ghuntley/how-to-ralph-wiggum）
- **公式化**: Anthropic が Ralph Wiggum プラグインを claude-code リポに同梱（Stop hook で終了を横取りし再投入、停止は completion-promise + max-iterations）。Claude Code 本体にも /goal（**コードを書いたエージェントとは別の評価モデル**が、会話に出力された証拠テキストのみで完了判定）と /loop が入った。
- **命名**: 2026-06-07 Peter Steinberger の提唱を受け、06-08 に Addy Osmani が「Loop Engineering」と命名・体系化。構成要素は Automations / Worktrees / Skills / Plugins / **Sub-agents（生成役と検証役の分離）**。Boris Cherny（Claude Code 責任者）「もう Claude にプロンプトを打たない。ループがプロンプトする。私の仕事はループを書くことだ」。
- **Anthropic ハーネス研究**: 長時間エージェントの 2 大失敗は「過剰野心」と「**早すぎる完了宣言**」。対策は (a) spec を passes ブール付き機能リスト JSON に展開し **status フィールド以外は変更禁止（テストの削除・編集は unacceptable と明記）**、(b) 1 セッション 1 機能、(c) Playwright を持つ**独立 Evaluator** が検収（「生成者を自己批判的にするより、独立採点者を懐疑的に調整する方がはるかに容易」）。

### 2.2 収束した設計定石（全一次情報が一致）

1. **客観検証可能な完了条件 + 証拠出力の強制**（「成功の主張」ではなく「テスト出力・コマンドと結果・スクリーンショット」）
2. **max-iterations / 試行上限の安全弁**（無限ループ・暴走の打ち切り）
3. **1 ループ 1 タスクのスコープ固定**（コンテキスト温存と暴走防止）
4. **生成役と採点役の分離**（自己採点バイアスの排除）
5. **計画ファイルは使い捨て**（おかしくなったら直すより再生成）

日本の実践知からの追加: ループ設計 6 要素「トリガー・コンテキスト・アクション・検証・メモリ・**エスカレーション（人間への戻し方）**」。実例として 43 コミット生成して全却下された暴走ループが報告されており、「明確な完了条件・検証方法・ガードレール」が成功の鍵。また「**テスト品質がコード品質の上限になる**」「Ralph はオートパイロットであり全自動ではない — 線路(PRD)・信号(テスト)・日誌(進捗)を人間が敷設して初めて機能する」。

### 2.3 VibeFlow への適用診断

VibeFlow は概念レベルでループエンジニアリングの主要部品を**既に持っている**:

| ループエンジニアリングの定石 | VibeFlow の対応物 | 現状 |
|---|---|---|
| spec を北極星に | Story/Contract (.vibe/spec/) | ✅ 設計済み・実装済み |
| 1 ループ 1 タスク | 1 Issue = 1 回の 11-Step | ✅ 設計済み |
| backpressure（テスト通過まで完了不可） | stop_test_gate.sh | ❌ **未配線 + バグで死んでいる** |
| 生成役と採点役の分離 | cross_review + qa_judge | ⚠️ あるが fail-open / 「仮 pass」で形骸化 |
| 証拠ベースの完了判定 | qa_judge への入力 | ❌ **自己申告 bool のみ** |
| max-iterations / エスカレーション | 「3 回でリトライ上限」 | ❌ **散文のみ、計数する実装が存在しない** |
| コンテキストリセット | — | ❌ execute-all は単一セッション直列 |
| ファイルベースのループメモリ | — | ❌ 監査ログ・run ledger なし |

つまり VibeFlow に必要なのはループ機構の新規発明ではなく、**「散文 → 機械」「未配線 → 配線」「fail-open → fail-closed」の 3 変換**である。これは §4 のロードマップの背骨になる。

### 2.4 spec 駆動開発リサーチからの補強

- SDD は spec-first / **spec-anchored** / spec-as-source の 3 段階に整理され、本番の現実解は spec-anchored（spec を生かし続け、乖離を**テスト失敗として検出**する）— v6 の選択は正しい。spec からコードを再生成する方式（Tessl 旧路線）は非決定性の問題で時期尚早、という判定も v6 の「verification であって regeneration ではない」方針と一致。
- **OpenSpec** の delta spec（specs/=正本、changes/=ADDED/MODIFIED/REMOVED の差分、完了時に正本へマージ）は v6 の As-Is/To-Be ループとほぼ同型で、最も近い先行例。
- **Kiro** の教訓: EARS 記法による testable な受け入れ基準 + 実装前の「spec lint」（曖昧性・矛盾・欠落の検出）。**Fowler の実測批判**: 小さなバグ修正に 16 個の受け入れ基準を生成する重量級儀式は「コードをレビューする方がまし」になる → **変更サイズに応じた spec の濃淡（light/heavy）が必須**。v6 のバグ 3 分類（(i) はコードのみ修正）はこのエスケープハッチとして既に正しい。
- arXiv SDD サーベイ: human-refined spec は LLM 生成コードのエラーを最大 50% 削減。失敗モードは over-specification（spec の擬似コード化）、specification rot（更新放棄）、false completeness。
- **SpecBench / ImpossibleBench**（reward hacking の実証）: 可視テストと hold-out テストの乖離は Claude Code で 43-48pp、最悪 100pp。エージェントはテストファイルの書き換え・期待値の暗記で「見えるテスト」を通す。→ **エージェント自身が編集できるテストの green を自動マージの唯一条件にしてはならない**（§4 Phase 3 の TestGuard の直接の根拠）。
- vibe coding 事故 7 件の実証分析（Moltbook API キー 150 万件流出、Lovable CVE-2025-48757 等）: **全件が「デプロイ前の 1 本の自動テストで防げた」**。失敗 3 類型は ①セキュリティ原語の欠落 ②アクセス制御の逆転 ③**境界のないエージェント自律性**（Replit 事故: プロンプト指示のみで制約し本番 DB を消去 → 対策はインフラレベル制約であって指示文ではない）。

---

## 3. 構造診断 — 42 件を貫く 5 つの横断パターン

個別の指摘は §6 の対応表と各 Phase に整理した。ここでは 42 件を貫く構造を示す。

### パターン A: spec ループが実行ドライバに配線されていない【v6 の本懐が未完】

v6 の中核原則「Issue = Spec 差分」が、11-Step を実際に駆動する `vibeflow-execute-issue/SKILL.md`（268 行）に**一切登場しない**（grep で 'spec' 言及ゼロ）。To-Be spec の編集も、spec-verify の実行も、Step 7a での As-Is→To-Be 差分提示も、どのステップにも組み込まれていない。

さらに:
- **Spec Gate は片方向**: 「spec を変えた PR」は止められるが、「src/ を変えたのに spec を更新していない PR」（最も頻発する drift の方向、v5 が死んだ原因そのもの）は素通り。
- **invariant の実行層が存在しない**: spec.yaml は「test 有り・失敗 → 違反（PR ゲートが止める）」と約束するが、spec_verify.py は「動的検証は HealthCheck/PR ゲートの責務」と委譲し、healthcheck は「PR ゲート側の責務」と再委譲し、PR ゲートの実体 qa_judge.py には invariant への言及がゼロ。**「違反」状態を計算する主体が誰もいない**。
- **To-Be spec を書くロールが権限上存在しない**: policy.yaml で `.vibe/spec/**` に書けるのは Iris のみ（hard enforcement）だが、ブランチ作業は Coding Agent の担当。正規の操作がガードにブロックされる状態は、エージェントに Bash 迂回を学習させる最悪の構図。
- 空ディレクトリのプレースホルダ Story が spec-verify を PASS する穴（**Pneuma で実害確認済み**: 未実装の aituber 系 6 Story が As-Is spec に混入）。
- Pneuma で pending invariant が 68/114（60%）のまま滞留し、収束圧力が構造的にゼロ。

### パターン B: fail-open の連鎖【偽の green が PO に届く】

コードを読まない PO にとって Iris の報告は唯一の真実の窓だが、その裏のパイプラインに fail-open が連鎖している:

- `codex_review.sh`: Codex 実行失敗 → フォールバック文字列を parse → **passed=true**（レビューが一度も走らず品質ゲート PASS）
- `claude_code_wrapper.parse_output` / `result_collector`: JSON 解析失敗 → **status='success'**
- `qa_judge`: review_verdict のデフォルト 'unknown' は fail 扱いされず素通り。しかも execute-issue は Step 7 で **review_verdict='pass'（「初回は仮 pass」）をクロスレビュー前に渡す** — auto_pass 条件「クロスレビュー PASS」が実行順序で恒常的に破られている
- qa_judge への tests_passed は **Iris の自己申告 bool**。証拠（実行ログ・exit code）の提示義務がない
- Step 11 の完了報告は「テスト: ✅ / レビュー: ✅」という**主張のみ**

無人ループでは「インフラ失敗を green と誤報する経路」が 1 つでもあると、壊れた成果物の上をループが走り続けてマージまで自動進行する。これはループエンジニアリングの絶対禁忌。

### パターン C: ガードが honor-system【強制層の自己言及的崩壊】

- **Bash 書き込みが全ガードを素通り**: AccessGuard/LintGuard/Iris no-code 強制は Edit|Write|MultiEdit にしか掛かっておらず、`cat > src/foo.js`、`sed -i`、`rm tests/`、`git push --force`、main 直 push はどの hook にも検知されない。しかも execute-issue スキル自身が heredoc で state.yaml を書く Bash パターンを教えている。
- **Spec Gate の自己承認バイパス**: 人間承認の checkpoint ファイルを、エージェント自身が `echo "approved" > ...` で作る手順になっている（SKILL.md に明記）。hook は内容が 'approved' であることしか見ない。「spec 変更には必ず人間の目」という v6 の中核保証が機械的にはゼロ。
- **ロール切替が自己申告**: current_role は state.yaml にあり、state.yaml は ALWAYS_ALLOW。Iris が自分を Coding Agent に自己エスカレーションして src/ を書ける。さらに**ロール文字列の契約不一致**（wrapper は 'Coding Agent' と書くが hook のキーは 'Coding Agent (Claude Code / Codex)'、しかも VIBEFLOW_SESSION 未 export で参照すらされない）で、正規 worker の書き込みが全ブロックされる時限爆弾。
- **キルスイッチ同梱**: `.vibe/templates/settings.local.json`（disableAllHooks: true）を 1 コピーで全 hook が消え、gitignore 対象なので PO から見えない。ガード本体（.vibe/hooks/）・権限定義・manifest も被ガード者の書込範囲内。
- **テストが無防備**: linter 設定には LintGuard があるのに、より重要な回帰の正本であるテスト（tests/**, **/*.test.*）は Coding Agent が自由に削除・スキップ化・期待値書き換えできる。SpecBench が実証した reward hacking の最頻経路が全開。

### パターン D: ハーネス自身が dogfooding されていない【自己矛盾】

- 唯一の CI（generate-check.yml）は freshness チェックのみで、**テスト 66 本をどのコミットでも実行しない**。path filter も core/schema|generators|validators に限定され、core/runtime/・hooks・tests/ の変更では CI 自体が起動しない。
- **main は現に赤**: test_stop_gate.sh 2 件・test_postwrite_lint.sh 2 件失敗、test_state.sh / test_migration_v2_to_v3.sh はサマリなしクラッシュ。失敗はすべて本物のバグ（stop_test_gate 未配線等）を正しく検出している。
- **テストランナー自体が fail-open**: test_helpers.sh の run_test は fail() を経ない非ゼロ return を失敗計上せず、「All N tests passed / exit 0」と虚偽報告し得る。
- 約 25 本が文言 grep テストで、「配線されて実際に発火するか」という結合挙動の検証層が欠落。`python3 -c` heredoc + `2>/dev/null` でトレースバックを捨てる方式は、現に main にある挙動バグ（fail-open、UI 誤判定、フラット配布での ImportError）を原理的に捕捉できない。
- VibeFlow リポ自身に .vibe/ が存在せず、自分の spec ループを自分に適用していない。V6-HANDOFF.md は git 未追跡。
- 細部の品質劣化の兆候: **10 モジュールで `from __future__ import annotations` が docstring の内側**（no-op）、dependency_analyzer の偽循環、dispatcher/patch_loop のフラット配布で壊れる絶対 import。

### パターン E: 二重正本と三世代の死蔵コード【乖離バグの量産器】

- **生成系が二系統**: setup（bash heredoc 群）と generate（schema 駆動 Python）が同じ成果物の別正本。heredoc 版だけが stop_test_gate を配線し、generate 版には無い → `vibeflow generate` を通すと**安全装置が無警告で剥がれる**。
- **sourced lib の SCRIPT_DIR グローバル汚染**により、setup の Step 7b/7c（.claude/rules/ と .vibe/runtime/ の配置）と GitHub ラベル作成が**無音スキップ** — 新規プロジェクトに v5/v6 の中核が配置されない（実地検証済み）。
- **アップグレードも二系統**: `vibeflow upgrade`（migrations を実行しない）と upgrade_vibeflow.sh（CLI から到達不能）。upgrade.py は廃止コマンドを復活させ、CLAUDE.md の手書き領域を無警告上書きし、baseline は v5/v6 が欠落。
- **三世代の死蔵コード ~1,400 行**: v4 packet 系（handoff.py / worker_adapter.py スタブ / codex_impl）、v5 dispatch 系（dispatcher / wrapper 群 — v6 実フローはどれも使わない）、v4 の 6 ロール定義。単なる埋蔵物ではなく、upgrade 経由で配布され、AGENTS.md が現役として説明し、「どれが本物の実行経路か」を曖昧にしている。
- doctor は可変 state ファイルの hash 不一致で**恒常的に error / exit 1**（毎セッション実行が義務のため、PO が「error が出るのが正常」と学習する狼少年化）。README は配布されないコマンドを案内し、.mcp.json.example は npm に存在しないパッケージを指す。

---

## 4. 改善ロードマップ — 6 フェーズ

検証済み提案を依存順に 6 フェーズへ統合した。各項目末尾の [id] は §6 対応表の finding ID。
原則: **新機構の発明より配線と fail-closed 化を先に。** 各フェーズは TDD（赤テスト先行）で進め、Pneuma で 1 サイクル実地確認してから次へ。

### Phase 0: 止血 — ハーネス自身を green にする（effort: S〜M、最優先）

「壊れない改修」を提供する前提として、まず自分が壊れていない状態を機械的に保証する。

1. **SCRIPT_DIR ホットフィックス**: 各 lib/create_*.sh のトップレベル `SCRIPT_DIR` を `_VF_LIB_DIR` 等の固有名に改名。これだけで新規 setup の .claude/rules/・.vibe/runtime/ 配置と GitHub ラベル作成が即復活する。[unify-setup-into-generate-pipeline (0)]
2. **tests/run_all.sh 新設 + CI でテスト実行**: test_helpers.sh を除く全 test_*.sh をサブシェル実行し exit code 集約。`.github/workflows/tests.yml`（path filter なし、pyyaml/jinja2 インストール、実測全件約 6 分）。[ci-runs-no-tests-main-is-red / harness-itself-untested-in-ci / ci-test-enforcement-and-runner]
3. **test_helpers.sh の silent-pass 修正**: run_test を if コンテキスト呼び出しに変え（set -e 即死も構造的に防止）、fail() 未経由の非ゼロ return を失敗計上。print_summary に PASSED+FAILED==RUN の整合検査。EXIT trap で「ABORTED before summary」検出。[test-helpers-silent-pass]
4. **main の赤 4 件を修正**: (a) generate_settings.py に stop_test_gate.sh（Stop、waiting_input より前）と postwrite_lint.sh（PostToolUse）を配線 + generate_hooks.py の static_hooks に追加、(b) test_state.sh の v4 'Engineer' fixture を v6 ロールへ、(c) v2→v3 migration の参照切れ修正 or レガシー打ち切り明示。[stop-test-gate-unwired ほか]
5. **PO の「詰み」3 点の即時解消**: (a) manifest に `kind: "mutable"` を導入し可変 state の hash 検査をスキップ（doctor の恒常 error 解消 — manifest から外すのは file_missing 検出を壊すため不可）、(b) README が案内する /execute-issue・/execute-all・/patch を実際に配布、(c) .mcp.json.example を実在する `@playwright/mcp` に修正（設定形状も `npx @playwright/mcp@latest --headless` 形式へ）。[po-recoverable-errors-doctor-readme-mcp]

**検証**: CI 上で 65 テストファイル全 green。わざと 1 テスト壊した PR が赤になる。新規 tmpdir setup で rules/runtime が配置される。

### Phase 1: fail-closed 化 — 偽 green の根絶（effort: M）

ループを回す前に「失敗が green に化ける経路」をゼロにする。これが無人運用の前提条件。

1. **レビュー実行失敗 → 失敗として記録**: codex_review.sh は $CODEX_CMD の exit code を明示捕捉し、失敗時は `{"passed": false, "status": "execution_failed"}` を直接書き出し非ゼロ exit。フォールバック文字列を parse させる現方式を廃止。[fail-open-gates-poison-loop / qa-chain-fail-open]
2. **parse 失敗 → 中立値**: claude_code_wrapper / result_collector / codex_wrapper の「JSON 解析失敗 → success」を `status='unparsed'` に変更し、判定側で非成功として扱う。
3. **qa_judge の verdict ホワイトリスト化**: `review_verdict=='pass'` のみ auto_pass 候補。'warn' は対応記録の evidence がない限り needs_human。'fail' は fail。**それ以外（unknown/unparsed/pending/欠落）は needs_human**（reason: 'review not executed'）。インフラ故障を fail でなく needs_human に倒すのは、壊れているのがコードではなくレビュー基盤であり、再実装リトライを焼くのが誤りだから。
4. **「仮 pass」の廃止と再判定の配線**: execute-issue Step 7-3 は `review_verdict='pending'` を渡し、Step 9（クロスレビュー）後に **Step 9.5: qa_judge 再実行（実 verdict で確定判定）** を追加。auto_pass はこの再判定でのみ成立。workflow-standard.md の auto_pass 条件と実行順序の矛盾を解消。
5. **証拠ベースの判定**: Step 7-1 を「テスト出力を `.vibe/reports/<issue>/test.log` に tee、exit code を test.exit に保存してから judge を呼ぶ」に改訂。judge は (i) ファイル実在・非空、(ii) test.exit==0 を検証し、自己申告 bool より exit code を優先。欠落時は auto_pass 不可。Step 11 完了報告は「主張」でなく証拠（出力末尾・ログパス・実行コマンド）を必須記載。[iris-report-evidence-fail-open]
6. **UI 判定の単一実装化**: `core/runtime/ui_task.py` に集約（qa_judge / dispatcher / issue_generator の三重定義解消）。英語キーワードは単語境界 regex（'ui' が 'build' にマッチする誤爆の解消 — 実証済み）、日本語は部分一致維持。優先順位: qa:ui ラベル > 変更ファイル拡張子 > キーワード fallback。[ui-gate-misfire / qa-judge-ui-false-positive-and-runtime-delivery]
7. **runtime 配布の修復**: generate_all.py に target "runtime"（core/runtime/*.py → .vibe/runtime/、manifest 管理下）。import はフラット配置対応の try/except フォールバックに統一（dispatcher/patch_loop の絶対 import は配布先で ImportError — 再現確認済み）。

**検証**: tests/test_qa_judge.sh に「unknown/pending/欠落 → 非 auto_pass」「evidence 欠落 → 非 auto_pass」「'Fix build script' が非 UI」。test_codex_review.sh に「実行失敗 → passed=false」。

### Phase 2: spec ループの完成 — v6 の本懐を配線する（effort: M〜L）

1. **execute-issue への spec 手順の組み込み**（v6 最大の欠落の解消）[spec-update-not-wired-into-execution-loop]:
   - **Step 3.5「To-Be Spec 編集」新設** — ブランチ作成後・ロール切替前。Issue の「## Spec 変更」欄に従い Story/Contract を同ブランチで編集（「spec 変更なし」の Issue は省略）
   - **Step 7-0「spec-verify 実行」** — exit 0（ERRORS 0）を確認、FAIL なら差戻し
   - **Step 7a の提示物に As-Is→To-Be 差分**（`git diff <base>...HEAD -- .vibe/spec/`）を追加
2. **逆方向 Spec Gate**: validate_step7a.py に「コードを変更しているのに .vibe/spec/ 変更がない PR」の検査を追加。Issue 本文の「spec 変更なし」**記入済み**宣言（テンプレ未記入の角括弧行は不可 — 偽陽性防止）があれば通し、なければ fail-closed でブロック。バグ分類 (i)（コードのみ修正）は宣言で正当に通過できループモデルと整合。[同上]
3. **To-Be spec の権限矛盾解消**: policy.yaml の coding_agent.can_write に `.vibe/spec/**` を追加 + **wrapper の role 文字列を display_name に揃え VIBEFLOW_SESSION を export**（これなしでは policy 1 行が無効化される）。iris-core.md に「Iris の spec 書込は kickoff と会話ドラフトに限る。ブランチ上の To-Be は Coding Agent」と明文化。[tobe-spec-author-unassigned-acl-contradiction]
4. **invariant 実行層の実装**（スキーマの約束を実装に）[invariant-test-execution-layer-missing / invariant-regression-orphaned]:
   - spec_verify.py に `--run-tests` モード: test 付き invariant をランナー自動判別でパス指定実行し、invariant ごとに `{id, story, status: verified|violated|pending}` を返す。**最大の独自価値は「収集 0 件検出」**（パスは実在するがテストランナーに収集されないファイル — 全スイート実行では原理的に検出不能な唯一の失敗モード）
   - qa_judge に `invariants_violated` を後方互換で追加（None=未実行は現行動作、>0 で hard fail）
   - healthcheck #8 を `--run-tests` に切替え、verified/pending/violated の実数を初めて表示
   - CI への組み込みはしない（V6-HANDOFF「drift CI 禁止」を遵守 — 既存のローカルゲート内に留める）
5. **spec-verify の穴塞ぎ**: 空ディレクトリ placeholder を error 化（.gitkeep 除外の再帰ファイル存在チェック）。kickoff に「未実装ドメインは Story を作らない」を明記。Pneuma の aituber 系 6 Story + Contract 2 件の削除 Issue（invariant テキストは plan.md に退避）。[empty-dir-placeholder-passes-spec-verify]
6. **スキーマ二重宣言の整合テスト**: spec.yaml の required 定義と spec_verify.py の手書き定数の set 比較テスト + schema_validate.py に spec タイプ追加。[spec-schema-double-declaration-drift]
7. **pending invariant の収束圧力**: healthcheck が spec-verify --json の stats を STATUS.md「Spec Health」に 1 行追記（直近 10 行のみ保持）。pending 比率の増加・30% 超滞留・同一 warning 2 回連続で「invariant 補強 Issue」の作成を PO に提案。[no-forcing-function-for-pending-invariants]
8. **実装前の意図確認（上流ゲート）**: Step 2 を「Task Breakdown + To-Be 確認」に拡張 — 曖昧点があれば AskUserQuestion で最大 3-5 問（回答は Issue の「## Clarifications」へ）、spec 変更ありの場合のみ「この Issue で変わること」を日本語 3-5 行で提示し Go を得る。dor_gate.py を execute-issue Step 1 から**実際に呼び出す**（現在どこからも呼ばれない死蔵モジュール）+ _SECTION_CHECKS に「## Spec 変更」を追加。根拠: Jules Planning Critic はタスク失敗率 -9.5% を定量実証、実装前検出は実装後検出より圧倒的に安い。[pre-implementation-clarify-and-tobe-approval]
9. **Checkpoint Packet**: Step 7a の提示物を「diff 行数 + 理由 1 行」から、AC チェックリスト形式を正とする 1 枚の packet（`.vibe/checkpoints/<issue>-packet.md`）に統合 — ①AC ごとの充足 + 対応テスト名 ②spec 差分の平易な日本語要約（できる/変わる/なくなること）③証拠（テスト出力・スクショ・レビュー verdict）④スコープ外変更の列挙 ⑤invariant 接触リスト（best-effort）。hook は packet の存在を強制（内容品質は instruction 担保）。既存 3 フォーマットの統合であり Decision Card 的な新インフラは作らない。[checkpoint-packet-for-po-decision]

**検証**: test_spec_gate.sh に「コード変更のみ+宣言なし → block」「未記入テンプレ原文 → block」等 4 ケース。test_invariant_runner.sh で「fail する test → violated」「収集 0 件 → error」。最後に Pneuma で 1 Issue を clarify → To-Be 編集 → 実装 → invariant 実行 → packet → Spec Gate の全経路で流す。

### Phase 3: 強制層 — honor-system の終了（effort: M）

Replit 事故の教訓どおり、自律エージェントの制約は指示文ではなくインフラレベルで。協調的エージェント向けガードレール（eval 難読化等は対象外）であることは validate_step7a.py 同様に明記する。

1. **validate_bash.py 新設**（PreToolUse, matcher: Bash、j2 テンプレート + generate 配線 + manifest 登録）: ①破壊的 git（push --force、main 直 push、reset --hard、clean -fd 等）を deny — reset --hard 等は checkpoint ファイルによる人間承認オーバーライド付き、②`>`/`tee`/`sed -i`/`rm`/`mv` の書込先パス抽出と ROLE_EDIT_ALLOW + ガード対象（tests/**、.vibe/hooks/**、linter 設定、settings.json）判定。`2>/dev/null` や /tmp は除外（誤検知対策）、`cat > .vibe/state.yaml` heredoc は ALWAYS_ALLOW でスキル互換維持。[bash-write-bypass-destructive-git / no-test-guard-bash-bypass]
2. **TestGuard**: (a) validate_access.py.j2 に Edit/Write レベルの検査（.skip/.only/xit/@pytest.mark.skip の新規追加、テスト数大幅減の上書き）、(b) validate_step7a.py に spec_changed() と同型の `test_weakened()` をインライン実装 — テストファイル削除・テストケース純減・skip 追加を検出したら**人間承認 checkpoint がない限り gh pr create をブロック**（qa:auto で bypass 不可）、(c) qa_judge に test_guard コンテキスト（削除/skip 検出で auto_pass 禁止）。Anthropic ハーネス指針「テストの削除・編集は unacceptable」の機械化。[no-test-guard-reward-hacking]
3. **自己承認バイパスの封鎖**: checkpoint 作成の唯一経路を `vibeflow approve <issue>`（**stdin が TTY であることを必須** — エージェントの Bash は TTY を持たないため決定論的に PO のみ通る）に変更。validate_access/validate_bash で `.vibe/checkpoints/**` への直接書込を全ロール deny。validate_step7a.py のブロックメッセージから「checkpoint を作成せよ」というバイパス教示を除去。[spec-gate-self-approval-bypass]
4. **ガード自己改竄の防止**: GUARD_PATTERNS（.vibe/hooks/**、.vibe/policy.yaml、generated-manifest.json、.claude/settings*.json）を全ロール deny。**disableAllHooks テンプレートの同梱を廃止**（緊急時手順は「PO が自分の手で作る」として docs へ）。doctor に disableAllHooks 検出を error として追加 + dispatch 直前にも同チェック（hook ベースの自己検査は hook 無効化時に動かないため）。[guard-self-tampering-and-killswitch / no-runaway-budgets (2)]
5. **ロール契約の修復**: validate_access.py の照合を role id ベース + 正規化層（display_name/短縮形/id のどれでも解決）に変更。wrapper は role_id を書き VIBEFLOW_SESSION を export。tests/test_role_contract.sh で policy ⇄ hook ⇄ wrapper ⇄ SKILL の文字列を突合。ロール遷移は transition_role.sh 経由 + ログ（遷移表の enforcement は全ワークフローの遷移表が揃ってから）。**根治は基本ループ安定後の「Coding Agent のサブエージェント化（worktree + disallowedTools）」** — ロール分離を自己申告から実行体の分離へ。[role-switch-honor-system-and-key-mismatch]
6. **Stop ゲートの正しい実装**: stop_hook_active（公式仕様の stdin JSON）を一次の再入防止とし、連続失敗カウンタ（成功時リセット、3 回で警告付き素通し+エスカレーション）を二次安全弁に。trap によるフラグ即削除を廃止。失敗メッセージは stderr へ（現状 stdout に出ており Claude に渡らないバグ）。jq でなく python3 でパース。[stop-gate-backpressure-unwired / stop-gate-unwired-and-flag-bug]

### Phase 4: ループエンジニアリングの実装 — 散文の機械化（effort: M〜L）

§2.3 の表の ❌ を埋める。すべて「既にあるルールの機械化」であり新発明ではない。

1. **loop_control.py 新設（リトライ計数の実体化）**: 既存の死にスキーマ `.vibe/sessions/dev-issue-<N>.yaml` の safety キー（max_fix_attempts: 3 / failed_approach_log が既に書かれている）を正本に再利用。`should-retry <issue>` CLI が attempts から `{action: retry|switch_agent|escalate}` を返し、execute-issue の失敗分岐で必ず実行する手順に。attempt 3 で Codex へスイッチ（agent_selector のフォールバックが初めて発火する）、3 失敗後は escalate（needs_human 強制 + PO 報告）。散文不遵守への保険として attempts>3 + 未承認時に commit/PR をブロックする hook。[loop-stop-conditions-not-enforced]
2. **暴走予算**: 試行ごとに `git diff --shortstat` を記録し、上限（patch_loop と同水準 + 行数上限）超過で強制 escalate。**同一失敗フィンガープリント**（Step 7 の失敗テスト名集合のハッシュ）2 回連続で「別アプローチ指示」、3 回で needs_human — safety.md の散文ルールの機械化。43 コミット暴走事例（§2.2）への直接の対策。[no-runaway-budgets-or-kill-switch]
3. **run ledger（ループのメモリ）**: `.vibe/runs/<date>.jsonl` 追記型台帳（run_ledger.py、単機能 API）。runtime モジュール側が自分で追記（honor-system にしない）。/progress と Step 11 報告は台帳から生成。healthcheck に「closed Issue に台帳エントリなし」警告。Ralph 原典のファイルベース状態管理（電源断からも復帰）の VibeFlow 版。[no-run-ledger-for-po-audit]
4. **進捗正本の一本化とアラート修復**: state.py に update_workflow_state()（state.yaml / project_state.yaml / sessions を同時更新）。waiting_input.sh の Step 判定を `7|7_*|7a*` に修正（**現状、Human Checkpoint 到達アラートは一度も鳴らない** — "7" 完全一致 vs 実際の値 "7_acceptance_test"）。[progress-truth-and-audit-journal]
5. **Issue ごとの fresh context**: execute-issue の Step 4-6 を同一セッション内ロール切替から、サブエージェント（worktree 分離可）または headless `claude -p` 委譲へ — これは iris-core.md の既存ルール「必ず dispatch する」に SKILL を一致させる修正。重いツール出力（テストログ・diff 全文）をサブエージェント側に閉じ込め、Iris 本体のコンテキスト劣化を抑える。Ralph の中心的洞察「イテレーション毎のコンテキストリセット、ファイルだけが共有状態」の採用。夜間バッチの到達点は「1 Issue = 1 fresh プロセス」。並列化は HANDOFF どおり基本ループ安定後。[execute-all-single-context-no-reset]

### Phase 5: 基盤統合と dogfooding（effort: L）

1. **setup → generate 一本化**: setup を「骨格 + 初期ファイル + 前提チェック + ラベル」の薄いブートストラップに縮小し、末尾で cmd_generate を必ず実行（manifest ごと生成）。settings.json の正本は schema 側に一本化し heredoc を廃止。generate の対象に rules / runtime / agents / skills のコピーターゲットを追加。[unify-setup-into-generate-pipeline]
2. **upgrade 一本化**: cmd_upgrade を「migration 連鎖 → ファイル同期 → generate」の単一パイプラインに。廃止コマンドの復活防止（allow-list 共有）、CLAUDE.md は generate の VF マーカー置換に委ねて全文上書きを廃止、baseline v5/v6 の補完 + リリースチェックリスト化。[single-upgrade-path-with-baselines]
3. **manifest/doctor の信頼回復**: mutable kind、source の虚偽記録修正（実コピー元 + provenance 分離）、.vibe/runtime/ を manifest 管理下に（検出器自身の drift 無検査という非対称の解消）。[manifest-doctor-integrity-trust]
4. **三世代死蔵コードの棚卸し**: v4 packet 系・v5 dispatch 系（残す場合は ADR で理由を明記）・lib/roles の v4 6 ロール・廃止コマンドを 2 段 PR で削除。配布済みプロジェクトの orphan 削除を migration に含める。[purge-three-generations-dead-code]
5. **pytest 基盤**: tests/python/ 新設。最初の 1 本は**フラット配布レイアウトでの全 18 モジュール import テスト**（現状 dispatcher/patch_loop が赤 — 再現確認済み）。docstring 内 no-op future import は ast 検証に置換。grep テストは価値の高い順に挙動テストへ移植。[no-python-test-infrastructure / grep-tests-cannot-catch-behavior-drift]
6. **setup/upgrade の E2E テスト**: tmpdir + gh シムで setup をフル実行し v6 不変条件をアサート。migration 参照ファイル実在チェックの機械化。[no-setup-upgrade-e2e-tests]
7. **CI 強化**: path filter 撤廃、os × python のマトリクス（macOS = BSD grep 環境の自然検出）、check_freshness を `generate_all.py --check` の exit code 利用に。[ci-matrix-and-fragile-freshness-check]
8. **dogfooding**: VibeFlow 自身に .vibe/spec/ を Bootstrap（Story = setup/generate/upgrade/spec-verify/doctor、Contract = manifest/settings/workflow-schema）。workflow.yaml(10 step) vs rules(11 step) の正本分裂を Issue で決着させ invariant 化 — spec-loop の (iii) の実演。V6-HANDOFF.md を docs/ へ移動し git 追跡。フル self-install（role hook 込み）は干渉リスクがあるため部分 dogfooding から。[dogfood-vibeflow-with-own-spec-loop]

### Phase 6（将来・基本ループ安定後): 完全性チェッカーが挙げた 10 ギャップ

1. **`/rollback <PR>` スキル** — revert + spec 逆適用 + invariant 実行 + Checkpoint を原子的に（PO の「やっぱり戻して」の受け皿。spec と revert を別々にやると整合が壊れる）
2. **Bootstrap As-Is の受け入れ検証** — Story を自然言語サマリで PO に提示 + 主要 Story は ui-explore で実挙動を見せる「As-Is 受け入れ」（間違った As-Is は以後の全差分を狂わせる）
3. **spec のライフサイクル管理** — Story の status 属性、機能削除時の spec 削除手順、肥大警告（Pneuma は既に 16 Story / 114 invariant）
4. **Vision ⇄ Story のトレーサビリティ** — vision_ref フィールド + Vision 改訂時の影響 Story 差分提案フロー（「意図通り」を構造的に保証する唯一の軸）
5. **非機能 invariant** — 性能予算・セキュリティの invariant 種別 + 認証/認可 Story への敵対的テスト自動生成（vibe coding 事故 7 件は全件 1 本のテストで防げた）
6. **依存更新ループ** — 第 4 の定型 Issue タイプ「依存更新 → 全 invariant → スモーク」+ healthcheck での古い依存報告
7. **コスト可視化** — run ledger に Issue ごとの時間・概算コスト、暴走予算に金額軸、/progress で報告
8. **セッション間の知識継承** — `.vibe/notes.md`（追記式 1-2 行、重い機構にしない）への学び記録 + Issue 着手時読み込み
9. **エージェント CLI の出力契約テスト** — doctor に CLI バージョン/フォーマットのスモーク、wrapper パースのフィクスチャ契約テスト
10. **シークレット漏洩防止 hook** — commit/PR 時の軽量パターン検査（fail-closed）+ .env 系を AccessGuard 対象に

---

## 5. 「やらないこと」の確認 — V6-HANDOFF 制約との整合

全提案は敵対的検証で以下の制約に照らしてチェック済み:

- **ゼロから作り直さない** ✅ — 全提案が既存モジュールの修正・配線・既存パターン（LintGuard、Spec Gate、patch_loop）の同型拡張
- **PO に YAML を書かせない** ✅ — PO の新しい操作は「会話で clarify に答える」「packet を読んで承認する」「`vibeflow approve` を打つ」のみ
- **Dashboard / Cockpit を作らない** ✅ — 可視化はすべて STATUS.md への行追記・チャット提示・jsonl 台帳に限定
- **akasha の過剰機械を持ち込まない** ✅ — drift 検出 **CI** は明示的に不採用（invariant 実行はローカルゲート内）。Decision Card 化を避けるガード（packet に独自 schema/インデックスを作らない）も提案に内蔵。/goal 型の汎用証拠判定器も将来送り
- **超並列・徹底レビューは基本ループの後** ✅ — worktree 並列・hold-out テスト 2 層構造・ロール遷移表の enforcement・Coding Agent 完全サブエージェント化は、いずれも「基本ループ安定後」と明記して将来枠に置いた

---

## 6. 全 42 findings 対応表

| # | ID | 次元 | 深刻度 | 工数 | Phase |
|---|---|---|---|---|---|
| 1 | spec-update-not-wired-into-execution-loop | spec | **critical** | M | 2 |
| 2 | invariant-test-execution-layer-missing | spec | **critical** | L | 2 |
| 3 | empty-dir-placeholder-passes-spec-verify | spec | high | S | 2 |
| 4 | tobe-spec-author-unassigned-acl-contradiction | spec | high | S-M | 2 |
| 5 | no-forcing-function-for-pending-invariants | spec | medium | S-M | 2 |
| 6 | spec-schema-double-declaration-drift | spec | medium | S | 2 |
| 7 | no-test-guard-bash-bypass | verify | **critical** | M | 3 |
| 8 | stop-test-gate-unwired | verify | **critical** | M | 0+3 |
| 9 | qa-chain-fail-open | verify | high | M | 1 |
| 10 | harness-itself-untested-in-ci | verify | high | M | 0 |
| 11 | invariant-regression-orphaned | verify | high | M-L | 2 |
| 12 | ui-gate-misfire | verify | medium | M | 1 |
| 13 | iris-report-evidence-fail-open | po-ux | **critical** | M | 1 |
| 14 | checkpoint-packet-for-po-decision | po-ux | **critical** | M | 2 |
| 15 | pre-implementation-clarify-and-tobe-approval | po-ux | high | M | 2 |
| 16 | progress-truth-and-audit-journal | po-ux | high | M | 4 |
| 17 | po-recoverable-errors-doctor-readme-mcp | po-ux | high | M | 0 |
| 18 | qa-judge-ui-false-positive-and-runtime-delivery | po-ux | high | M | 1 |
| 19 | loop-stop-conditions-not-enforced | loop | **critical** | M | 4 |
| 20 | stop-gate-backpressure-unwired | loop | **critical** | S | 0+3 |
| 21 | fail-open-gates-poison-loop | loop | **critical** | M | 1 |
| 22 | no-run-ledger-for-po-audit | loop | high | M | 4 |
| 23 | execute-all-single-context-no-reset | loop | high | L | 4 |
| 24 | no-runaway-budgets-or-kill-switch | loop | high | M | 4 |
| 25 | unify-setup-into-generate-pipeline | arch | **critical** | L | 0(hotfix)+5 |
| 26 | ci-test-enforcement-and-runner | arch | **critical** | M | 0 |
| 27 | single-upgrade-path-with-baselines | arch | high | L | 5 |
| 28 | manifest-doctor-integrity-trust | arch | high | M | 0(mutable)+5 |
| 29 | purge-three-generations-dead-code | arch | medium | M | 5 |
| 30 | dogfood-vibeflow-with-own-spec-loop | arch | high | M | 5 |
| 31 | bash-write-bypass-destructive-git | safety | **critical** | M | 3 |
| 32 | spec-gate-self-approval-bypass | safety | **critical** | M | 3 |
| 33 | guard-self-tampering-and-killswitch | safety | high | M | 3 |
| 34 | role-switch-honor-system-and-key-mismatch | safety | high | M | 3 |
| 35 | stop-gate-unwired-and-flag-bug | safety | high | S | 0+3 |
| 36 | no-test-guard-reward-hacking | safety | high | M | 3 |
| 37 | ci-runs-no-tests-main-is-red | self-tests | **critical** | M | 0 |
| 38 | no-setup-upgrade-e2e-tests | self-tests | **critical** | M-L | 5 |
| 39 | test-helpers-silent-pass | self-tests | high | S | 0 |
| 40 | grep-tests-cannot-catch-behavior-drift | self-tests | high | M | 5 |
| 41 | no-python-test-infrastructure | self-tests | medium | M | 5 |
| 42 | ci-matrix-and-fragile-freshness-check | self-tests | medium | S | 5 |

（critical 13 件 / high 21 件 / medium 8 件。複数次元から同一根因に到達した指摘 — Stop ゲート、fail-open、CI 赤、invariant 実行層 — は本文では統合して扱った）

---

## 7. 主要な一次情報源

**ループエンジニアリング**: ghuntley.com/ralph, ghuntley.com/loop, github.com/ghuntley/how-to-ralph-wiggum, anthropics/claude-code の ralph-wiggum プラグイン, addyosmani.com/blog/loop-engineering, The Register (2026-01-27), Zenn (karamage / peintangos / explaza), note (AI-Driven Lab / MAKE A CHANGE)

**ハーネス公式**: code.claude.com/docs の best-practices / hooks / goal / sub-agents / headless, anthropic.com/engineering の effective-harnesses-for-long-running-agents / harness-design-long-running-apps, claude.com/blog/building-agents-with-the-claude-agent-sdk, nizos/tdd-guard

**SDD**: martinfowler.com/articles/exploring-gen-ai/sdd-3-tools, kiro.dev/docs + blog/deep-spec-analysis, github.com/Fission-AI/OpenSpec, github.com/github/spec-kit, arxiv 2602.00180, tessl.io, AWS builders-flash 202601, Zenn fusic, Classmethod

**エージェント QA**: openhands.dev（critic AUC 0.69 / SDLC ゲート YAML）, alignment.openai.com/scaling-code-verification, cognition.ai（Devin 年次レビュー）, jules.google/docs/changelog（Planning Critic -9.5%）, SpecBench (arxiv 2605.21384), ImpossibleBench, Meta ACH, red.anthropic.com/2026/property-based-testing, Mergify/GitHub auto-merge

**非エンジニア PO**: dannorth.net/introducing-bdd, gojko.net (Specification by Example), getautonoma.com/blog/vibe-coding-failures（事故 7 件）, simonwillison.net (vibe engineering), Thoughtworks Radar Vol.34 (harness engineering), Vercel preview comments, testRigor/Shortest, Zenn NCDC, Azit（受け入れエラーの 41% は旧仕様の残存）

---

## 8. 終わりに — 一番大事な一段落

v6 が導入した構造化 spec は、ループエンジニアリング時代の「北極星」としてそのまま機能する正しい資産であり、業界の最先端（spec-anchored + 独立 Evaluator + backpressure ループ）と同じ場所に立っている。足りないのはアイデアではなく、**自分が書いたルールを自分の機械で強制すること**。本レポートの 42 件は多く見えるが、根は 3 つ — 散文を機械に、未配線を配線に、fail-open を fail-closed に — であり、Phase 0〜2（止血 → 偽 green 根絶 → spec ループ配線）だけで「PO がコードを読まずに、壊れない改修を回す」の骨格は立つ。Phase 3 以降は、その骨格を夜間・無人・長時間に耐えるループへ育てる工程である。
