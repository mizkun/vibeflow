#!/usr/bin/env python3
from __future__ import annotations
"""
VibeFlow Worker Handoff Packet Runtime
Generates, saves, and loads handoff packets for worker terminals.

A handoff packet contains everything a worker needs to execute a task:
- Source of truth (Issue number, repo)
- Goal and acceptance criteria
- Constraints (allowed/forbidden paths, file limit)
- Must-read files (from policy can_read)
- Validation commands
- Worker type (claude/codex/human, explicit only)
"""

import json
import os
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None


# Default forbidden paths — always blocked regardless of role
DEFAULT_FORBIDDEN_PATHS = [
    "plans/*",
    ".vibe/hooks/*",
    ".claude/settings.json",
]

# Default max files changed
DEFAULT_MAX_FILES = 20

# Default validation commands by task type
DEFAULT_VALIDATION = {
    "dev": ["npm test", "npm run lint"],
    "patch": ["npm test"],
    "spike": [],
    "ops": [],
}


def _load_policy(policy_path: str) -> dict:
    """Load policy.yaml and return as dict."""
    p = Path(policy_path)
    if not p.exists():
        return {}
    content = p.read_text(encoding="utf-8")
    if yaml:
        return yaml.safe_load(content) or {}
    # Minimal fallback — not sufficient for nested structures
    return {}


def _extract_task_type(labels: list[dict]) -> str:
    """Extract task type from labels (type:dev → dev)."""
    for label in labels:
        name = label.get("name", "")
        if name.startswith("type:"):
            return name.split(":", 1)[1]
    return "dev"


def _extract_acceptance_criteria(body: str) -> list[str]:
    """Extract acceptance criteria from Issue body.

    Looks for a ## Acceptance Criteria section and extracts list items.
    """
    if not body:
        return []

    # Find the AC section
    match = re.search(
        r"##\s*Acceptance\s+Criteria\s*\n(.*?)(?=\n##|\Z)",
        body,
        re.DOTALL | re.IGNORECASE,
    )
    if not match:
        return []

    section = match.group(1)
    criteria = []
    for line in section.splitlines():
        line = line.strip()
        # Match "- [ ] item", "- [x] item", "- item", "* item"
        m = re.match(r"^[-*]\s*(?:\[.\]\s*)?(.+)$", line)
        if m:
            criteria.append(m.group(1).strip())
    return criteria


def _get_role_permissions(policy: dict, role: str) -> tuple[list, list]:
    """Get (can_read, can_write) for a role from policy.

    Args:
        policy: Parsed policy.yaml dict
        role: Role ID (e.g., 'engineer', 'qa_engineer')

    Returns:
        Tuple of (can_read, can_write) lists
    """
    roles = policy.get("roles", {})
    role_def = roles.get(role, {})
    can_read = role_def.get("can_read", [])
    can_write = role_def.get("can_write", [])
    return can_read, can_write


def build_packet(
    issue: dict,
    repo: str,
    role: str,
    policy_path: str,
    worker_type: str,
) -> dict:
    """Build a handoff packet from Issue data and policy.

    Args:
        issue: Dict with number, title, body, labels
               (matches `gh issue view --json number,title,body,labels`)
        repo: Repository in "owner/repo" format
        role: Role ID for permission lookup (e.g., 'engineer')
        policy_path: Path to core/schema/policy.yaml
        worker_type: Worker type ('claude', 'codex', 'human')

    Returns:
        Handoff packet dict
    """
    issue_number = issue.get("number", 0)
    title = issue.get("title", "")
    body = issue.get("body") or ""
    labels = issue.get("labels") or []

    task_type = _extract_task_type(labels)
    task_id = f"task-{issue_number}-{task_type}"

    # Load policy for role permissions
    policy = _load_policy(policy_path)
    can_read, can_write = _get_role_permissions(policy, role)

    # Build constraints
    # Filter out state files from allowed_paths (they're always_allow, not work targets)
    state_patterns = {".vibe/project_state.yaml", ".vibe/sessions/*.yaml", ".vibe/state.yaml"}
    allowed_paths = [p for p in can_write if p not in state_patterns]

    # Forbidden paths: defaults, minus anything in allowed_paths
    forbidden_paths = list(DEFAULT_FORBIDDEN_PATHS)

    # must_read: from can_read, excluding state files and globs
    must_read = [p for p in can_read if p not in state_patterns]

    # Acceptance criteria
    acceptance_criteria = _extract_acceptance_criteria(body)

    # Validation commands
    validation_commands = list(DEFAULT_VALIDATION.get(task_type, []))

    return {
        "task_id": task_id,
        "task_type": task_type,
        "source_of_truth": {
            "issue_number": issue_number,
            "repo": repo,
        },
        "goal": title,
        "acceptance_criteria": acceptance_criteria,
        "constraints": {
            "allowed_paths": allowed_paths,
            "forbidden_paths": forbidden_paths,
            "max_files_changed": DEFAULT_MAX_FILES,
        },
        "must_read": must_read,
        "validation": {
            "required_commands": validation_commands,
        },
        "worker_type": worker_type,
        "artifacts": {
            "qa_report": None,
            "pr_number": None,
            "branch": None,
        },
    }


def save_packet(directory: str, packet: dict) -> str:
    """Save a handoff packet as JSON.

    Args:
        directory: Directory to save into
        packet: Handoff packet dict

    Returns:
        Path to the saved JSON file
    """
    p = Path(directory)
    p.mkdir(parents=True, exist_ok=True)

    task_id = packet.get("task_id", "unknown")
    filename = f"{task_id}.json"
    filepath = p / filename

    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(packet, f, indent=2, ensure_ascii=False)

    return str(filepath)


def load_packet(path: str) -> dict:
    """Load a handoff packet from a JSON file.

    Args:
        path: Path to the JSON file

    Returns:
        Handoff packet dict
    """
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)
