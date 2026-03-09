#!/usr/bin/env python3
"""
VibeFlow Worker Adapter — Common interface for task execution.

Provides a uniform API for dispatching handoff packets to different
worker backends (Claude Code, Codex, Human).

Worker type is always explicitly specified in the handoff packet —
no automatic routing or selection.
"""

from abc import ABC, abstractmethod

# Required fields in a handoff packet
REQUIRED_PACKET_FIELDS = ("task_id", "task_type", "worker_type", "goal")


class WorkerAdapter(ABC):
    """Base class for all worker adapters."""

    worker_type: str = ""

    def validate_packet(self, packet: dict) -> bool:
        """Validate that a handoff packet has required fields.

        Raises:
            ValueError: If required fields are missing
        """
        missing = [f for f in REQUIRED_PACKET_FIELDS if f not in packet or not packet[f]]
        if missing:
            raise ValueError(f"Packet missing required fields: {', '.join(missing)}")
        return True

    def execute(self, packet: dict) -> dict:
        """Execute a task from a handoff packet.

        Args:
            packet: Handoff packet dict (from handoff.build_packet)

        Returns:
            Result dict with at least 'status' key.

        Raises:
            ValueError: If packet is invalid or worker_type mismatches.
        """
        self.validate_packet(packet)

        if packet.get("worker_type") != self.worker_type:
            raise ValueError(
                f"Worker type mismatch: packet has '{packet.get('worker_type')}' "
                f"but this adapter handles '{self.worker_type}'"
            )

        return self._execute(packet)

    @abstractmethod
    def _execute(self, packet: dict) -> dict:
        """Internal execution — implemented by each adapter."""
        ...


class ClaudeWorker(WorkerAdapter):
    """Claude Code worker adapter.

    Executes tasks via Claude Code in a terminal session.
    """

    worker_type = "claude"

    def _execute(self, packet: dict) -> dict:
        # Stub: returns pending status for now.
        # Full implementation in Phase 3-4.
        return {
            "status": "pending",
            "worker_type": self.worker_type,
            "task_id": packet.get("task_id"),
            "message": "Claude worker execution not yet implemented",
        }


class CodexWorker(WorkerAdapter):
    """Codex worker adapter.

    Executes tasks via `codex exec` with worktree isolation.
    """

    worker_type = "codex"

    def _execute(self, packet: dict) -> dict:
        # Stub: returns pending status for now.
        # Full implementation in Phase 3-3/3-4.
        return {
            "status": "pending",
            "worker_type": self.worker_type,
            "task_id": packet.get("task_id"),
            "message": "Codex worker execution not yet implemented",
        }


class HumanWorker(WorkerAdapter):
    """Human worker adapter.

    Produces a task description for human execution.
    """

    worker_type = "human"

    def _execute(self, packet: dict) -> dict:
        # Stub: returns pending status for now.
        return {
            "status": "pending",
            "worker_type": self.worker_type,
            "task_id": packet.get("task_id"),
            "message": "Awaiting human execution",
        }


# Worker registry — explicit mapping only, no auto-selection
# Future: "codex-cloud" → CloudCodexWorker (async, submit-then-poll)
# See docs/codex-cloud-design.md for design details.
_WORKERS = {
    "claude": ClaudeWorker,
    "codex": CodexWorker,
    "human": HumanWorker,
}


def get_worker(worker_type: str) -> WorkerAdapter:
    """Factory function to get a worker adapter by type.

    Args:
        worker_type: One of 'claude', 'codex', 'human'

    Returns:
        WorkerAdapter instance

    Raises:
        ValueError: If worker_type is not recognized
    """
    cls = _WORKERS.get(worker_type)
    if cls is None:
        raise ValueError(
            f"Unknown worker_type: '{worker_type}'. "
            f"Valid types: {', '.join(sorted(_WORKERS.keys()))}"
        )
    return cls()
