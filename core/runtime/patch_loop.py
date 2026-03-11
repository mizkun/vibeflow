#!/usr/bin/env python3
from __future__ import annotations
"""
VibeFlow Patch Loop Runtime
Lightweight fix workflow for scoped changes tied to a parent Issue/PR.

Key constraints:
- Parent Issue is required (standalone patches are not allowed)
- Parent PR is optional (auto-detected if available)
- Target tests are required (no-test fixes belong in Standard Issue)
- File count and scope are limited; exceeding limits triggers escalation
- State is recorded in project_state.yaml under patch_runs

Statuses: in_progress → completed | escalated
"""

import json
import subprocess

from core.runtime.state import read_project_state, write_project_state

# Limits — exceeding these suggests the fix is too large for Patch Loop
DEFAULT_FILE_LIMIT = 10


def detect_parent_pr(issue_number: int) -> int | None:
    """Auto-detect a PR linked to the given issue number.

    Uses `gh pr list` to find open PRs whose body or title references
    the issue. Returns the first matching PR number, or None.
    """
    try:
        result = subprocess.run(
            [
                "gh", "pr", "list",
                "--search", f"#{issue_number}",
                "--json", "number",
                "--limit", "1",
            ],
            capture_output=True, text=True, timeout=10,
        )
        if result.returncode != 0:
            return None
        prs = json.loads(result.stdout)
        if prs:
            return prs[0]["number"]
    except (subprocess.TimeoutExpired, FileNotFoundError, json.JSONDecodeError,
            KeyError, IndexError):
        pass
    return None


def _next_patch_seq(patch_runs: list, parent_issue: int) -> int:
    """Get the next sequence number for patches on a given parent issue."""
    existing = [
        r for r in patch_runs
        if r.get("parent_issue") == parent_issue
    ]
    return len(existing) + 1


def create_patch(
    project_dir: str,
    parent_issue: int | None,
    description: str,
    target_files: list[str],
    target_tests: list[str] | None = None,
    parent_pr: int | None = None,
    pr_detector=None,
) -> dict:
    """Create a new Patch Loop run.

    Args:
        project_dir: Project root directory
        parent_issue: Parent GitHub Issue number (required)
        description: Short description of the fix
        target_files: List of files to modify
        target_tests: List of test files to run (required, non-empty)
        parent_pr: Parent PR number (optional; auto-detected if None)
        pr_detector: Callable(issue_number) → int|None for PR detection.
                     Defaults to detect_parent_pr. Pass a mock for testing.

    Returns:
        Patch run dict with patch_id, status, etc.

    Raises:
        ValueError: If parent_issue is None or target_tests is empty
    """
    if parent_issue is None:
        raise ValueError(
            "Patch Loop requires a parent Issue. "
            "Standalone fixes are not allowed — create a Standard Issue first."
        )

    if not target_tests:
        raise ValueError(
            "Patch Loop requires target tests. "
            "対象テストを指定してください。指定できない場合は Standard Issue を検討してください。"
        )

    # Auto-detect parent PR if not explicitly provided
    if parent_pr is None:
        detector = pr_detector or detect_parent_pr
        parent_pr = detector(parent_issue)

    # Read current state
    ps = read_project_state(project_dir)
    patch_runs = ps.get("patch_runs") or []
    if not isinstance(patch_runs, list):
        patch_runs = []

    # Generate patch_id
    seq = _next_patch_seq(patch_runs, parent_issue)
    patch_id = f"patch-{parent_issue}-{seq}"

    # Check file limit for escalation
    status = "in_progress"
    escalation_reason = None

    if len(target_files) > DEFAULT_FILE_LIMIT:
        status = "escalated"
        escalation_reason = (
            f"Target file count ({len(target_files)}) exceeds limit ({DEFAULT_FILE_LIMIT}). "
            f"Consider creating a Standard Issue instead."
        )

    patch = {
        "patch_id": patch_id,
        "parent_issue": parent_issue,
        "parent_pr": parent_pr,
        "description": description,
        "target_files": target_files,
        "target_tests": target_tests,
        "status": status,
    }

    if escalation_reason:
        patch["escalation_reason"] = escalation_reason

    # Record in project state
    patch_runs.append(patch)
    ps["patch_runs"] = patch_runs
    write_project_state(project_dir, ps)

    return patch


def complete_patch(project_dir: str, patch_id: str) -> dict:
    """Mark a patch run as completed.

    Args:
        project_dir: Project root directory
        patch_id: ID of the patch to complete

    Returns:
        Updated patch dict

    Raises:
        ValueError: If patch_id is not found
    """
    ps = read_project_state(project_dir)
    patch_runs = ps.get("patch_runs") or []

    for patch in patch_runs:
        if patch.get("patch_id") == patch_id:
            patch["status"] = "completed"
            ps["patch_runs"] = patch_runs
            write_project_state(project_dir, ps)
            return patch

    raise ValueError(f"Patch '{patch_id}' not found in patch_runs")


def escalate_patch(project_dir: str, patch_id: str, reason: str) -> dict:
    """Mark a patch run as escalated (needs Standard Issue).

    Args:
        project_dir: Project root directory
        patch_id: ID of the patch to escalate
        reason: Why this patch needs escalation

    Returns:
        Updated patch dict

    Raises:
        ValueError: If patch_id is not found
    """
    ps = read_project_state(project_dir)
    patch_runs = ps.get("patch_runs") or []

    for patch in patch_runs:
        if patch.get("patch_id") == patch_id:
            patch["status"] = "escalated"
            patch["escalation_reason"] = reason
            ps["patch_runs"] = patch_runs
            write_project_state(project_dir, ps)
            return patch

    raise ValueError(f"Patch '{patch_id}' not found in patch_runs")
