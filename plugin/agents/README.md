# Plugin Agents Mapping

VibeFlow が提供する Claude Code Subagents の一覧と配置マッピング。

## Source of Truth

`examples/.claude/agents/` が実体の置き場所です。

## Provided Agents

| Agent | Source | Target | Purpose |
|-------|--------|--------|---------|
| `code-reviewer` | `examples/.claude/agents/code-reviewer.md` | `.claude/agents/code-reviewer.md` | Read-only コードレビュー |
| `qa-acceptance` | `examples/.claude/agents/qa-acceptance.md` | `.claude/agents/qa-acceptance.md` | 受入テスト検証 |
| `test-runner` | `examples/.claude/agents/test-runner.md` | `.claude/agents/test-runner.md` | 並列テスト実行 |

## Standalone 対応

Standalone setup では `lib/create_subagents.sh` が配置を担当します。
