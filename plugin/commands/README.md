# Plugin Commands Mapping

VibeFlow が提供する Claude Code Commands（互換レイヤ）の一覧と配置マッピング。

## Source of Truth

`lib/commands/` が実体の置き場所です。Commands は Skills への互換 wrapper として維持されています。

## Provided Commands

| Command | Source | Target | 対応 Skill |
|---------|--------|--------|-----------|
| `discuss` | `lib/commands/discuss.md` | `.claude/commands/discuss.md` | `vibeflow-discuss` |
| `conclude` | `lib/commands/conclude.md` | `.claude/commands/conclude.md` | `vibeflow-conclude` |
| `progress` | `lib/commands/progress.md` | `.claude/commands/progress.md` | `vibeflow-progress` |
| `healthcheck` | `lib/commands/healthcheck.md` | `.claude/commands/healthcheck.md` | `vibeflow-healthcheck` |
| `quickfix` | `lib/commands/quickfix.md` | `.claude/commands/quickfix.md` | — (direct) |
| `run-e2e` | `lib/commands/run-e2e.md` | `.claude/commands/run-e2e.md` | — (direct) |

## Skills との関係

v4.0 以降、Skills が canonical な実装です。Commands は `/discuss` のようなスラッシュコマンド形式での呼び出しを維持するための互換レイヤです。

## Standalone 対応

Standalone setup では `lib/create_commands.sh` が配置を担当します。
