"""Session Auto-Dispatch for VibeFlow v5 Iris-Only Architecture.
from __future__ import annotations
Iris dispatches coding tasks to agents automatically.
Generates prompts, selects agents, manages worktree isolation,
and tracks session state.
"""

import json
import os
import time
import uuid
from typing import Any, Dict, Optional

from core.runtime.agent_selector import select_agent
from core.runtime.claude_code_wrapper import ClaudeCodeWrapper
from core.runtime.codex_wrapper import CodexWrapper

# Keywords that indicate UI task
_UI_KEYWORDS = [
    "ui", "page", "screen", "component", "layout", "design",
    "css", "style", "button", "form", "modal", "dialog",
    "animation", "responsive", "dashboard",
    "画面", "表示", "デザイン", "ダッシュボード", "コンポーネント",
]


def _is_ui_task(issue: Dict[str, Any]) -> bool:
    """Detect if an issue involves UI changes."""
    title = issue.get("title", "").lower()
    body = issue.get("body", "").lower()
    text = f"{title} {body}"
    return any(kw in text for kw in _UI_KEYWORDS)


def generate_prompt(
    issue: Dict[str, Any],
    context: Optional[Dict[str, Any]] = None,
) -> str:
    """Generate a task prompt for the coding agent.

    Combines issue content with project context into a structured prompt.

    Args:
        issue: Issue dict with number, title, body, labels.
        context: Optional project context (spec, plan, status).

    Returns:
        Formatted prompt string for the agent.
    """
    ctx = context or {}
    lines = [
        f"# Task: Issue #{issue['number']} — {issue['title']}",
        "",
        "## Issue Description",
        issue.get("body", "No description provided."),
        "",
    ]

    # Add acceptance criteria if available
    criteria = issue.get("acceptance_criteria", [])
    if criteria:
        lines.append("## Acceptance Criteria")
        for c in criteria:
            lines.append(f"- [ ] {c}")
        lines.append("")

    # Add labels context
    labels = issue.get("labels", [])
    if labels:
        lines.append(f"**Labels:** {', '.join(labels)}")
        lines.append("")

    # Add project context
    if ctx.get("spec"):
        lines.append("## Relevant Spec")
        lines.append(ctx["spec"][:2000])
        lines.append("")

    if ctx.get("plan"):
        lines.append("## Relevant Plan")
        lines.append(ctx["plan"][:1000])
        lines.append("")

    # Detect UI task
    ui_task = _is_ui_task(issue)

    # Add workflow instructions
    lines.extend([
        "## Workflow Instructions",
        "1. Write tests first (TDD)",
        "2. Implement to make tests pass",
        "3. Refactor if needed",
        "4. Ensure all tests pass",
        "5. Create a commit with a descriptive message",
    ])

    if ui_task:
        lines.extend([
            "",
            "## Playwright Required (UI Task)",
            "This is a UI task. The following are **mandatory**:",
            "- Write Playwright E2E tests in `tests/e2e/`",
            "- Run `bash scripts/playwright_smoke.sh` and ensure all tests pass",
            "- Produce at least one artifact: Playwright test, trace, screenshot, or exploratory log",
        ])

    return "\n".join(lines)


def dispatch_issue(
    issue: Dict[str, Any],
    project_dir: str = ".",
    context: Optional[Dict[str, Any]] = None,
    user_preference: Optional[str] = None,
    claude_code_failures: int = 0,
    dry_run: bool = False,
) -> Dict[str, Any]:
    """Dispatch an issue to the appropriate coding agent.

    Args:
        issue: Issue dict with number, title, body, labels.
        project_dir: Project root directory.
        context: Optional project context.
        user_preference: Optional user-specified agent.
        claude_code_failures: Number of previous Claude Code failures.
        dry_run: If True, don't actually execute.

    Returns:
        Handle dict with task_id, agent, status, prompt.
    """
    # Select agent
    selection = select_agent(issue, user_preference, claude_code_failures)
    agent = selection["agent"]

    # Generate prompt
    prompt = generate_prompt(issue, context)

    # Create task handle
    task_id = f"dispatch-{issue['number']}-{uuid.uuid4().hex[:6]}"
    session_dir = os.path.join(project_dir, ".vibe", "sessions")
    worktree_branch = f"vf/issue-{issue['number']}"

    handle = {
        "task_id": task_id,
        "agent": agent,
        "status": "dispatched" if not dry_run else "dry_run",
        "issue_number": issue["number"],
        "prompt": prompt,
        "worktree_branch": worktree_branch,
        "selection_reason": selection["reason"],
        "started_at": time.time(),
    }

    if not dry_run:
        # Record session
        os.makedirs(session_dir, exist_ok=True)
        session_file = os.path.join(session_dir, f"{task_id}.json")
        with open(session_file, "w") as f:
            json.dump(handle, f, indent=2)

        # Actually dispatch to the selected agent
        if agent == "codex":
            wrapper = CodexWrapper()
            agent_handle = wrapper.dispatch(
                task_prompt=prompt,
                work_dir=project_dir,
                session_dir=session_dir,
            )
        else:
            wrapper = ClaudeCodeWrapper()
            agent_handle = wrapper.dispatch(
                task_prompt=prompt,
                work_dir=project_dir,
                session_dir=session_dir,
            )
        handle["agent_handle"] = agent_handle
        handle["process_task_id"] = agent_handle.get("task_id")

    return handle
