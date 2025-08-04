# Vibe Coding Framework セットアップガイド

## はじめに

Vibe Coding Frameworkは、Claude Codeで使用するAI駆動の開発方法論です。このガイドでは、フレームワークのセットアップ方法を詳しく説明します。

## 前提条件

- macOS または Linux
- Bash シェル
- Git（オプション、プロジェクト管理用）
- Claude Code

## インストール方法

### 1. リポジトリのクローン

```bash
git clone https://github.com/mizkun/vibeflow.git
cd vibeflow
```

### 2. 新しいプロジェクトディレクトリの作成

**重要**: setup_vibeflow.shは、プロジェクトを作成したいディレクトリで実行してください。リポジトリ内で直接実行しないでください。

```bash
# 新しいプロジェクトディレクトリを作成
mkdir ~/my-vibe-project
cd ~/my-vibe-project

# セットアップスクリプトを実行
~/path/to/vibeflow/setup_vibeflow.sh
```

### 3. セットアップオプション

```bash
# ヘルプを表示
./setup_vibeflow.sh --help

# 確認なしでインストール
./setup_vibeflow.sh --force

# バックアップをスキップ
./setup_vibeflow.sh --no-backup

# バージョンを確認
./setup_vibeflow.sh --version
```

## 初期設定

セットアップ完了後、以下のファイルを編集してプロジェクトの内容を記入してください：

### 1. vision.md
プロダクトビジョンを記載します：
- 解決したい課題
- ターゲットユーザー
- 提供する価値
- プロダクトの概要
- 成功の定義

### 2. spec.md
仕様と技術設計を記載します：
- 機能要件（必須機能、あったら良い機能）
- 非機能要件（パフォーマンス、セキュリティ、可用性）
- 技術スタック
- アーキテクチャ
- 制約事項

### 3. plan.md
開発計画とTODOを記載します：
- マイルストーン
- TODOリスト（優先度別）
- 完了項目
- 次のスプリント予定

## Claude Codeでの使用方法

1. Claude Codeでプロジェクトディレクトリを開く
2. 日本語で「開発サイクルを開始して」と入力
3. AIが自動的に開発フローを進行

## プロジェクト構造

セットアップ後、以下の構造が作成されます：

```
your-project/
├── .claude/
│   ├── agents/         # Subagent定義
│   └── commands/       # スラッシュコマンド
├── .vibe/
│   ├── state.yaml      # サイクル状態
│   └── templates/      # Issueテンプレート
├── issues/             # 実装タスク
├── src/                # ソースコード
├── CLAUDE.md           # フレームワーク説明
├── vision.md           # プロダクトビジョン
├── spec.md             # 仕様書
└── plan.md             # 開発計画
```

## 次のステップ

1. vision.md、spec.md、plan.mdを編集
2. Claude Codeで開発サイクルを開始
3. 2つのヒューマンチェックポイントで確認
4. AIが自動的に実装を進行

詳細な使い方は[CLAUDE.md](../examples/todo-app/CLAUDE.md)を参照してください。