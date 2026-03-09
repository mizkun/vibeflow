#!/usr/bin/env python3
"""
VibeFlow Policy Generator
Generates project-side .vibe/policy.yaml from core/schema/policy.yaml.
The generated file is full-fidelity: includes enforcement, display_name, and human role.

Usage:
    python3 core/generators/generate_policy.py --schema core/schema/policy.yaml --output <dir>
"""

import argparse
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml is required.", file=sys.stderr)
    sys.exit(1)


def generate_policy(schema_path: str, output_dir: str) -> None:
    """Generate project-side policy.yaml from schema."""
    with open(schema_path) as f:
        schema = yaml.safe_load(f)

    # Build project-side policy preserving all fields
    output = {
        "# VibeFlow Role-Based Access Policy": None,
        "# Generated from core/schema/policy.yaml — do not edit manually": None,
    }

    project_policy = {"roles": {}}
    for role_id, role_def in schema.get("roles", {}).items():
        project_policy["roles"][role_id] = {
            "display_name": role_def.get("display_name", role_id),
            "can_read": role_def.get("can_read", []),
            "can_write": role_def.get("can_write", []),
            "enforcement": role_def.get("enforcement", "hard"),
        }

    project_policy["always_allow"] = schema.get("always_allow", [])

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    policy_file = output_path / "policy.yaml"
    with open(policy_file, "w") as f:
        f.write("# VibeFlow Role-Based Access Policy\n")
        f.write("# Generated from core/schema/policy.yaml — do not edit manually\n")
        yaml.dump(project_policy, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

    print(f"Generated: {policy_file}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate project policy.yaml from schema")
    parser.add_argument("--schema", required=True, help="Path to core/schema/policy.yaml")
    parser.add_argument("--output", required=True, help="Output directory")
    args = parser.parse_args()

    generate_policy(args.schema, args.output)


if __name__ == "__main__":
    main()
