"""Cross-Review Model for VibeFlow v5 Iris-Only Architecture.

The agent that did NOT code reviews the changes.
Claude Code codes → Codex reviews (default), and vice versa.
"""

import re
from typing import Any, Dict, List, Optional


def select_reviewer(coding_agent: str) -> str:
    """Select the reviewer agent (the opposite of the coding agent).

    Args:
        coding_agent: 'codex' or 'claude_code'

    Returns:
        The reviewer agent name.
    """
    if coding_agent == "codex":
        return "claude_code"
    return "codex"


def format_review_prompt(
    diff: str,
    issue_title: str,
    acceptance_criteria: Optional[List[str]] = None,
) -> str:
    """Generate a review prompt for the reviewing agent.

    Args:
        diff: Git diff of the changes.
        issue_title: Title of the issue being reviewed.
        acceptance_criteria: List of acceptance criteria to check.

    Returns:
        Formatted review prompt string.
    """
    lines = [
        f"# Code Review: {issue_title}",
        "",
        "## Instructions",
        "Review the following diff for:",
        "- **Correctness**: Does the code match the acceptance criteria?",
        "- **Tests**: Are tests sufficient and correct?",
        "- **Security**: Any OWASP Top 10 vulnerabilities?",
        "- **Performance**: Any obvious N+1 queries or unnecessary re-renders?",
        "- **Consistency**: Does it match the existing codebase style?",
        "",
    ]

    if acceptance_criteria:
        lines.append("## Acceptance Criteria")
        for c in acceptance_criteria:
            lines.append(f"- [ ] {c}")
        lines.append("")

    lines.extend([
        "## Diff",
        "```diff",
        diff,
        "```",
        "",
        "## Output Format",
        "Start your response with one of:",
        "  verdict: pass",
        "  verdict: warn",
        "  verdict: fail",
        "",
        "Then list any items found:",
        "- severity: error | warning | info",
        "  file: <path>",
        "  message: <description>",
        "  suggestion: <fix>",
    ])

    return "\n".join(lines)


def parse_review(review_text: str) -> Dict[str, Any]:
    """Parse a review response into structured data.

    Args:
        review_text: Raw review text from the agent.

    Returns:
        Dict with verdict ('pass', 'warn', 'fail') and items list.
    """
    result: Dict[str, Any] = {
        "verdict": "unknown",
        "items": [],
        "raw": review_text,
    }

    # Extract verdict
    verdict_match = re.search(
        r"verdict:\s*(pass|warn|fail)", review_text, re.IGNORECASE
    )
    if verdict_match:
        result["verdict"] = verdict_match.group(1).lower()

    # Extract items (simple pattern matching)
    item_pattern = re.compile(
        r"-\s*severity:\s*(error|warning|info)\s*\n"
        r"\s*file:\s*(.+?)\s*\n"
        r"\s*message:\s*(.+?)(?:\n|$)",
        re.MULTILINE | re.IGNORECASE,
    )
    for match in item_pattern.finditer(review_text):
        item = {
            "severity": match.group(1).lower(),
            "file": match.group(2).strip(),
            "message": match.group(3).strip(),
        }
        result["items"].append(item)

    return result
