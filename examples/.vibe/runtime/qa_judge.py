"""QA Judgment Automation for VibeFlow v6 Iris-Only Architecture.

Determines whether an issue can be auto-closed or needs human review.
UI tasks require Playwright artifacts and are routed to needs_human.

Fail-closed contract (v6):
- review_verdict is a whitelist: only 'pass' (or 'warn' with all
  responses recorded) can reach auto_pass. 'fail' fails. Anything else
  (unknown/pending/unparsed/missing) means the review never actually
  ran — that's an infrastructure problem, so escalate to a human
  instead of burning re-implementation retries.
- auto_pass requires on-disk test evidence (log + exit code file); the
  exit code overrides the self-reported tests_passed bool.
"""

from __future__ import annotations

import os
from typing import Any, Dict, List

# Thresholds
MAX_FILES_AUTO = 5
MAX_LINES_AUTO = 200

# UI detection lives in ui_task.py — the single source of truth shared
# with dispatcher and issue_generator. is_ui_task is re-exported here
# for backward compatibility (skills import it from qa_judge).
try:
    from core.runtime.ui_task import is_ui_task
except ImportError:  # flat .vibe/runtime/ deployment
    from ui_task import is_ui_task


def judge(context: Dict[str, Any]) -> Dict[str, Any]:
    """Judge whether an issue passes QA automatically.

    Args:
        context: Dict with:
            - labels: list of str (e.g., ['type:fix', 'risk:low', 'qa:auto'])
            - tests_passed: bool (self-report; evidence overrides it)
            - review_verdict: str ('pass', 'warn', 'fail', anything else
              is treated as "review did not run" → needs_human)
            - warn_responses_recorded: bool (optional; required for
              'warn' to count as a passing review — every warn item must
              have a fix or a recorded technical justification)
            - evidence: dict (optional but required for auto_pass):
                - test_log: path to the captured test output (non-empty)
                - test_exit: path to a file holding the test exit code
            - files_changed: int
            - lines_changed: int
            - has_ui_changes: bool (optional, explicit flag)
            - changed_files: list of str (optional, file paths)
            - issue_title: str (optional)
            - issue_body: str (optional)
            - playwright_passed: bool (optional, None = not run)
            - has_playwright_artifact: bool (optional)
            - playwright_artifact_path: str (optional; when given, the
              path must exist for the artifact to count)

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
    evidence = context.get("evidence")

    ui_task = is_ui_task(context)
    reasons: List[str] = []

    def _fail(reason: str) -> Dict[str, Any]:
        return {
            "verdict": "fail",
            "needs_human": False,
            "reason": reason,
            "is_ui_task": ui_task,
            "playwright_required": ui_task,
        }

    # Hard fail: tests didn't pass (self-report)
    if not tests_passed:
        return _fail("Tests failed")

    # Evidence beats claims: a recorded non-zero test exit code fails
    # the judgment even when tests_passed=True was reported.
    evidence_ok = False
    if isinstance(evidence, dict):
        test_log = evidence.get("test_log", "")
        test_exit = evidence.get("test_exit", "")
        log_ok = bool(test_log) and os.path.isfile(test_log) \
            and os.path.getsize(test_log) > 0
        exit_value = None
        if test_exit and os.path.isfile(test_exit):
            try:
                exit_value = open(test_exit).read().strip()
            except OSError:
                exit_value = None
        if exit_value is not None and exit_value != "0":
            return _fail(
                f"Tests failed (exit code evidence: {exit_value})"
            )
        evidence_ok = log_ok and exit_value == "0"

    if not evidence_ok:
        reasons.append(
            "no verifiable test evidence (test_log + test_exit required "
            "for auto_pass)"
        )

    # Hard fail: review failed
    if review_verdict == "fail":
        return _fail("Code review failed")

    # Review whitelist: only 'pass' (or 'warn' with every item's
    # response recorded) counts as a completed, passing review.
    if review_verdict == "warn":
        if not context.get("warn_responses_recorded", False):
            reasons.append(
                "review warnings without recorded responses "
                "(fix or technical justification required per item)"
            )
    elif review_verdict != "pass":
        reasons.append(
            f"review not executed or unparseable "
            f"(verdict: {review_verdict})"
        )

    # UI task: Playwright is mandatory
    if ui_task:
        # Playwright not run at all
        if playwright_passed is None:
            return _fail(
                "UI task requires Playwright execution, "
                "but Playwright was not run"
            )

        # Playwright failed
        if not playwright_passed:
            return _fail("Playwright E2E tests failed")

        # A claimed artifact must actually exist on disk
        artifact_path = context.get("playwright_artifact_path")
        if artifact_path and not os.path.exists(artifact_path):
            return _fail(
                f"Claimed Playwright artifact does not exist: "
                f"{artifact_path}"
            )

        # Playwright passed but no artifact
        if not has_artifact:
            return _fail(
                "UI task requires at least one Playwright artifact "
                "(test/trace/screenshot/log)"
            )

    # Check conditions that require human review.
    # Evidence/review problems recorded above force needs_human too.
    needs_human = bool(reasons)

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
