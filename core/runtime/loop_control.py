#!/usr/bin/env python3
"""
VibeFlow Loop Control Runtime (v6)

Makes the autonomous-loop stop conditions REAL. The "max 3 retries →
escalate" / "switch agent on repeated failure" rules lived only in
SKILL.md prose; nothing counted attempts, so the recovery strategy never
fired and a long unattended loop could retry the same failure forever or
silently move past a failed issue.

State of record is the per-issue session file
(.vibe/sessions/dev-issue-<N>.yaml) under its `safety` key — the schema
create_dev_session already writes (max_fix_attempts, failed_approach_log).
No new state file, no YAML duplication.

API:
- record_attempt(project_dir, issue, step, outcome, fingerprint)
- should_retry(project_dir, issue) -> {action, agent, reason, attempts}

CLI:
- python3 loop_control.py should-retry <issue> [--project-dir DIR]
"""

from __future__ import annotations

import argparse
import os
import sys

try:
    from core.runtime.state import read_session_state, write_session_state
    from core.runtime.agent_selector import select_agent
except ImportError:  # flat .vibe/runtime/ deployment
    from state import read_session_state, write_session_state
    from agent_selector import select_agent

# Single source of the retry policy (was scattered/implicit):
#   attempts 0-1 failed  → retry with the default agent (claude_code)
#   attempt 2 failed     → switch to the fallback agent (codex)
#   attempt >= 3 failed  → escalate to a human
MAX_FIX_ATTEMPTS = 3
SWITCH_AGENT_AFTER = 2  # failures

# Pre-emptive scope budget for a single attempt. qa_judge's thresholds
# are a post-hoc needs_human; these stop a runaway before it lands a
# 43-commit scope explosion. Kept in line with patch_loop's file limit.
MAX_FILES_PER_ATTEMPT = 10
MAX_LINES_PER_ATTEMPT = 800

# Same failure repeating this many times in a row → change approach.
REPEAT_FAILURE_THRESHOLD = 2


def _session_id(issue) -> str:
    return f"dev-issue-{str(issue).lstrip('#')}"


def _load(project_dir: str, issue):
    sid = _session_id(issue)
    data = read_session_state(project_dir, sid) or {}
    safety = data.get("safety")
    if not isinstance(safety, dict):
        safety = {"max_fix_attempts": MAX_FIX_ATTEMPTS, "failed_approach_log": []}
        data["safety"] = safety
    if not isinstance(safety.get("failed_approach_log"), list):
        safety["failed_approach_log"] = []
    return sid, data, safety


def record_attempt(project_dir: str, issue, step: str, outcome: str,
                   fingerprint: str = "") -> dict:
    """Record one attempt. A 'pass' outcome resets the failure log.

    Returns the updated safety dict."""
    sid, data, safety = _load(project_dir, issue)
    if outcome == "pass":
        safety["failed_approach_log"] = []
    else:
        safety["failed_approach_log"].append({
            "step": step,
            "outcome": outcome,
            "fingerprint": fingerprint,
        })
    data["safety"] = safety
    write_session_state(project_dir, sid, data)
    return safety


def failure_count(project_dir: str, issue) -> int:
    _sid, _data, safety = _load(project_dir, issue)
    return len(safety["failed_approach_log"])


def consecutive_fingerprint(project_dir: str, issue) -> int:
    """How many times the most recent failure fingerprint repeated in a row."""
    _sid, _data, safety = _load(project_dir, issue)
    log = safety["failed_approach_log"]
    if not log:
        return 0
    last = log[-1].get("fingerprint", "")
    n = 0
    for entry in reversed(log):
        if entry.get("fingerprint", "") == last and last:
            n += 1
        else:
            break
    return n


def check_budget(files_changed: int = 0, lines_changed: int = 0) -> dict:
    """Pre-emptive runaway guard for a single attempt's diff size.

    Returns {action: proceed|escalate, reason}."""
    if files_changed > MAX_FILES_PER_ATTEMPT or lines_changed > MAX_LINES_PER_ATTEMPT:
        return {
            "action": "escalate",
            "reason": (
                f"scope budget exceeded ({files_changed} files / "
                f"{lines_changed} lines > "
                f"{MAX_FILES_PER_ATTEMPT}/{MAX_LINES_PER_ATTEMPT}) — "
                f"stop and escalate before the change runs away"
            ),
        }
    return {"action": "proceed", "reason": "within scope budget"}


def should_retry(project_dir: str, issue) -> dict:
    """Decide what to do after the current attempt's failures.

    Returns {action, agent, reason, attempts, repeated_failure}.
    """
    fails = failure_count(project_dir, issue)
    repeated = consecutive_fingerprint(project_dir, issue) >= REPEAT_FAILURE_THRESHOLD

    if fails >= MAX_FIX_ATTEMPTS:
        return {
            "action": "escalate",
            "agent": "",
            "reason": f"{fails} failed attempts (max {MAX_FIX_ATTEMPTS}) — escalate to human",
            "attempts": fails,
            "repeated_failure": repeated,
        }

    # select_agent encodes the fallback: claude_code_failures>=2 → codex
    sel = select_agent({}, claude_code_failures=fails)
    if sel["agent"] != "claude_code":
        action, agent, reason = "switch_agent", sel["agent"], sel["reason"]
    else:
        action, agent, reason = "retry", "claude_code", f"attempt {fails + 1}/{MAX_FIX_ATTEMPTS}"

    if repeated:
        reason += (
            " — 同じ失敗が連続している。前回と同じアプローチを繰り返さず、"
            "別の方法を試すこと"
        )
    return {
        "action": action,
        "agent": agent,
        "reason": reason,
        "attempts": fails,
        "repeated_failure": repeated,
    }


def main(argv: list) -> int:
    parser = argparse.ArgumentParser(description="VibeFlow loop control")
    sub = parser.add_subparsers(dest="cmd")
    sr = sub.add_parser("should-retry")
    sr.add_argument("issue")
    sr.add_argument("--project-dir", default=os.environ.get("VIBEFLOW_PROJECT_DIR", "."))

    ra = sub.add_parser("record-attempt")
    ra.add_argument("issue")
    ra.add_argument("step")
    ra.add_argument("outcome", choices=["pass", "fail"])
    ra.add_argument("fingerprint", nargs="?", default="")
    ra.add_argument("--project-dir", default=os.environ.get("VIBEFLOW_PROJECT_DIR", "."))

    args = parser.parse_args(argv)

    if args.cmd == "should-retry":
        d = should_retry(args.project_dir, args.issue)
        print(f"{d['action']} {d['agent']}".strip())
        print(d["reason"])
        return 0
    if args.cmd == "record-attempt":
        safety = record_attempt(args.project_dir, args.issue, args.step,
                                args.outcome, args.fingerprint)
        print(f"recorded: {len(safety['failed_approach_log'])} failures")
        return 0
    parser.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
