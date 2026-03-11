#!/usr/bin/env python3
from __future__ import annotations
"""
VibeFlow Codex Implementation Runtime
Handles packet loading, diff validation, and validation command execution.
"""

import json
import subprocess
from fnmatch import fnmatch
from pathlib import Path


def load_and_validate_packet(packet_path: str) -> dict:
    """Load a handoff packet JSON and validate it for codex worker.

    Args:
        packet_path: Path to the handoff packet JSON file

    Returns:
        Parsed packet dict

    Raises:
        FileNotFoundError: If packet file doesn't exist
        ValueError: If packet is invalid or worker_type is not 'codex'
    """
    path = Path(packet_path)
    if not path.exists():
        raise FileNotFoundError(f"Packet not found: {packet_path}")

    with open(path, encoding="utf-8") as f:
        packet = json.load(f)

    required = ("task_id", "task_type", "goal", "worker_type")
    missing = [k for k in required if k not in packet]
    if missing:
        raise ValueError(f"Packet missing required fields: {missing}")

    if packet.get("worker_type") != "codex":
        raise ValueError(
            f"Expected worker_type='codex', got '{packet.get('worker_type')}'"
        )

    return packet


def make_branch_name(task_id: str) -> str:
    """Generate a branch name from a task ID.

    Args:
        task_id: Task identifier (e.g., 'task-42-dev')

    Returns:
        Branch name in vf/<task_id> format
    """
    return f"vf/{task_id}"


def validate_diff(changed_files: list, constraints: dict) -> list:
    """Validate changed files against packet constraints.

    Args:
        changed_files: List of changed file paths (relative)
        constraints: Dict with allowed_paths, forbidden_paths, max_files_changed

    Returns:
        List of error strings (empty if all valid)
    """
    errors = []
    allowed = constraints.get("allowed_paths", [])
    forbidden = constraints.get("forbidden_paths", [])
    max_files = constraints.get("max_files_changed")

    # Check max files
    if max_files is not None and len(changed_files) > max_files:
        errors.append(
            f"max_files_changed exceeded: {len(changed_files)} > {max_files}"
        )

    for f in changed_files:
        # Check forbidden paths
        for pattern in forbidden:
            if fnmatch(f, pattern):
                errors.append(f"Forbidden path modified: {f} (matches {pattern})")
                break

        # Check allowed paths (if specified, file must match at least one)
        if allowed:
            matched = any(fnmatch(f, pat) for pat in allowed)
            if not matched:
                errors.append(f"File not in allowed_paths: {f}")

    return errors


def run_validation(commands: list, cwd: str = ".") -> list:
    """Run validation commands and collect errors.

    Args:
        commands: List of shell commands to run
        cwd: Working directory for command execution

    Returns:
        List of error strings for failed commands (empty if all pass)
    """
    errors = []
    for cmd in commands:
        try:
            subprocess.run(
                cmd,
                shell=True,
                cwd=cwd,
                check=True,
                capture_output=True,
                text=True,
            )
        except subprocess.CalledProcessError as e:
            errors.append(f"Validation command failed: {cmd} (exit {e.returncode})")
    return errors
