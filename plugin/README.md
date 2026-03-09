# VibeFlow Plugin Structure

このディレクトリは VibeFlow を Claude Code plugin として配布するための構造定義です。

## 概要

VibeFlow は 2 つのインストール方法をサポートします:

| モード | 方法 | 対象 |
|--------|------|------|
| **Standalone** | `setup_vibeflow.sh` | 新規プロジェクトへのフルセットアップ |
| **Plugin** | `plugin/` マッピング | Claude Code plugin としてのインストール |

## ディレクトリ構成

```
plugin/
├── README.md          # この文書
├── skills/            # Skills マッピング
│   └── README.md      # 提供する skills の一覧と配置先
├── hooks/             # Hooks マッピング
│   └── README.md      # 提供する hooks の一覧と配置先
├── agents/            # Agents マッピング
│   └── README.md      # 提供する agents の一覧と配置先
└── commands/          # Commands 互換レイヤ
    └── README.md      # コマンド → skill 対応表
```

## Source of Truth

**`examples/` が single source of truth** です。`plugin/` はマッピング定義のみを持ち、実体は `examples/` から参照します。

```
examples/                          plugin/
├── .claude/skills/vibeflow-*/  →  skills/ (マッピング)
├── .claude/agents/*.md         →  agents/ (マッピング)
├── .vibe/hooks/*               →  hooks/ (マッピング)
└── .claude/commands/*.md        →  commands/ (マッピング)
```

## Plugin メタデータ

`.claude-plugin/plugin.json` にプラグインの名前・バージョン・提供物を定義しています。

## 関連ドキュメント

- `docs/architecture.md` — Standalone / Plugin 両立方針の詳細
- `.claude-plugin/plugin.json` — プラグインメタデータ
