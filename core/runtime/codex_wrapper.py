"""Codex CLI Wrapper for VibeFlow v5 Iris-Only Architecture.

Provides a unified interface to dispatch tasks to Codex,
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
    """Parse JSONL output from Codex CLI.

    Reads line-by-line JSON, extracts the final result entry.
    Returns a dict with at minimum 'status' and 'messages' keys.
    """
    messages: List[Dict[str, Any]] = []
    result: Dict[str, Any] = {"status": "unknown", "messages": messages}

    for line in raw_output.strip().split("\n"):
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            messages.append(entry)
            if entry.get("type") == "result":
                result["status"] = entry.get("status", "success")
                result["summary"] = entry.get("summary", "")
            elif entry.get("status"):
                result["status"] = entry["status"]
        except json.JSONDecodeError:
            messages.append({"type": "raw", "content": line})

    if not messages:
        result["status"] = "empty"

    return result


class CodexWrapper:
    """Wrapper around the Codex CLI for task dispatch and management."""

    def __init__(self, codex_cmd: str = "codex", timeout: int = DEFAULT_TIMEOUT):
        self.codex_cmd = codex_cmd
        self.timeout = timeout
        self._processes: Dict[str, subprocess.Popen] = {}

    def dispatch(
        self,
        task_prompt: str,
        work_dir: str,
        session_dir: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Dispatch a task to Codex.

        Args:
            task_prompt: The prompt describing the task.
            work_dir: Working directory for execution.
            session_dir: Directory for session recording (.vibe/sessions/).

        Returns:
            A handle dict with task_id and status.
        """
        task_id = f"codex-{uuid.uuid4().hex[:8]}"
        handle = {
            "task_id": task_id,
            "status": "dispatched",
            "agent": "codex",
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

        # Launch codex CLI subprocess
        cmd = [
            self.codex_cmd,
            "exec",
            "--full-auto",
            "--json",
            task_prompt,
        ]
        try:
            proc = subprocess.Popen(
                cmd,
                cwd=work_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            self._processes[task_id] = proc
            handle["status"] = "running"
        except FileNotFoundError:
            handle["status"] = "failed"
            handle["error"] = f"Command not found: {self.codex_cmd}"

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
