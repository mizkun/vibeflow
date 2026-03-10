#!/usr/bin/env python3
"""
VibeFlow State Management Runtime
Provides read/write API for project_state.yaml and session state files.

State is split into two concerns:
- project_state.yaml: project-wide state (active issue, phase, patch runs)
- sessions/<session-id>.yaml: per-session state (role, step, attached issue)

Session resolution order:
1. VIBEFLOW_SESSION env var → sessions/<value>.yaml
2. Fallback: read .vibe/state.yaml (backward compat with v3)
"""

import os
from pathlib import Path

try:
    import yaml
except ImportError:
    # Minimal YAML parsing fallback for environments without pyyaml
    yaml = None


def _read_yaml(path: str) -> dict:
    """Read a YAML file and return its contents as a dict."""
    p = Path(path)
    if not p.exists():
        return {}
    content = p.read_text(encoding="utf-8")
    if yaml:
        return yaml.safe_load(content) or {}
    # Minimal fallback: parse key: value lines
    result = {}
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" in line and not line.startswith("-"):
            key, _, val = line.partition(":")
            key = key.strip()
            val = val.strip().strip('"').strip("'")
            if val == "null":
                val = None
            elif val.isdigit():
                val = int(val)
            result[key] = val
    return result


def _write_yaml(path: str, data: dict) -> None:
    """Write a dict to a YAML file."""
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    if yaml:
        with open(p, "w", encoding="utf-8") as f:
            yaml.dump(data, f, default_flow_style=False, allow_unicode=True,
                      sort_keys=False)
    else:
        # Minimal fallback
        lines = []
        for k, v in data.items():
            if v is None:
                lines.append(f"{k}: null")
            elif isinstance(v, str):
                lines.append(f'{k}: "{v}"')
            else:
                lines.append(f"{k}: {v}")
        p.write_text("\n".join(lines) + "\n", encoding="utf-8")


# ──────────────────────────────────────────────
# Project State API
# ──────────────────────────────────────────────

def read_project_state(project_dir: str) -> dict:
    """Read project_state.yaml from the given project directory."""
    path = os.path.join(project_dir, ".vibe", "project_state.yaml")
    return _read_yaml(path)


def write_project_state(project_dir: str, data: dict) -> None:
    """Write project_state.yaml to the given project directory."""
    path = os.path.join(project_dir, ".vibe", "project_state.yaml")
    _write_yaml(path, data)


# ──────────────────────────────────────────────
# Session State API
# ──────────────────────────────────────────────

def resolve_session_id(project_dir: str) -> str | None:
    """Resolve the current session ID.

    Resolution order:
    1. VIBEFLOW_SESSION environment variable
    2. None (no session found)
    """
    return os.environ.get("VIBEFLOW_SESSION")


def session_path(project_dir: str, session_id: str) -> str:
    """Get the file path for a session state file."""
    return os.path.join(project_dir, ".vibe", "sessions", f"{session_id}.yaml")


def read_session_state(project_dir: str, session_id: str | None = None) -> dict:
    """Read session state.

    If session_id is not provided, resolves via VIBEFLOW_SESSION env var.
    Falls back to .vibe/state.yaml for backward compatibility.
    """
    sid = session_id or resolve_session_id(project_dir)
    if sid:
        path = session_path(project_dir, sid)
        data = _read_yaml(path)
        if data:
            return data

    # Fallback: read legacy state.yaml
    legacy_path = os.path.join(project_dir, ".vibe", "state.yaml")
    return _read_yaml(legacy_path)


def write_session_state(project_dir: str, session_id: str, data: dict) -> None:
    """Write session state to sessions/<session_id>.yaml."""
    path = session_path(project_dir, session_id)
    _write_yaml(path, data)


def create_dev_session(project_dir: str, issue_number: int) -> str:
    """Create a new development session for the given issue.

    Returns the session_id.
    """
    sid = f"dev-issue-{issue_number}"
    data = {
        "session_id": sid,
        "kind": "worker",
        "current_role": "Iris",
        "current_step": "1_issue_review",
        "attached_issue": issue_number,
        "worktree": None,
        "status": "active",
        "safety": {
            "max_fix_attempts": 3,
            "failed_approach_log": [],
        },
        "infra_log": {
            "hook_changes": [],
            "rollback_pending": False,
        },
    }
    write_session_state(project_dir, sid, data)
    return sid
