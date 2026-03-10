"""Agent Selection Logic for VibeFlow v5 Iris-Only Architecture.

Determines whether to use Claude Code or Codex for a given task.
Default: Claude Code. Codex is used for review (cross-review model).
"""

from typing import Any, Dict, Optional


def select_agent(
    issue: Dict[str, Any],
    user_preference: Optional[str] = None,
    claude_code_failures: int = 0,
) -> Dict[str, str]:
    """Select the appropriate coding agent for an issue.

    Args:
        issue: Issue dict with title, labels, and optional flags:
            - requires_sandbox: bool (prefer Codex sandbox)
        user_preference: User-specified agent ('codex' or 'claude_code').
        claude_code_failures: Number of times Claude Code has failed for this task.

    Returns:
        Dict with 'agent' ('codex' or 'claude_code') and 'reason' (str).
    """
    # User override takes priority
    if user_preference:
        return {
            "agent": user_preference,
            "reason": f"User specified {user_preference}",
        }

    # Fallback after repeated Claude Code failures
    if claude_code_failures >= 2:
        return {
            "agent": "codex",
            "reason": f"Claude Code failed {claude_code_failures} times, falling back to Codex",
        }

    # Codex preferred for sandbox-only tasks
    if issue.get("requires_sandbox"):
        return {
            "agent": "codex",
            "reason": "Task prefers Codex sandbox execution",
        }

    # Default: Claude Code
    return {
        "agent": "claude_code",
        "reason": "Default agent (local execution with full capabilities)",
    }
