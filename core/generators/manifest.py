#!/usr/bin/env python3
"""
VibeFlow Generated Manifest
Tracks generated files with SHA256 hashes for upgrade safety.

Classification:
- stock-managed: file matches manifest hash (unmodified generated file)
- customized: file exists in manifest but hash differs (user modified)
- unknown: file not in manifest
"""

import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path


class Manifest:
    """Manages .vibe/generated-manifest.json for a project."""

    MANIFEST_PATH = ".vibe/generated-manifest.json"

    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.manifest_file = self.project_root / self.MANIFEST_PATH
        self.entries: dict = {}
        self._load()

    def _load(self) -> None:
        """Load existing manifest if present."""
        if self.manifest_file.exists():
            with open(self.manifest_file) as f:
                data = json.load(f)
            self.entries = data.get("files", {})

    def _hash_file(self, rel_path: str) -> str:
        """Compute SHA256 hash of a file."""
        abs_path = self.project_root / rel_path
        h = hashlib.sha256()
        with open(abs_path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                h.update(chunk)
        return h.hexdigest()

    def record(self, rel_path: str, source_schema: str) -> None:
        """Record a generated file in the manifest."""
        file_hash = self._hash_file(rel_path)
        self.entries[rel_path] = {
            "sha256": file_hash,
            "source": source_schema,
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

    def save(self) -> None:
        """Write manifest to disk."""
        os.makedirs(self.manifest_file.parent, exist_ok=True)
        data = {
            "version": "1.0",
            "files": self.entries,
        }
        with open(self.manifest_file, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")

    def classify(self, rel_path: str) -> str:
        """Classify a file as stock-managed, customized, or unknown."""
        if rel_path not in self.entries:
            return "unknown"

        abs_path = self.project_root / rel_path
        if not abs_path.exists():
            return "unknown"

        current_hash = self._hash_file(rel_path)
        recorded_hash = self.entries[rel_path].get("sha256", "")

        if current_hash == recorded_hash:
            return "stock-managed"
        return "customized"
