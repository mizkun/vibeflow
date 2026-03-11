"""QA Judgment Automation for VibeFlow v5 Iris-Only Architecture.
from __future__ import annotations
Determines whether an issue can be auto-closed or needs human review.
UI tasks require Playwright artifacts and are routed to needs_human.
"""

from typing import Any, Dict, List

# Thresholds
MAX_FILES_AUTO = 5
MAX_LINES_AUTO = 200

# File extensions that indicate UI changes
UI_FILE_EXTENSIONS = {
    ".tsx", ".jsx", ".vue", ".svelte", ".html",
    ".css", ".scss", ".less", ".sass",
}

# Keywords in issue title/body that indicate UI task
UI_KEYWORDS = [
    "ui", "page", "screen", "component", "layout", "design",
    "css", "style", "button", "form", "modal", "dialog",
    "animation", "responsive", "dashboard",
    "画面", "表示", "デザイン", "ダッシュボード", "レイアウト",
    "コンポーネント", "ボタン", "フォーム", "モーダル",
]


def is_ui_task(context: Dict[str, Any]) -> bool:
    """Determine if the task involves UI changes.

    Args:
        context: Dict with optional keys:
            - has_ui_changes: bool (explicit flag)
            - changed_files: list of file paths
            - issue_title: str
            - issue_body: str
            - labels: list of str

    Returns:
        True if the task is a UI task.
    """
    # Explicit flag
    if context.get("has_ui_changes"):
        return True

    # Check changed file extensions
    changed_files = context.get("changed_files", [])
    for f in changed_files:
        for ext in UI_FILE_EXTENSIONS:
            if f.endswith(ext):
                return True

    # Check issue title/body for UI keywords
    title = context.get("issue_title", "").lower()
    body = context.get("issue_body", "").lower()
    text = f"{title} {body}"
    for kw in UI_KEYWORDS:
        if kw in text:
            return True

    return False


def judge(context: Dict[str, Any]) -> Dict[str, Any]:
    """Judge whether an issue passes QA automatically.

    Args:
        context: Dict with:
            - labels: list of str (e.g., ['type:fix', 'risk:low', 'qa:auto'])
            - tests_passed: bool
            - review_verdict: str ('pass', 'warn', 'fail')
            - files_changed: int
            - lines_changed: int
            - has_ui_changes: bool (optional, explicit flag)
            - changed_files: list of str (optional, file paths)
            - issue_title: str (optional)
            - issue_body: str (optional)
            - playwright_passed: bool (optional, None = not run)
            - has_playwright_artifact: bool (optional)

    Returns:
        Dict with:
            - verdict: 'auto_pass' | 'needs_human' | 'fail'
            - needs_human: bool
            - reason: str
            - is_ui_task: bool
            - playwright_required: bool
    """
    labels = context.get("labels", [])
    tests_passed = context.get("tests_passed", False)
    review_verdict = context.get("review_verdict", "unknown")
    files_changed = context.get("files_changed", 0)
    lines_changed = context.get("lines_changed", 0)
    playwright_passed = context.get("playwright_passed", None)
    has_artifact = context.get("has_playwright_artifact", False)

    ui_task = is_ui_task(context)
    reasons: List[str] = []

    # Hard fail: tests didn't pass
    if not tests_passed:
        return {
            "verdict": "fail",
            "needs_human": False,
            "reason": "Tests failed",
            "is_ui_task": ui_task,
            "playwright_required": ui_task,
        }

    # Hard fail: review failed
    if review_verdict == "fail":
        return {
            "verdict": "fail",
            "needs_human": False,
            "reason": "Code review failed",
            "is_ui_task": ui_task,
            "playwright_required": ui_task,
        }

    # UI task: Playwright is mandatory
    if ui_task:
        # Playwright not run at all
        if playwright_passed is None:
            return {
                "verdict": "fail",
                "needs_human": False,
                "reason": "UI task requires Playwright execution, but Playwright was not run",
                "is_ui_task": True,
                "playwright_required": True,
            }

        # Playwright failed
        if not playwright_passed:
            return {
                "verdict": "fail",
                "needs_human": False,
                "reason": "Playwright E2E tests failed",
                "is_ui_task": True,
                "playwright_required": True,
            }

        # Playwright passed but no artifact
        if not has_artifact:
            return {
                "verdict": "fail",
                "needs_human": False,
                "reason": "UI task requires at least one Playwright artifact (test/trace/screenshot/log)",
                "is_ui_task": True,
                "playwright_required": True,
            }

    # Check conditions that require human review
    needs_human = False

    # UI task → always needs human (visual verification)
    if ui_task:
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
            "is_ui_task": ui_task,
            "playwright_required": ui_task,
        }

    # Auto pass
    return {
        "verdict": "auto_pass",
        "needs_human": False,
        "reason": "All checks passed: tests OK, review OK, within auto-close thresholds",
        "is_ui_task": ui_task,
        "playwright_required": False,
    }
