#!/usr/bin/env python3
"""
VibeFlow Settings Generator
Generates .claude/settings.json from schema.

Usage:
    python3 core/generators/generate_settings.py --schema-dir core/schema --output <dir>
"""

import argparse
import sys
from pathlib import Path

try:
    from jinja2 import Environment, FileSystemLoader
except ImportError:
    print("ERROR: jinja2 is required. Install with: pip install jinja2", file=sys.stderr)
    sys.exit(1)


def generate_settings(schema_dir: str, output_dir: str) -> None:
    """Generate settings.json from template."""
    core_dir = Path(__file__).parent.parent
    templates_dir = core_dir / "templates"

    env = Environment(
        loader=FileSystemLoader(str(templates_dir)),
        keep_trailing_newline=True,
    )
    template = env.get_template("settings.json.j2")
    rendered = template.render()

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    (output_path / "settings.json").write_text(rendered)

    print(f"Generated: {output_path / 'settings.json'}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate settings.json from schema")
    parser.add_argument("--schema-dir", required=True, help="Path to schema directory")
    parser.add_argument("--output", required=True, help="Output directory")
    args = parser.parse_args()

    generate_settings(args.schema_dir, args.output)


if __name__ == "__main__":
    main()
