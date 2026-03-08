#!/usr/bin/env python3
"""
VibeFlow Hook Generator
Generates validate_access.py from core/schema/policy.yaml.

Usage:
    python3 core/generators/generate_hooks.py --schema core/schema/policy.yaml --output <dir>

Requires: Python 3.8+, pyyaml, jinja2
"""

import argparse
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml is required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

try:
    from jinja2 import Environment, FileSystemLoader
except ImportError:
    print("ERROR: jinja2 is required. Install with: pip install jinja2", file=sys.stderr)
    sys.exit(1)


def load_policy(schema_path: str) -> dict:
    """Load and return policy schema."""
    with open(schema_path) as f:
        return yaml.safe_load(f)


def build_template_context(policy: dict) -> dict:
    """Build Jinja2 template context from policy schema."""
    roles = []
    for role_id, role_def in policy.get("roles", {}).items():
        roles.append(
            {
                "id": role_id,
                "display_name": role_def.get("display_name", role_id),
                "description": "",
                "can_write": role_def.get("can_write", []),
            }
        )

    always_allow = policy.get("always_allow", [])

    return {
        "roles": roles,
        "always_allow": always_allow,
    }


def generate_validate_access(schema_path: str, output_dir: str) -> None:
    """Generate validate_access.py from policy schema."""
    policy = load_policy(schema_path)

    # Locate templates directory
    generators_dir = Path(__file__).parent
    core_dir = generators_dir.parent
    templates_dir = core_dir / "templates"

    env = Environment(
        loader=FileSystemLoader(str(templates_dir)),
        keep_trailing_newline=True,
    )
    template = env.get_template("validate_access.py.j2")

    context = build_template_context(policy)
    rendered = template.render(**context)

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    (output_path / "validate_access.py").write_text(rendered)

    print(f"Generated: {output_path / 'validate_access.py'}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate hook files from schema")
    parser.add_argument(
        "--schema",
        required=True,
        help="Path to policy.yaml schema file",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output directory for generated files",
    )
    args = parser.parse_args()

    generate_validate_access(args.schema, args.output)


if __name__ == "__main__":
    main()
