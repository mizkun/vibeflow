# VibeFlow v5 — Iris-Only Architecture

> **Iris と話しかけるだけで開発が進む。**
> ユーザーは Iris にだけ会話すれば、Iris が計画・実装・レビュー・QA・クローズまで全自動で実行します。

## What is VibeFlow?

VibeFlow は AI 駆動の開発フレームワークです。v5 では **Iris-Only** アーキテクチャを採用し、ユーザーは Iris（プロジェクトパートナー）に自然言語で話しかけるだけで開発が進みます。

### Key Features

- **Iris-Only**: 単一ターミナルで完結。Iris が全てを管理
- **Codex + Claude Code**: デフォルト Codex で sandbox 実行、必要時に Claude Code へ自動フォールバック
- **クロスレビュー (Cross-Review)**: コーディングしなかった方の agent がレビュー
- **自動 QA 判断**: テスト + レビュー結果から auto QA 判定。`qa:auto` Issue は自動クローズ (auto_pass)
- **Playwright デフォルト**: E2E テストがデフォルト有効
- **TDD 駆動**: テストファースト (Red-Green-Refactor)
- **Issue 駆動**: すべての作業は GitHub Issue に紐付け

## Quick Start

```bash
# 1. VibeFlow をインストール
git clone <vibeflow-repo>
cd vibeflow && bash install.sh

# 2. プロジェクトディレクトリでセットアップ
cd ~/your-project
vibeflow setup

# 3. Iris と会話開始
claude
# → Iris に「ログイン機能を作りたい」と話しかけるだけ！
```

## How It Works

```
ユーザー: 「ログイン機能を作りたい」
    │
    ▼
Iris: 要件整理 → Issue 作成
    │
    ▼
Iris: Codex に dispatch (自動)
    │
    ▼
Codex: TDD で実装 (sandbox)
    │
    ▼
Iris: Claude Code でクロスレビュー
    │
    ▼
Iris: QA 判断 → PR 作成 → マージ → クローズ
    │
    ▼
ユーザー: 結果報告を受ける
```

## Architecture

### Agent Selection

| 条件 | Agent |
|------|-------|
| デフォルト | Codex (sandbox) |
| MCP / Playwright / ローカル FS | Claude Code |
| Codex 2回失敗 | Claude Code (fallback) |
| ユーザー指定 | 指定に従う |

### Workflow (11 Steps)

Iris が自動進行します。

| Steps | Description | Who |
|-------|------------|-----|
| 1-2 | Issue Review + Task Breakdown | Iris |
| 3-6 | Branch + TDD (Test→Impl→Refactor) | Coding Agent |
| 7-7a | Acceptance Test + Human Checkpoint | Iris / Human |
| 8 | PR Creation | Coding Agent |
| 9 | Cross-Review | Other Agent |
| 10-11 | Merge + Close | Iris |

### QA Judgment

- **auto_pass**: テスト PASS + レビュー PASS + 小 diff + 低リスク → 自動クローズ
- **needs_human**: UI 変更 / 高リスク / `qa:manual` → ユーザー確認
- **fail**: テスト or レビュー失敗 → 修正を再 dispatch

## Project Structure

```
your-project/
├── CLAUDE.md                          # Iris ロール定義 + プロジェクト概要
├── .claude/
│   ├── rules/                         # ルール定義 (v5)
│   │   ├── iris-core.md              # Iris の振る舞い・責務
│   │   ├── workflow-standard.md      # 11-step ワークフロー
│   │   ├── workflow-patch.md         # Patch Loop
│   │   ├── safety.md                 # Safety Rules
│   │   └── playwright.md            # Playwright E2E ルール
│   ├── skills/                       # スキル定義
│   ├── agents/                       # サブエージェント
│   └── settings.json                 # Hook 設定
├── .vibe/
│   ├── project_state.yaml           # プロジェクト状態
│   ├── sessions/                     # Agent セッション記録
│   ├── context/STATUS.md            # 現在の状況
│   ├── references/                   # ホット参照情報
│   └── archive/                     # アーカイブ
├── vision.md                        # プロダクトビジョン
├── spec.md                          # 仕様
└── plan.md                          # ロードマップ
```

## Commands

Iris への自然言語指示が基本です。Slash command は補助的に使用します。

| Command | Description |
|---------|------------|
| (自然言語) | Iris に直接話しかける（メイン） |
| `/conclude` | 会話をまとめ、Plan/Spec を更新 |
| `/patch <issue>` | Patch Loop 開始 |
| `/progress` | 進捗確認 |
| `/healthcheck` | 整合性チェック |
| `/run-e2e` | Playwright E2E テスト |

## CLI

```bash
vibeflow setup [--force|--no-backup|--without-e2e]
vibeflow upgrade [--dry-run|--allow-dirty]
vibeflow generate [--target <name>|--diff]
vibeflow version
vibeflow doctor [--json|--strict]
vibeflow help
```

## Runtime Modules

v5 の core/runtime/ モジュール:

| Module | Description |
|--------|------------|
| `codex_wrapper.py` | Codex CLI ラッパー |
| `claude_code_wrapper.py` | Claude Code CLI ラッパー |
| `agent_selector.py` | Agent 選択ロジック |
| `result_collector.py` | 結果収集・報告 |
| `dispatcher.py` | Session 自動 dispatch |
| `dependency_analyzer.py` | Issue 依存関係分析 |
| `issue_generator.py` | Issue 自動生成 |
| `qa_judge.py` | QA 判断自動化 |
| `cross_review.py` | クロスレビュー |
| `auto_close.py` | Issue 自動クローズ |

## Development

```bash
# テスト実行
for f in tests/test_*.sh; do bash "$f"; done

# 特定テスト
bash tests/test_codex_wrapper.sh
```

## License

MIT
