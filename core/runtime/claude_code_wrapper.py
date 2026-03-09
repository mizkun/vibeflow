"""Claude Code CLI Wrapper for VibeFlow v5 Iris-Only Architecture.

Provides a unified interface to dispatch tasks to Claude Code,
poll for status, collect results, and cancel execution.
"""

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
        # Fall back to treating as plain text
        result["status"] = "success"
        result["result"] = raw_output

    return result


class ClaudeCodeWrapper:
    """Wrapper around the Claude Code CLI for task dispatch and management."""

    def __init__(self, claude_cmd: str = "claude", timeout: int = DEFAULT_TIMEOUT):
        self.claude_cmd = claude_cmd
        self.timeout = timeout
        self._processes: Dict[str, subprocess.Popen] = {}

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

        # Record session
        if session_dir:
            os.makedirs(session_dir, exist_ok=True)
            session_file = os.path.join(session_dir, f"{task_id}.json")
            with open(session_file, "w") as f:
                json.dump(handle, f, indent=2)

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
            else:
                handle["status"] = "running"
        elif ret == 0:
            handle["status"] = "completed"
        else:
            handle["status"] = "failed"
            handle["exit_code"] = ret

        return handle

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

        if proc and proc.stdout:
            raw = proc.stdout.read()
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
