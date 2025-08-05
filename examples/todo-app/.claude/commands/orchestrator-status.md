# Orchestrator状態を表示

Display the current orchestrator status including:
- Overall project health (healthy/warning/critical)
- Recent step completions and their artifacts
- Active warnings and risks
- Critical decisions pending
- Communication log highlights

Read .vibe/orchestrator.yaml and provide a comprehensive summary in Japanese.

Format output as:
```
🌐 プロジェクト健全性: [status]
📦 成果物: [summary]
⚠️  警告: [count]
🔴 リスク: [summary]
💬 コミュニケーション: [recent]
```
