"""Result Collection & Reporting for VibeFlow v5 Iris-Only Architecture.
from __future__ import annotations
Collects output from Codex and Claude Code, parses results,
detects PRs, and formats reports for Iris to present to the user.
"""

import json
from typing import Any, Dict, List, Optional


def collect_results(agent_output: Dict[str, Any]) -> Dict[str, Any]:
    """Collect and parse results from a coding agent.

    Args:
        agent_output: Dict with:
            - agent: 'codex' or 'claude_code'
            - raw_output: str (JSONL for codex, JSON for claude_code)
            - exit_code: int

    Returns:
        Dict with status, summary, files_changed, tests_passed, pr_number.
    """
    agent = agent_output.get("agent", "unknown")
    raw = agent_output.get("raw_output", "")
    exit_code = agent_output.get("exit_code", -1)

    result: Dict[str, Any] = {
        "status": "unknown",
        "agent": agent,
        "summary": "",
        "files_changed": [],
        "tests_passed": None,
        "test_results": None,
        "pr_number": None,
    }

    # Non-zero exit code means failure
    if exit_code != 0:
        result["status"] = "failed"
        result["summary"] = _extract_error(raw)
        return result

    if agent == "codex":
        result.update(_parse_codex_output(raw))
    elif agent == "claude_code":
        result.update(_parse_claude_output(raw))
    else:
        result["status"] = "success" if exit_code == 0 else "failed"

    return result


def _parse_codex_output(raw: str) -> Dict[str, Any]:
    """Parse Codex JSONL output."""
    parsed: Dict[str, Any] = {"status": "success", "summary": ""}

    for line in raw.strip().split("\n"):
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            entry_type = entry.get("type", "")
            if entry_type == "result":
                parsed["status"] = entry.get("status", "success")
                parsed["summary"] = entry.get("summary", "")
            elif entry_type == "error":
                parsed["status"] = "failed"
                parsed["summary"] = entry.get("message", "Unknown error")
            if "files_changed" in entry:
                parsed["files_changed"] = entry["files_changed"]
            if "test_results" in entry:
                parsed["test_results"] = entry["test_results"]
                parsed["tests_passed"] = entry.get("tests_passed", None)
        except json.JSONDecodeError:
            continue

    return parsed


def _parse_claude_output(raw: str) -> Dict[str, Any]:
    """Parse Claude Code JSON output."""
    parsed: Dict[str, Any] = {"status": "success", "summary": ""}

    try:
        data = json.loads(raw.strip())
        subtype = data.get("subtype", data.get("type", ""))
        if subtype == "success":
            parsed["status"] = "success"
        elif subtype in ("error", "failure"):
            parsed["status"] = "failed"
        else:
            parsed["status"] = data.get("status", "success")
        parsed["summary"] = data.get("result", data.get("message", ""))
        parsed["cost_usd"] = data.get("cost_usd", 0)
    except json.JSONDecodeError:
        parsed["status"] = "success"
        parsed["summary"] = raw.strip()

    return parsed


def _extract_error(raw: str) -> str:
    """Extract error message from raw output."""
    try:
        data = json.loads(raw.strip())
        return data.get("message", data.get("error", str(data)))
    except (json.JSONDecodeError, AttributeError):
        return raw.strip()[:500] if raw else "Unknown error"


def detect_pr(raw_output: str) -> Optional[int]:
    """Detect if a PR was created from the agent output.

    Looks for PR number patterns in the output.
    Returns the pull_request number or None.
    """
    import re

    patterns = [
        r"pull/(\d+)",
        r"PR #(\d+)",
        r"pull request #(\d+)",
        r"pr_number[\"']?\s*[:=]\s*(\d+)",
    ]
    for pattern in patterns:
        match = re.search(pattern, raw_output, re.IGNORECASE)
        if match:
            return int(match.group(1))
    return None


def format_report(result: Dict[str, Any]) -> str:
    """Format a result into a human-readable report for Iris.

    Args:
        result: Dict with status, agent, summary, files_changed, tests_passed.

    Returns:
        Formatted markdown report string.
    """
    status_icon = "✅" if result.get("status") == "success" else "❌"
    agent = result.get("agent", "unknown")
    summary = result.get("summary", "")
    files = result.get("files_changed", [])
    tests = result.get("tests_passed")

    lines = [
        f"## {status_icon} Agent Report ({agent})",
        "",
        f"**Status:** {result.get('status', 'unknown')}",
    ]

    if summary:
        lines.append(f"**Summary:** {summary}")

    if files:
        lines.append("")
        lines.append("**Files changed:**")
        for f in files:
            lines.append(f"- `{f}`")

    if tests is not None:
        test_icon = "✅" if tests else "❌"
        lines.append(f"\n**Tests:** {test_icon} {'passed' if tests else 'failed'}")

    test_results = result.get("test_results")
    if test_results:
        lines.append(f"**Test details:** {test_results}")

    pr = result.get("pr_number")
    if pr:
        lines.append(f"\n**PR:** #{pr}")

    return "\n".join(lines)
