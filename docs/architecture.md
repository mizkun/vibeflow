# VibeFlow Architecture

VibeFlow のアーキテクチャと配布モデルの設計ドキュメント。

## 配布モデル: Standalone と Plugin の両立

VibeFlow は 2 つのインストールモードをサポートします。どちらも同じ source（`examples/`）から生成されるため、結果は同一です。

### Standalone Mode（現行）

`setup_vibeflow.sh` を実行し、プロジェクトに直接ファイルをコピーします。

```
setup_vibeflow.sh
├── create_claude_md()        → CLAUDE.md
├── create_slash_commands()   → .claude/commands/*.md
├── create_skills()           → .claude/skills/*/SKILL.md
├── create_subagents()        → .claude/agents/*.md
├── create_access_guard()     → .vibe/hooks/validate_*.{py,sh}
├── create_claude_settings()  → .claude/settings.json + notification hooks
├── create_playwright_mcp()   → .mcp.json.example + scripts/playwright_*.sh
├── deploy rules/             → .claude/rules/*.md (v5)
└── create_github_labels()    → GitHub labels (optional)
# Note: create_dev_launcher() は v5 で廃止 (Iris auto-dispatch)
```

**特徴**:
- 完全自己完結型（依存関係なし）
- プロジェクトごとにファイルがコピーされる
- カスタマイズ自由（コピー後は独立）

### Plugin Mode（将来）

Claude Code plugin として `plugin/` の定義に基づいてインストールします。

```
.claude-plugin/plugin.json    → プラグインメタデータ
plugin/
├── skills/                   → Skills マッピング定義
├── hooks/                    → Hooks マッピング定義
├── agents/                   → Agents マッピング定義
└── commands/                 → Commands 互換レイヤ定義
```

**特徴**:
- Claude Code のプラグインエコシステムに統合
- バージョン管理・アップデートが容易
- 複数プロジェクトで共有可能

## Source of Truth

```
examples/                        ← Single Source of Truth
├── CLAUDE.md                    ← プロジェクトルールテンプレート
├── .claude/
│   ├── skills/vibeflow-*/       ← Skills 実体
│   ├── agents/*.md              ← Agents 実体
│   └── commands/*.md            ← Commands 実体
├── .vibe/
│   └── hooks/                   ← Hooks 実体
├── .mcp.json.example            ← MCP 設定テンプレート
└── scripts/                     ← Playwright スクリプト
```

`lib/commands/` は commands の master copy です（`examples/.claude/commands/` は lib からコピーされたもの）。

### 生成フロー

```
examples/ (source)
    │
    ├──→ setup_vibeflow.sh (Standalone) ──→ target project
    │
    └──→ plugin/ (Plugin) ──→ Claude Code plugin install ──→ target project
```

両方のパスが同じ `examples/` を参照するため、出力は一貫しています。

## コンポーネント構成

### Skills（Canonical）

| Component | Location | Installer |
|-----------|----------|-----------|
| Source | `examples/.claude/skills/vibeflow-*/SKILL.md` | — |
| Standalone | `lib/create_skills.sh` | `setup_vibeflow.sh` |
| Plugin | `plugin/skills/` | plugin install |

Skills は v4.0 以降の canonical な実装単位です。

### Hooks（Guard + Notification）

| Component | Location | Installer |
|-----------|----------|-----------|
| Source | `examples/.vibe/hooks/*` | — |
| Standalone | `lib/create_access_guard.sh`, `lib/create_claude_settings.sh` | `setup_vibeflow.sh` |
| Plugin | `plugin/hooks/` | plugin install |

Hooks は `.claude/settings.json` への登録が必要です。

### Agents（Subagents）

| Component | Location | Installer |
|-----------|----------|-----------|
| Source | `examples/.claude/agents/*.md` | — |
| Standalone | `lib/create_subagents.sh` | `setup_vibeflow.sh` |
| Plugin | `plugin/agents/` | plugin install |

### Commands（互換レイヤ）

| Component | Location | Installer |
|-----------|----------|-----------|
| Master | `lib/commands/*.md` | — |
| Source | `examples/.claude/commands/*.md` | — |
| Standalone | `lib/create_commands.sh` | `setup_vibeflow.sh` |
| Plugin | `plugin/commands/` | plugin install |

Commands は Skills への互換 wrapper です。`/discuss` → `vibeflow-discuss` skill のように対応します。

## Plugin install の将来設計

Plugin install は以下のステップで動作する想定です（未実装）:

1. `.claude-plugin/plugin.json` を読み込む
2. `provides` に定義されたコンポーネントを `source` パスから取得
3. target project の適切な場所にコピー
4. `.claude/settings.json` に hooks を登録

### 制約

- Plugin install は **additive** — 既存ファイルは上書きしない
- Plugin uninstall は managed files のみ削除
- Plugin update は差分のみ適用

## ディレクトリ構成（全体）

```
vibeflow/
├── bin/vibeflow              # CLI エントリポイント
├── setup_vibeflow.sh         # Standalone installer
├── VERSION                   # バージョン (single source)
│
├── examples/                 # Source of Truth
│   ├── CLAUDE.md
│   ├── .claude/skills/
│   ├── .claude/agents/
│   ├── .claude/commands/
│   ├── .vibe/hooks/
│   ├── .mcp.json.example
│   └── scripts/
│
├── lib/                      # Setup modules
│   ├── common.sh
│   ├── create_skills.sh
│   ├── create_commands.sh
│   ├── create_playwright.sh
│   └── ...
│
├── plugin/                   # Plugin マッピング定義
│   ├── skills/
│   ├── hooks/
│   ├── agents/
│   └── commands/
│
├── .claude-plugin/
│   └── plugin.json           # Plugin メタデータ
│
├── core/                     # Runtime / Schema (将来)
│   ├── runtime/
│   └── schema/
│
├── docs/                     # ドキュメント
│   ├── architecture.md       # この文書
│   ├── playwright.md
│   └── codex-cloud-design.md
│
└── tests/                    # テスト
```
