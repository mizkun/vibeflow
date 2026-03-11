#!/usr/bin/env python3
from __future__ import annotations
"""
VibeFlow Definition of Ready (DoR) Gate
Validates that a GitHub Issue meets minimum requirements before starting work.

Input: Issue data dict (from `gh issue view --json title,body,labels`)
Output: Structured result with passed/hard_blocks/warnings

Hard blocks prevent work from starting.
Warnings are informational but do not block.
"""

import re


# Label prefixes for required/recommended categories
TYPE_PREFIX = "type:"
WORKFLOW_PREFIX = "workflow:"
RISK_PREFIX = "risk:"
QA_PREFIX = "qa:"

# Body sections checked as warnings
_SECTION_CHECKS = [
    ("acceptance_criteria", r"##\s*Acceptance\s+Criteria"),
    ("file_locations", r"##\s*File\s+Locations"),
    ("testing_requirements", r"##\s*Testing\s+Requirements"),
]


def _has_label_prefix(labels: list[dict], prefix: str) -> bool:
    """Check if any label starts with the given prefix."""
    return any(
        label.get("name", "").startswith(prefix)
        for label in labels
    )


def check_dor(issue: dict) -> dict:
    """Check if an issue meets the Definition of Ready.

    Args:
        issue: Dict with keys 'title', 'body', 'labels'.
               Labels is a list of dicts with 'name' key.
               (Matches `gh issue view --json title,body,labels` output.)

    Returns:
        Dict with:
        - passed (bool): True if no hard blocks
        - hard_blocks (list): List of {field, message} dicts
        - warnings (list): List of {field, message} dicts
    """
    title = issue.get("title") or ""
    body = issue.get("body") or ""
    labels = issue.get("labels") or []

    hard_blocks = []
    warnings = []

    # ── Hard blocks ──
    if not title.strip():
        hard_blocks.append({
            "field": "title",
            "message": "Issue title is required",
        })

    if not body.strip():
        hard_blocks.append({
            "field": "body",
            "message": "Issue body is required",
        })

    if not _has_label_prefix(labels, TYPE_PREFIX):
        hard_blocks.append({
            "field": "type_label",
            "message": "A type: label is required (type:dev, type:patch, type:spike, type:ops)",
        })

    if not _has_label_prefix(labels, WORKFLOW_PREFIX):
        hard_blocks.append({
            "field": "workflow_label",
            "message": "A workflow: label is required (workflow:standard, workflow:patch, etc.)",
        })

    # ── Warnings (only check if body exists) ──
    if not _has_label_prefix(labels, RISK_PREFIX):
        warnings.append({
            "field": "risk",
            "message": "No risk: label found. Consider adding risk:low/medium/high.",
        })

    if not _has_label_prefix(labels, QA_PREFIX):
        warnings.append({
            "field": "qa",
            "message": "No qa: label found. Consider adding qa:auto or qa:manual.",
        })

    if body.strip():
        for field, pattern in _SECTION_CHECKS:
            if not re.search(pattern, body, re.IGNORECASE):
                warnings.append({
                    "field": field,
                    "message": f"Missing '## {field.replace('_', ' ').title()}' section in body.",
                })

    return {
        "passed": len(hard_blocks) == 0,
        "hard_blocks": hard_blocks,
        "warnings": warnings,
    }
