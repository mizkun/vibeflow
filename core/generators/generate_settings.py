#!/usr/bin/env python3
"""
VibeFlow Settings Generator
Generates .claude/settings.json from schema — reads policy.yaml to determine
which hooks to include based on enforcement level.

Usage:
    python3 core/generators/generate_settings.py --schema-dir core/schema --output <dir>
"""

import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml is required.", file=sys.stderr)
    sys.exit(1)


def generate_settings(schema_dir: str, output_dir: str) -> None:
    """Generate settings.json from schema directory."""
    schema_path = Path(schema_dir)

    with open(schema_path / "policy.yaml") as f:
        policy = yaml.safe_load(f)

    # Determine which hooks to include based on enforcement
    has_hard_enforcement = any(
        r.get("enforcement") == "hard"
        for r in policy.get("roles", {}).values()
    )

    # Build PreToolUse hooks
    pre_tool_use = []

    if has_hard_enforcement:
        # Access guard: blocks unauthorized writes per role
        pre_tool_use.append({
            "matcher": "Edit|Write|MultiEdit",
            "hooks": [{
                "type": "command",
                "command": 'python3 "$CLAUDE_PROJECT_DIR"/.vibe/hooks/validate_access.py',
                "timeout": 5,
            }],
        })
        # Write guard: blocks plans/ directory writes
        pre_tool_use.append({
            "matcher": "Edit|Write|MultiEdit",
            "hooks": [{
                "type": "command",
                "command": 'bash "$CLAUDE_PROJECT_DIR"/.vibe/hooks/validate_write.sh',
                "timeout": 5,
            }],
        })
        # Step 7a guard: blocks PR creation until QA checkpoint
        pre_tool_use.append({
            "matcher": "Bash",
            "hooks": [{
                "type": "command",
                "command": 'python3 "$CLAUDE_PROJECT_DIR"/.vibe/hooks/validate_step7a.py',
                "timeout": 10,
            }],
        })

    settings = {
        "hooks": {
            "PreToolUse": pre_tool_use,
            "PostToolUse": [{
                "matcher": "TodoWrite|Edit|Write|MultiEdit",
                "hooks": [{
                    "type": "command",
                    "command": 'bash "$CLAUDE_PROJECT_DIR"/.vibe/hooks/task_complete.sh 2>/dev/null || true',
                    "timeout": 2,
                }],
            }],
            "Stop": [{
                "hooks": [{
                    "type": "command",
                    "command": 'bash "$CLAUDE_PROJECT_DIR"/.vibe/hooks/waiting_input.sh 2>/dev/null || true',
                    "timeout": 2,
                }],
            }],
        },
    }

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    settings_file = output_path / "settings.json"
    with open(settings_file, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")

    print(f"Generated: {settings_file}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate settings.json from schema")
    parser.add_argument("--schema-dir", required=True, help="Path to schema directory")
    parser.add_argument("--output", required=True, help="Output directory")
    args = parser.parse_args()

    generate_settings(args.schema_dir, args.output)


if __name__ == "__main__":
    main()
