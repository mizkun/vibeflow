#!/usr/bin/env python3
"""
VibeFlow Schema Validator
Validates core/schema/*.yaml files against expected structure.
Uses pyyaml + manual validation (no JSON Schema dependency).

Requires: Python 3.8+, pyyaml

Usage:
    python3 core/validators/schema_validate.py core/schema/policy.yaml
    python3 core/validators/schema_validate.py core/schema/workflow.yaml
    python3 core/validators/schema_validate.py core/schema/roles.yaml
"""

import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml is required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


def validate_policy(data: dict) -> list[str]:
    """Validate policy.yaml structure."""
    errors = []

    roles = data.get("roles")
    if not isinstance(roles, dict):
        return ["Top-level 'roles' must be a mapping"]

    required_roles = {"iris", "product_manager", "engineer", "qa_engineer", "infra_manager", "human"}
    missing = required_roles - set(roles.keys())
    if missing:
        errors.append(f"Missing required roles: {missing}")

    valid_enforcement = {"hard", "soft"}
    for role_id, role in roles.items():
        if not isinstance(role, dict):
            errors.append(f"{role_id}: must be a mapping")
            continue
        for field in ("display_name", "can_read", "can_write", "enforcement"):
            if field not in role:
                errors.append(f"{role_id}: missing required field '{field}'")
        if "enforcement" in role and role["enforcement"] not in valid_enforcement:
            errors.append(
                f"{role_id}: enforcement must be 'hard' or 'soft', got '{role['enforcement']}'"
            )
        for list_field in ("can_read", "can_write"):
            if list_field in role and not isinstance(role[list_field], list):
                errors.append(f"{role_id}: {list_field} must be a list")

    return errors


def validate_workflow(data: dict) -> list[str]:
    """Validate workflow.yaml structure."""
    errors = []

    workflows = data.get("workflows")
    if not isinstance(workflows, dict):
        return ["Top-level 'workflows' must be a mapping"]

    valid_modes = {"solo", "team", "fork", "checkpoint", "review_worker"}

    for wtype, wdef in workflows.items():
        if not isinstance(wdef, dict):
            errors.append(f"{wtype}: must be a mapping")
            continue
        if "description" not in wdef:
            errors.append(f"{wtype}: missing 'description'")
        steps = wdef.get("steps")
        if not isinstance(steps, list):
            errors.append(f"{wtype}: 'steps' must be a list")
            continue
        for step in steps:
            if not isinstance(step, dict):
                errors.append(f"{wtype}: each step must be a mapping")
                continue
            for field in ("id", "role", "mode"):
                if field not in step:
                    errors.append(f"{wtype}.{step.get('id', '?')}: missing '{field}'")
            mode = step.get("mode", "")
            if mode and mode not in valid_modes:
                errors.append(
                    f"{wtype}.{step.get('id', '?')}: invalid mode '{mode}'"
                )

    return errors


def validate_roles(data: dict) -> list[str]:
    """Validate roles.yaml structure."""
    errors = []

    roles = data.get("roles")
    if not isinstance(roles, dict):
        return ["Top-level 'roles' must be a mapping"]

    for role_id, role in roles.items():
        if not isinstance(role, dict):
            errors.append(f"{role_id}: must be a mapping")
            continue
        for field in ("name", "description", "responsibilities"):
            if field not in role:
                errors.append(f"{role_id}: missing required field '{field}'")
        if "responsibilities" in role and not isinstance(role["responsibilities"], list):
            errors.append(f"{role_id}: responsibilities must be a list")

    return errors


def detect_schema_type(filepath: str) -> str:
    """Detect schema type from filename."""
    name = Path(filepath).stem
    if name == "policy":
        return "policy"
    elif name == "workflow":
        return "workflow"
    elif name == "roles":
        return "roles"
    return "unknown"


def validate_cross(schema_dir: str) -> list[str]:
    """Cross-file validation: workflow roles must exist in policy and roles schemas."""
    errors = []
    schema_path = Path(schema_dir)

    files = {}
    for name in ("policy", "workflow", "roles"):
        fpath = schema_path / f"{name}.yaml"
        if not fpath.exists():
            errors.append(f"Missing schema file: {fpath}")
            continue
        with open(fpath) as f:
            files[name] = yaml.safe_load(f)

    if errors:
        return errors

    policy_roles = set(files["policy"].get("roles", {}).keys())
    roles_roles = set(files["roles"].get("roles", {}).keys())

    # Check workflow role references
    for wtype, wdef in files["workflow"].get("workflows", {}).items():
        for step in wdef.get("steps", []):
            role = step.get("role", "")
            if role not in policy_roles:
                errors.append(f"workflow.{wtype}.{step['id']}: role '{role}' not in policy.yaml")
            if role not in roles_roles:
                errors.append(f"workflow.{wtype}.{step['id']}: role '{role}' not in roles.yaml")

    # Check policy ↔ roles consistency
    missing_in_roles = policy_roles - roles_roles
    missing_in_policy = roles_roles - policy_roles
    if missing_in_roles:
        errors.append(f"In policy.yaml but not roles.yaml: {missing_in_roles}")
    if missing_in_policy:
        errors.append(f"In roles.yaml but not policy.yaml: {missing_in_policy}")

    return errors


def main() -> None:
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <schema.yaml> | --cross <schema_dir>", file=sys.stderr)
        sys.exit(1)

    # Cross-file validation mode
    if sys.argv[1] == "--cross":
        if len(sys.argv) < 3:
            print(f"Usage: {sys.argv[0]} --cross <schema_dir>", file=sys.stderr)
            sys.exit(1)
        errors = validate_cross(sys.argv[2])
        if errors:
            print("Cross-file validation failed:", file=sys.stderr)
            for err in errors:
                print(f"  - {err}", file=sys.stderr)
            sys.exit(1)
        print(f"OK: cross-file validation for {sys.argv[2]}")
        sys.exit(0)

    filepath = sys.argv[1]
    try:
        with open(filepath) as f:
            data = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"ERROR: File not found: {filepath}", file=sys.stderr)
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"ERROR: Invalid YAML: {e}", file=sys.stderr)
        sys.exit(1)

    if not isinstance(data, dict):
        print("ERROR: Schema must be a YAML mapping", file=sys.stderr)
        sys.exit(1)

    schema_type = detect_schema_type(filepath)
    validators = {
        "policy": validate_policy,
        "workflow": validate_workflow,
        "roles": validate_roles,
    }

    validator = validators.get(schema_type)
    if not validator:
        print(f"ERROR: Unknown schema type for '{filepath}'", file=sys.stderr)
        sys.exit(1)

    errors = validator(data)
    if errors:
        print(f"Validation failed for {filepath}:", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)

    print(f"OK: {filepath}")


if __name__ == "__main__":
    main()
