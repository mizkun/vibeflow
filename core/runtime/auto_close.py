"""Issue Auto-Close for VibeFlow v5 Iris-Only Architecture.
from __future__ import annotations
Determines if an issue can be auto-closed and generates closure summaries.
qa:auto issues close automatically; qa:manual issues wait for human.
"""

from typing import Any, Dict


def should_auto_close(context: Dict[str, Any]) -> Dict[str, Any]:
    """Determine if an issue should be auto-closed.

    Args:
        context: Dict with:
            - labels: list of str
            - tests_passed: bool
            - review_verdict: str ('pass', 'warn', 'fail')
            - pr_merged: bool

    Returns:
        Dict with can_close, needs_human, reason.
    """
    labels = context.get("labels", [])
    tests_passed = context.get("tests_passed", False)
    review_verdict = context.get("review_verdict", "unknown")
    pr_merged = context.get("pr_merged", False)

    # PR must be merged
    if not pr_merged:
        return {
            "can_close": False,
            "needs_human": False,
            "reason": "PR not yet merged",
        }

    # Tests must pass
    if not tests_passed:
        return {
            "can_close": False,
            "needs_human": False,
            "reason": "Tests not passed",
        }

    # Review must pass
    if review_verdict not in ("pass", "warn"):
        return {
            "can_close": False,
            "needs_human": False,
            "reason": f"Review verdict: {review_verdict}",
        }

    # qa:manual requires human confirmation
    if "qa:manual" in labels:
        return {
            "can_close": False,
            "needs_human": True,
            "reason": "qa:manual — waiting for human confirmation",
        }

    # qa:auto can auto-close
    return {
        "can_close": True,
        "needs_human": False,
        "reason": "All checks passed, auto-closing",
    }


def close_issue(
    issue_number: int,
    repo: str = "",
    dry_run: bool = True,
) -> Dict[str, Any]:
    """Close a GitHub issue.

    Args:
        issue_number: GitHub issue number.
        repo: Repository in owner/repo format.
        dry_run: If True, don't actually close.

    Returns:
        Dict with status and command used.
    """
    cmd = f"gh issue close {issue_number}"
    if repo:
        cmd += f" -R {repo}"

    if dry_run:
        return {
            "status": "dry_run",
            "command": cmd,
            "issue_number": issue_number,
        }

    import subprocess

    try:
        subprocess.run(cmd.split(), check=True, capture_output=True)
        return {
            "status": "closed",
            "command": cmd,
            "issue_number": issue_number,
        }
    except subprocess.CalledProcessError as e:
        return {
            "status": "error",
            "command": cmd,
            "issue_number": issue_number,
            "error": str(e),
        }


def generate_summary(context: Dict[str, Any]) -> str:
    """Generate a closure summary for the user.

    Args:
        context: Dict with issue_number, title, agent, pr_number,
                 tests_passed, review_verdict.

    Returns:
        Formatted summary string.
    """
    issue_num = context.get("issue_number", "?")
    title = context.get("title", "Unknown")
    agent = context.get("agent", "unknown")
    pr_num = context.get("pr_number", "?")
    tests = context.get("tests_passed", False)
    review = context.get("review_verdict", "unknown")

    test_icon = "✅" if tests else "❌"
    review_icon = "✅" if review == "pass" else "⚠️" if review == "warn" else "❌"

    return (
        f"## Issue #{issue_num}: {title}\n\n"
        f"- **Agent:** {agent}\n"
        f"- **PR:** #{pr_num}\n"
        f"- **Tests:** {test_icon}\n"
        f"- **Review:** {review_icon} ({review})\n"
        f"- **Status:** Closed ✅\n"
    )
