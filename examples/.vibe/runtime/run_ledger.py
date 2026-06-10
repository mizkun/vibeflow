#!/usr/bin/env python3
"""
VibeFlow Run Ledger (v6)

An append-only audit log so a PO can verify an overnight / long-running
loop after the fact — which issue, how many attempts, which tests passed,
what evidence was left. runtime had no logging and the conversation
summary vanishes on compaction, so 'what happened while I was away' had
no answer but reading git log by hand.

This is the loop's external memory (Ralph's file-based state): one JSON
object per line in .vibe/runs/<YYYY-MM-DD>.jsonl, written with O_APPEND
so concurrent writers don't clobber each other.

Generalizes patch_loop's patch_runs to the standard workflow.
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path


def _runs_dir(project_dir: str) -> Path:
    return Path(project_dir) / ".vibe" / "runs"


def _today_path(project_dir: str, date: str | None = None) -> Path:
    if date is None:
        date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    return _runs_dir(project_dir) / f"{date}.jsonl"


def append_event(project_dir: str, issue, step: str, attempt: int,
                 verdict: str, evidence_paths=None, duration=None,
                 agent: str = "", date: str | None = None,
                 timestamp: str | None = None) -> None:
    """Append one event to today's ledger.

    O_APPEND keeps concurrent writers safe. timestamp/date are injectable
    for deterministic tests; default to UTC now."""
    runs = _runs_dir(project_dir)
    runs.mkdir(parents=True, exist_ok=True)
    event = {
        "ts": timestamp or datetime.now(timezone.utc).isoformat(),
        "issue": issue,
        "step": step,
        "attempt": attempt,
        "verdict": verdict,
        "agent": agent,
        "evidence_paths": evidence_paths or [],
        "duration": duration,
    }
    line = json.dumps(event, ensure_ascii=False) + "\n"
    path = _today_path(project_dir, date)
    fd = os.open(str(path), os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o644)
    try:
        os.write(fd, line.encode("utf-8"))
    finally:
        os.close(fd)


def read_events(project_dir: str) -> list:
    """Read every ledger event across all days (chronological by file)."""
    runs = _runs_dir(project_dir)
    events = []
    if not runs.is_dir():
        return events
    for f in sorted(runs.glob("*.jsonl")):
        for line in f.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return events


def summarize(project_dir: str, issue=None) -> dict:
    """Summarize the ledger, optionally for one issue.

    Returns {attempts, final_verdict, by_verdict, events}."""
    events = read_events(project_dir)
    if issue is not None:
        events = [e for e in events if str(e.get("issue")) == str(issue)]
    by_verdict: dict = {}
    for e in events:
        v = e.get("verdict", "unknown")
        by_verdict[v] = by_verdict.get(v, 0) + 1
    return {
        "attempts": len(events),
        "final_verdict": events[-1].get("verdict") if events else None,
        "by_verdict": by_verdict,
        "events": events,
    }


def closed_issues_without_entries(project_dir: str, closed_issues) -> list:
    """Closed issues that have no ledger entry (a discipline gap)."""
    logged = {str(e.get("issue")) for e in read_events(project_dir)}
    return [i for i in closed_issues if str(i) not in logged]
