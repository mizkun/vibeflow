#!/usr/bin/env python3
"""
VibeFlow Codex Review Runtime
Parses and saves structured review output from Codex.

Review JSON schema:
{
    "identifier": "pr-123",
    "findings": [
        {
            "file": "src/app.py",
            "line": 42,
            "severity": "warning|error|info",
            "message": "Issue description",
            "suggestion": "How to fix"
        }
    ],
    "summary": "Review summary text",
    "passed": true|false,
    "raw_output": "Original codex output"
}
"""

import json
import os
import re
from datetime import datetime
from pathlib import Path


def parse_review(raw_output: str, identifier: str = "unknown") -> dict:
    """Parse raw Codex review output into structured JSON.

    Extracts findings from markdown-formatted review output.
    A finding block is expected to have:
      - File: <path>
      - Line: <number>
      - Severity: <warning|error|info>
      - Issue: <description>
      - Suggestion: <text>

    Args:
        raw_output: Raw text output from codex exec
        identifier: Review identifier (e.g., 'pr-123', 'diff-abc')

    Returns:
        Structured review dict
    """
    findings = []

    # Extract finding blocks
    finding_pattern = re.compile(
        r"###\s*Finding\s*\d+\s*\n"
        r"(?:.*?-\s*File:\s*(.+?)\n)?"
        r"(?:.*?-\s*Line:\s*(\d+)\n)?"
        r"(?:.*?-\s*Severity:\s*(\w+)\n)?"
        r"(?:.*?-\s*(?:Issue|Message):\s*(.+?)\n)?"
        r"(?:.*?-\s*Suggestion:\s*(.+?)(?:\n|$))?",
        re.DOTALL,
    )

    for match in finding_pattern.finditer(raw_output):
        finding = {
            "file": (match.group(1) or "").strip(),
            "line": int(match.group(2)) if match.group(2) else None,
            "severity": (match.group(3) or "info").strip().lower(),
            "message": (match.group(4) or "").strip(),
            "suggestion": (match.group(5) or "").strip(),
        }
        if finding["message"]:
            findings.append(finding)

    # Extract summary
    summary_match = re.search(
        r"##\s*Review\s*Summary\s*\n(.+?)(?=\n###|\Z)",
        raw_output,
        re.DOTALL,
    )
    summary = summary_match.group(1).strip() if summary_match else ""

    # Determine pass/fail:
    # - passed=true if no error-severity findings (warnings alone do not fail)
    # - has_warnings=true if any warning-severity findings exist
    has_errors = any(f["severity"] == "error" for f in findings)
    has_warnings = any(f["severity"] == "warning" for f in findings)
    passed = not has_errors

    return {
        "identifier": identifier,
        "timestamp": datetime.now().isoformat(),
        "findings": findings,
        "summary": summary,
        "passed": passed,
        "has_warnings": has_warnings,
        "finding_count": len(findings),
        "raw_output": raw_output,
    }


def save_review(directory: str, review: dict) -> str:
    """Save a review result as JSON.

    Args:
        directory: Directory to save into (e.g., .vibe/reviews/)
        review: Structured review dict from parse_review()

    Returns:
        Path to the saved JSON file
    """
    p = Path(directory)
    p.mkdir(parents=True, exist_ok=True)

    identifier = review.get("identifier", "unknown")
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    filename = f"{identifier}-{timestamp}.json"
    filepath = p / filename

    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(review, f, indent=2, ensure_ascii=False)
        f.write("\n")

    return str(filepath)
