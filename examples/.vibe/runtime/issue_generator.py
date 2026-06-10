"""Issue Auto-Generation for VibeFlow v6 Iris-Only Architecture.

Generates GitHub Issues from Plan/Spec content.
Auto-assigns labels (type, qa) and formats for user review.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List

# UI detection is shared with qa_judge / dispatcher via ui_task.py.
try:
    from core.runtime.ui_task import text_mentions_ui
except ImportError:  # flat .vibe/runtime/ deployment
    from ui_task import text_mentions_ui

_FIX_KEYWORDS = ["fix", "bug", "patch", "修正", "バグ"]
_CHORE_KEYWORDS = ["chore", "refactor", "cleanup", "lint", "docs", "リファクタ"]


def title_is_ui(title: str) -> bool:
    """True if an issue title suggests UI work (shared ui_task logic)."""
    return text_mentions_ui(title)


def generate_issues(plan_text: str) -> List[Dict[str, Any]]:
    """Generate issue dicts from plan markdown text.

    Parses plan items (TODO checkboxes, bullet points under milestones)
    and creates issue dicts with auto-assigned labels.

    Args:
        plan_text: Markdown text from plan.md

    Returns:
        List of issue dicts with title, body, labels, milestone,
        and acceptance_criteria.
    """
    issues: List[Dict[str, Any]] = []
    current_milestone = ""

    for line in plan_text.strip().split("\n"):
        line = line.strip()

        # Detect milestone headers
        milestone_match = re.match(r"^##\s+(?:Milestone\s+\d+:\s*)?(.+)", line)
        if milestone_match:
            current_milestone = milestone_match.group(1).strip()
            continue

        # Detect TODO items
        item_match = re.match(r"^-\s+\[[ x]\]\s+(.+)", line)
        if not item_match:
            # Also match plain bullet items
            item_match = re.match(r"^-\s+(.+)", line)
        if not item_match:
            continue

        title = item_match.group(1).strip()
        if not title:
            continue

        labels = _auto_labels(title)
        issue = {
            "title": title,
            "body": f"Auto-generated from plan.\n\nMilestone: {current_milestone}" if current_milestone else "Auto-generated from plan.",
            "labels": labels,
            "milestone": current_milestone,
            "acceptance_criteria": [f"{title} is implemented and tested"],
        }
        issues.append(issue)

    return issues


def _auto_labels(title: str) -> List[str]:
    """Auto-assign labels based on title keywords."""
    labels: List[str] = []
    title_lower = title.lower()

    # Type label
    if any(kw in title_lower for kw in _FIX_KEYWORDS):
        labels.append("type:fix")
    elif any(kw in title_lower for kw in _CHORE_KEYWORDS):
        labels.append("type:chore")
    else:
        labels.append("type:dev")

    # QA label
    if title_is_ui(title):
        labels.append("qa:manual")
    else:
        labels.append("qa:auto")

    return labels


def format_issue(issue: Dict[str, Any]) -> str:
    """Format an issue dict into a human-readable summary for review.

    Args:
        issue: Issue dict with title, body, labels, milestone.

    Returns:
        Formatted string for user review.
    """
    lines = [
        f"### {issue['title']}",
        "",
        f"**Labels:** {', '.join(issue.get('labels', []))}",
    ]

    if issue.get("milestone"):
        lines.append(f"**Milestone:** {issue['milestone']}")

    if issue.get("body"):
        lines.append(f"\n{issue['body']}")

    criteria = issue.get("acceptance_criteria", [])
    if criteria:
        lines.append("\n**Acceptance Criteria:**")
        for c in criteria:
            lines.append(f"- [ ] {c}")

    return "\n".join(lines)
