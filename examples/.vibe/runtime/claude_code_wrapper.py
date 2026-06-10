"""Claude Code CLI Wrapper for VibeFlow v6 Iris-Only Architecture.
Provides a unified interface to dispatch tasks to Claude Code,
poll for status, collect results, and cancel execution.
"""

from __future__ import annotations

import json
import os
import subprocess
import time
import uuid
from typing import Any, Dict, List, Optional


DEFAULT_TIMEOUT = 600  # 10 minutes


def parse_output(raw_output: str) -> Dict[str, Any]:
    """Parse JSON output from Claude Code CLI.

    Claude Code with --output-format json returns structured JSON.
    Returns a dict with at minimum 'status' key.
    """
    result: Dict[str, Any] = {"status": "unknown"}

    raw_output = raw_output.strip()
    if not raw_output:
        result["status"] = "empty"
        return result

    try:
        data = json.loads(raw_output)
        subtype = data.get("subtype", data.get("type", ""))
        if subtype == "success":
            result["status"] = "success"
        elif subtype == "error":
            result["status"] = "failed"
        else:
            result["status"] = data.get("status", "success")

        result["result"] = data.get("result", "")
        result["cost_usd"] = data.get("cost_usd", 0)
        result["raw"] = data
    except json.JSONDecodeError:
        # Fail-closed: an unparseable payload is NOT a success — it is
        # usually an error string from a crashed agent. Downstream QA
        # must treat 'unparsed' as non-success.
        result["status"] = "unparsed"
        result["result"] = raw_output

    return result


class ClaudeCodeWrapper:
    """Wrapper around the Claude Code CLI for task dispatch and management."""

    def __init__(self, claude_cmd: str = "claude", timeout: int = DEFAULT_TIMEOUT):
        self.claude_cmd = claude_cmd
        self.timeout = timeout
        self._processes: Dict[str, subprocess.Popen] = {}
        self._out_files: Dict[str, tuple] = {}

    def dispatch(
        self,
        task_prompt: str,
        work_dir: str,
        session_dir: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Dispatch a task to Claude Code.

        Args:
            task_prompt: The prompt describing the task.
            work_dir: Working directory for execution.
            session_dir: Directory for session recording (.vibe/sessions/).

        Returns:
            A handle dict with task_id and status.
        """
        task_id = f"claude-{uuid.uuid4().hex[:8]}"
        handle = {
            "task_id": task_id,
            "status": "dispatched",
            "agent": "claude_code",
            "work_dir": work_dir,
            "prompt": task_prompt,
            "started_at": time.time(),
        }

        # Record session (JSON handle + YAML role file the hooks read)
        if session_dir:
            os.makedirs(session_dir, exist_ok=True)
            session_file = os.path.join(session_dir, f"{task_id}.json")
            with open(session_file, "w") as f:
                json.dump(handle, f, indent=2)
            # The role-aware guards key on current_role from this YAML.
            # Use the policy display_name so the role resolves to coding_agent.
            with open(os.path.join(session_dir, f"{task_id}.yaml"), "w") as f:
                f.write(f'session_id: "{task_id}"\n')
                f.write('current_role: "Coding Agent (Claude Code / Codex)"\n')
                f.write('current_step: "5_implementation"\n')

        # Launch claude CLI subprocess. Export VIBEFLOW_SESSION so the
        # guards resolve the session role (else they fall back to state.yaml).
        cmd = [
            self.claude_cmd,
            "--dangerously-skip-permissions",
            "--print",
            "--output-format", "json",
            task_prompt,
        ]
        env = dict(os.environ)
        env["VIBEFLOW_SESSION"] = task_id
        # Stream stdout/stderr to files, not PIPEs: a long-running agent
        # that writes a lot to stderr fills the OS pipe buffer (~64KB)
        # and deadlocks if nobody drains it while we wait on poll().
        out_dir = session_dir or work_dir
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, f"{task_id}.stdout")
        err_path = os.path.join(out_dir, f"{task_id}.stderr")
        handle["stdout_path"] = out_path
        handle["stderr_path"] = err_path
        try:
            fout = open(out_path, "w")
            ferr = open(err_path, "w")
            proc = subprocess.Popen(
                cmd,
                cwd=work_dir,
                stdout=fout,
                stderr=ferr,
                text=True,
                env=env,
            )
            self._processes[task_id] = proc
            self._out_files[task_id] = (fout, ferr)
            handle["status"] = "running"
        except FileNotFoundError:
            handle["status"] = "failed"
            handle["error"] = f"Command not found: {self.claude_cmd}"

        return handle

    def poll(self, handle: Dict[str, Any]) -> Dict[str, Any]:
        """Poll the status of a dispatched task.

        Returns updated handle with current status.
        """
        task_id = handle["task_id"]
        proc = self._processes.get(task_id)

        if proc is None:
            handle["status"] = "not_started"
            return handle

        ret = proc.poll()
        if ret is None:
            elapsed = time.time() - handle.get("started_at", time.time())
            if elapsed > self.timeout:
                proc.kill()
                handle["status"] = "timeout"
                self._close_files(task_id)
            else:
                handle["status"] = "running"
        elif ret == 0:
            handle["status"] = "completed"
            self._close_files(task_id)
        else:
            handle["status"] = "failed"
            handle["exit_code"] = ret
            self._close_files(task_id)

        return handle

    def _close_files(self, task_id: str) -> None:
        files = self._out_files.pop(task_id, None)
        if files:
            for f in files:
                try:
                    f.close()
                except Exception:
                    pass

    def collect(self, handle: Dict[str, Any]) -> Dict[str, Any]:
        """Collect the results of a completed task.

        Returns dict with status, output, and parsed results.
        """
        task_id = handle["task_id"]
        proc = self._processes.get(task_id)

        result = {
            "task_id": task_id,
            "status": handle.get("status", "unknown"),
            "output": "",
            "parsed": {},
        }

        self._close_files(task_id)
        out_path = handle.get("stdout_path")
        if out_path and os.path.exists(out_path):
            with open(out_path, encoding="utf-8") as f:
                raw = f.read()
            if raw:
                result["output"] = raw
                result["parsed"] = parse_output(raw)

        return result

    def cancel(self, handle: Dict[str, Any]) -> Dict[str, Any]:
        """Cancel a running task.

        Returns updated handle with cancelled status.
        """
        task_id = handle["task_id"]
        proc = self._processes.get(task_id)

        if proc and proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()

        handle["status"] = "cancelled"
        return handle
