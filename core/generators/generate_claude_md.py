#!/usr/bin/env python3
"""
VibeFlow CLAUDE.md Partial Generator
Updates only VF:BEGIN/VF:END managed sections, preserving hand-written content.

Marker format:
    <!-- VF:BEGIN section_name -->
    ... generated content ...
    <!-- VF:END section_name -->

Usage:
    python3 core/generators/generate_claude_md.py --input CLAUDE.md --schema-dir core/schema --output CLAUDE.md
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

# Regex to match VF:BEGIN ... VF:END blocks
MARKER_RE = re.compile(
    r"(<!-- VF:BEGIN (\w+) -->)\n(.*?)(<!-- VF:END \2 -->)",
    re.DOTALL,
)


def load_schemas(schema_dir: str) -> dict:
    """Load all schema files from directory."""
    schema_path = Path(schema_dir)
    schemas = {}
    for name in ("policy", "workflow", "roles"):
        fpath = schema_path / f"{name}.yaml"
        if fpath.exists():
            with open(fpath) as f:
                schemas[name] = yaml.safe_load(f)
    return schemas


def generate_roles_section(schemas: dict) -> str:
    """Generate roles section content from schemas."""
    lines = []
    policy = schemas.get("policy", {})
    roles_schema = schemas.get("roles", {})

    for role_id, role_def in roles_schema.get("roles", {}).items():
        policy_def = policy.get("roles", {}).get(role_id, {})
        name = role_def.get("name", role_id)
        desc = role_def.get("description", "")
        can_write = policy_def.get("can_write", [])
        enforcement = policy_def.get("enforcement", "hard")

        lines.append(f"### {name}")
        lines.append(f"**Description**: {desc}")
        lines.append(f"**Enforcement**: {enforcement}")
        if can_write:
            lines.append("**Can Write**: " + ", ".join(f"`{p}`" for p in can_write))
        lines.append("")

    return "\n".join(lines)


def generate_workflow_section(schemas: dict) -> str:
    """Generate workflow section content from schemas."""
    lines = []
    workflows = schemas.get("workflow", {}).get("workflows", {})

    for wtype, wdef in workflows.items():
        desc = wdef.get("description", "")
        steps = wdef.get("steps", [])
        lines.append(f"### {wtype.title()} Workflow")
        lines.append(f"{desc}")
        lines.append("")
        lines.append("| Step | Role | Mode |")
        lines.append("|------|------|------|")
        for step in steps:
            lines.append(f"| {step['id']} | {step['role']} | {step['mode']} |")
        lines.append("")

    return "\n".join(lines)


SECTION_GENERATORS = {
    "roles": generate_roles_section,
    "workflow": generate_workflow_section,
}


def update_managed_sections(content: str, schemas: dict) -> str:
    """Replace content within VF:BEGIN/VF:END markers."""

    def replacer(match):
        begin_marker = match.group(1)
        section_name = match.group(2)
        end_marker = match.group(4)

        generator = SECTION_GENERATORS.get(section_name)
        if generator:
            new_content = generator(schemas)
        else:
            new_content = f"<!-- Unknown section: {section_name} -->"

        return f"{begin_marker}\n{new_content}\n{end_marker}"

    return MARKER_RE.sub(replacer, content)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate CLAUDE.md managed sections")
    parser.add_argument("--input", required=True, help="Input CLAUDE.md path")
    parser.add_argument("--schema-dir", required=True, help="Path to schema directory")
    parser.add_argument("--output", required=True, help="Output CLAUDE.md path")
    args = parser.parse_args()

    input_path = Path(args.input)
    if input_path.exists():
        content = input_path.read_text()
    else:
        content = ""

    schemas = load_schemas(args.schema_dir)

    # Only update existing markers — never auto-insert into markerless files
    if "VF:BEGIN" not in content:
        print(
            f"WARNING: {args.input} has no VF:BEGIN/VF:END markers. "
            f"Skipping generation. Add markers manually to enable managed sections.",
            file=sys.stderr,
        )
        # Write unchanged content if output differs from input
        if str(Path(args.output).resolve()) != str(input_path.resolve()):
            output_path = Path(args.output)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(content)
        sys.exit(0)

    content = update_managed_sections(content, schemas)

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content)

    print(f"Generated: {output_path}")


if __name__ == "__main__":
    main()
