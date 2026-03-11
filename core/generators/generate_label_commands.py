#!/usr/bin/env python3
from __future__ import annotations
"""
VibeFlow Label Command Generator
Reads issue_labels.yaml and outputs `gh label create` commands.

Usage:
    python3 core/generators/generate_label_commands.py core/schema/issue_labels.yaml
    python3 core/generators/generate_label_commands.py core/schema/issue_labels.yaml --dry-run
"""

import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml is required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


def generate_commands(labels_path: str) -> list[str]:
    """Read issue_labels.yaml and return gh label create commands."""
    with open(labels_path) as f:
        data = yaml.safe_load(f)

    categories = data.get("categories", {})
    commands = []

    for cat_def in categories.values():
        labels = cat_def.get("labels", [])
        for label in labels:
            name = label["name"]
            color = label["color"]
            description = label.get("description", "")
            # --force updates the label if it already exists
            cmd = (
                f'gh label create "{name}" '
                f'--color "{color}" '
                f'--description "{description}" '
                f'--force'
            )
            commands.append(cmd)

    return commands


def main() -> None:
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <issue_labels.yaml> [--dry-run]", file=sys.stderr)
        sys.exit(1)

    labels_path = sys.argv[1]
    if not Path(labels_path).exists():
        print(f"ERROR: File not found: {labels_path}", file=sys.stderr)
        sys.exit(1)

    commands = generate_commands(labels_path)
    for cmd in commands:
        print(cmd)


if __name__ == "__main__":
    main()
