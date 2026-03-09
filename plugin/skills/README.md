# Plugin Skills Mapping

VibeFlow が提供する Claude Code Skills の一覧と配置マッピング。

## Source of Truth

`examples/.claude/skills/` が実体の置き場所です。Plugin install 時はここから target project の `.claude/skills/` へコピーされます。

## Provided Skills

| Skill | Source | Target |
|-------|--------|--------|
| `vibeflow-issue-template` | `examples/.claude/skills/vibeflow-issue-template/SKILL.md` | `.claude/skills/vibeflow-issue-template/SKILL.md` |
| `vibeflow-tdd` | `examples/.claude/skills/vibeflow-tdd/SKILL.md` | `.claude/skills/vibeflow-tdd/SKILL.md` |
| `vibeflow-discuss` | `examples/.claude/skills/vibeflow-discuss/SKILL.md` | `.claude/skills/vibeflow-discuss/SKILL.md` |
| `vibeflow-conclude` | `examples/.claude/skills/vibeflow-conclude/SKILL.md` | `.claude/skills/vibeflow-conclude/SKILL.md` |
| `vibeflow-progress` | `examples/.claude/skills/vibeflow-progress/SKILL.md` | `.claude/skills/vibeflow-progress/SKILL.md` |
| `vibeflow-healthcheck` | `examples/.claude/skills/vibeflow-healthcheck/SKILL.md` | `.claude/skills/vibeflow-healthcheck/SKILL.md` |
| `vibeflow-ui-smoke` | `examples/.claude/skills/vibeflow-ui-smoke/SKILL.md` | `.claude/skills/vibeflow-ui-smoke/SKILL.md` |
| `vibeflow-ui-explore` | `examples/.claude/skills/vibeflow-ui-explore/SKILL.md` | `.claude/skills/vibeflow-ui-explore/SKILL.md` |

## Standalone 対応

Standalone setup (`setup_vibeflow.sh`) では `lib/create_skills.sh` が同じ source からコピーを実行します。Plugin install も同じ source を使うため、結果は同一です。
