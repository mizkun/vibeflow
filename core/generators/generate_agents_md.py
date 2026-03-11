#!/usr/bin/env python3
from __future__ import annotations
"""
VibeFlow AGENTS.md Generator
Generates Codex instruction layer from schema files.

Uses the same schema sources as CLAUDE.md generation (policy.yaml,
workflow.yaml, roles.yaml) to ensure consistency across worker types.

Usage:
    python3 core/generators/generate_agents_md.py --schema-dir core/schema --output examples/AGENTS.md
"""

import argparse
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


def load_schemas(schema_dir: str) -> dict:
    """Load all schema files needed for AGENTS.md generation."""
    schema_path = Path(schema_dir)
    schemas = {}

    for name in ("policy", "workflow", "roles"):
        fpath = schema_path / f"{name}.yaml"
        if fpath.exists():
            with open(fpath) as f:
                schemas[name] = yaml.safe_load(f) or {}

    return schemas


def generate_agents_md(schema_dir: str, output_path: str) -> str:
    """Generate AGENTS.md from schema files.

    Args:
        schema_dir: Path to core/schema directory
        output_path: Path to write AGENTS.md

    Returns:
        Generated content string
    """
    schemas = load_schemas(schema_dir)

    # Prepare template context
    roles_schema = schemas.get("roles", {})
    policy_schema = schemas.get("policy", {})
    workflow_schema = schemas.get("workflow", {})

    roles = roles_schema.get("roles", {})
    policy_roles = policy_schema.get("roles", {})
    workflows = workflow_schema.get("workflows", {})

    # Load Jinja2 template
    templates_dir = Path(__file__).parent.parent / "templates"
    env = Environment(
        loader=FileSystemLoader(str(templates_dir)),
        keep_trailing_newline=True,
    )
    template = env.get_template("AGENTS.md.j2")

    content = template.render(
        roles=roles,
        policy_roles=policy_roles,
        workflows=workflows,
    )

    # Write output
    out = Path(output_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content)

    print(f"Generated: {out}")
    return content


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate AGENTS.md from schema")
    parser.add_argument("--schema-dir", required=True, help="Path to schema directory")
    parser.add_argument("--output", required=True, help="Output AGENTS.md path")
    args = parser.parse_args()

    generate_agents_md(args.schema_dir, args.output)


if __name__ == "__main__":
    main()
