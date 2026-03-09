"""Agent Selection Logic for VibeFlow v5 Iris-Only Architecture.

Determines whether to use Codex or Claude Code for a given task.
Default: Codex. Fallback: Claude Code when specific conditions are met.
"""

from typing import Any, Dict, Optional


def select_agent(
    issue: Dict[str, Any],
    user_preference: Optional[str] = None,
    codex_failures: int = 0,
) -> Dict[str, str]:
    """Select the appropriate coding agent for an issue.

    Args:
        issue: Issue dict with title, labels, and optional flags:
            - requires_mcp: bool
            - requires_playwright: bool
            - requires_local_fs: bool
        user_preference: User-specified agent ('codex' or 'claude_code').
        codex_failures: Number of times Codex has failed for this task.

    Returns:
        Dict with 'agent' ('codex' or 'claude_code') and 'reason' (str).
    """
    # User override takes priority
    if user_preference:
        return {
            "agent": user_preference,
            "reason": f"User specified {user_preference}",
        }

    # Fallback after repeated Codex failures
    if codex_failures >= 2:
        return {
            "agent": "claude_code",
            "reason": f"Codex failed {codex_failures} times, falling back to Claude Code",
        }

    # Claude Code required for MCP
    if issue.get("requires_mcp"):
        return {
            "agent": "claude_code",
            "reason": "Task requires MCP server integration",
        }

    # Claude Code required for Playwright
    if issue.get("requires_playwright"):
        return {
            "agent": "claude_code",
            "reason": "Task requires Playwright (local browser)",
        }

    # Claude Code required for local filesystem access
    if issue.get("requires_local_fs"):
        return {
            "agent": "claude_code",
            "reason": "Task requires local filesystem access",
        }

    # Default: Codex
    return {
        "agent": "codex",
        "reason": "Default agent (sandbox execution)",
    }
