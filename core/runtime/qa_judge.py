"""QA Judgment Automation for VibeFlow v5 Iris-Only Architecture.

Determines whether an issue can be auto-closed or needs human review.
"""

from typing import Any, Dict, List

# Thresholds
MAX_FILES_AUTO = 5
MAX_LINES_AUTO = 200


def judge(context: Dict[str, Any]) -> Dict[str, Any]:
    """Judge whether an issue passes QA automatically.

    Args:
        context: Dict with:
            - labels: list of str (e.g., ['type:fix', 'risk:low', 'qa:auto'])
            - tests_passed: bool
            - review_verdict: str ('pass', 'warn', 'fail')
            - files_changed: int
            - lines_changed: int
            - has_ui_changes: bool (optional)

    Returns:
        Dict with:
            - verdict: 'auto_pass' | 'needs_human' | 'fail'
            - needs_human: bool
            - reason: str
    """
    labels = context.get("labels", [])
    tests_passed = context.get("tests_passed", False)
    review_verdict = context.get("review_verdict", "unknown")
    files_changed = context.get("files_changed", 0)
    lines_changed = context.get("lines_changed", 0)
    has_ui_changes = context.get("has_ui_changes", False)

    reasons: List[str] = []

    # Hard fail: tests didn't pass
    if not tests_passed:
        return {
            "verdict": "fail",
            "needs_human": False,
            "reason": "Tests failed",
        }

    # Hard fail: review failed
    if review_verdict == "fail":
        return {
            "verdict": "fail",
            "needs_human": False,
            "reason": "Code review failed",
        }

    # Check conditions that require human review
    needs_human = False

    # UI changes always need human
    if has_ui_changes:
        needs_human = True
        reasons.append("UI changes require visual verification")

    # qa:manual label
    if "qa:manual" in labels:
        needs_human = True
        reasons.append("Issue labeled qa:manual")

    # High risk
    if "risk:high" in labels:
        needs_human = True
        reasons.append("High risk change")

    # Large diff
    if files_changed > MAX_FILES_AUTO or lines_changed > MAX_LINES_AUTO:
        needs_human = True
        reasons.append(
            f"Large diff ({files_changed} files, {lines_changed} lines)"
        )

    # Security-related
    security_labels = [l for l in labels if "security" in l.lower() or "auth" in l.lower()]
    if security_labels:
        needs_human = True
        reasons.append("Security-related changes")

    if needs_human:
        return {
            "verdict": "needs_human",
            "needs_human": True,
            "reason": "; ".join(reasons),
        }

    # Auto pass
    return {
        "verdict": "auto_pass",
        "needs_human": False,
        "reason": "All checks passed: tests OK, review OK, within auto-close thresholds",
    }
