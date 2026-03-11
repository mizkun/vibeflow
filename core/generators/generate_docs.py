#!/usr/bin/env python3
from __future__ import annotations
"""
VibeFlow Docs Generator
Generates role documentation from schema.

Usage:
    python3 core/generators/generate_docs.py --schema-dir core/schema --output <dir>
"""

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml is required.", file=sys.stderr)
    sys.exit(1)

try:
    from jinja2 import Environment, FileSystemLoader
except ImportError:
    print("ERROR: jinja2 is required.", file=sys.stderr)
    sys.exit(1)


def role_id_to_filename(role_id: str) -> str:
    """Convert role_id to filename: infra_manager -> infra-manager."""
    return role_id.replace("_", "-")


def generate_role_docs(schema_dir: str, output_dir: str) -> None:
    """Generate role markdown docs from roles.yaml + policy.yaml."""
    schema_path = Path(schema_dir)

    with open(schema_path / "roles.yaml") as f:
        roles_data = yaml.safe_load(f)

    with open(schema_path / "policy.yaml") as f:
        policy_data = yaml.safe_load(f)

    core_dir = Path(__file__).parent.parent
    templates_dir = core_dir / "templates"

    env = Environment(
        loader=FileSystemLoader(str(templates_dir)),
        keep_trailing_newline=True,
    )
    template = env.get_template("role.md.j2")

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    for role_id, role_def in roles_data.get("roles", {}).items():
        policy = policy_data.get("roles", {}).get(role_id, {})

        context = {
            "name": role_def.get("name", role_id),
            "description": role_def.get("description", ""),
            "responsibilities": role_def.get("responsibilities", []),
            "can_read": policy.get("can_read", []),
            "can_write": policy.get("can_write", []),
            "enforcement": policy.get("enforcement", "hard"),
        }

        filename = role_id_to_filename(role_id) + ".md"
        rendered = template.render(**context)
        (output_path / filename).write_text(rendered)

    print(f"Generated: {len(roles_data.get('roles', {}))} role docs in {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate role docs from schema")
    parser.add_argument("--schema-dir", required=True, help="Path to schema directory")
    parser.add_argument("--output", required=True, help="Output directory")
    args = parser.parse_args()

    generate_role_docs(args.schema_dir, args.output)


if __name__ == "__main__":
    main()
