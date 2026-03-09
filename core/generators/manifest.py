#!/usr/bin/env python3
"""
VibeFlow Generated Manifest
Tracks generated files with SHA256 hashes for upgrade safety.

Classification:
- stock-managed: file matches manifest hash (unmodified generated file)
- customized: file exists in manifest but hash differs (user modified)
- unknown: file not in manifest

Supports two file types:
- full: entire file is generated (e.g., validate_access.py)
- partial: only VF:BEGIN/VF:END sections are managed (e.g., CLAUDE.md)
"""

import hashlib
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path

# For partial files: extract managed section content
MARKER_RE = re.compile(
    r"<!-- VF:BEGIN (\w+) -->\n(.*?)<!-- VF:END \1 -->",
    re.DOTALL,
)


class Manifest:
    """Manages .vibe/generated-manifest.json for a project."""

    MANIFEST_PATH = ".vibe/generated-manifest.json"

    def __init__(self, project_root: str, generator_version: str = "1.0.0"):
        self.project_root = Path(project_root)
        self.manifest_file = self.project_root / self.MANIFEST_PATH
        self.generator_version = generator_version
        self.entries: dict = {}
        self._load()

    def _load(self) -> None:
        """Load existing manifest if present."""
        if self.manifest_file.exists():
            with open(self.manifest_file) as f:
                data = json.load(f)
            self.entries = data.get("files", {})

    @staticmethod
    def _hash_bytes(data: bytes) -> str:
        """Compute SHA256 hash of bytes."""
        return hashlib.sha256(data).hexdigest()

    def _hash_file(self, rel_path: str) -> str:
        """Compute SHA256 hash of a file."""
        abs_path = self.project_root / rel_path
        with open(abs_path, "rb") as f:
            return self._hash_bytes(f.read())

    @staticmethod
    def _hash_schema(schema_path: str) -> str:
        """Compute SHA256 hash of a schema file for provenance tracking."""
        with open(schema_path, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()

    def _extract_managed_sections(self, rel_path: str) -> dict[str, str]:
        """Extract VF:BEGIN/VF:END section contents from a partial file."""
        abs_path = self.project_root / rel_path
        content = abs_path.read_text()
        sections = {}
        for match in MARKER_RE.finditer(content):
            sections[match.group(1)] = match.group(2)
        return sections

    def record(
        self,
        rel_path: str,
        source_schema: str,
        file_type: str = "full",
        managed_sections: list[str] | None = None,
    ) -> None:
        """Record a generated file in the manifest.

        Args:
            rel_path: relative path from project root
            source_schema: path to source schema file
            file_type: "full" or "partial"
            managed_sections: for partial files, list of section names
        """
        entry = {
            "sha256": self._hash_file(rel_path),
            "source": source_schema,
            "generator_version": self.generator_version,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "type": file_type,
        }

        # Schema hash for provenance
        if os.path.exists(source_schema):
            entry["schema_hash"] = self._hash_schema(source_schema)

        # Partial file metadata
        if file_type == "partial" and managed_sections:
            entry["managed_sections"] = managed_sections
            sections = self._extract_managed_sections(rel_path)
            section_hashes = {}
            for name, content in sections.items():
                if name in managed_sections:
                    section_hashes[name] = self._hash_bytes(content.encode())
            entry["section_hashes"] = section_hashes

        self.entries[rel_path] = entry

    def save(self) -> None:
        """Write manifest to disk."""
        os.makedirs(self.manifest_file.parent, exist_ok=True)
        data = {
            "version": "1.0",
            "generator_version": self.generator_version,
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

        entry = self.entries[rel_path]

        # For partial files, check managed section hashes only
        if entry.get("type") == "partial" and "section_hashes" in entry:
            current_sections = self._extract_managed_sections(rel_path)
            for name, recorded_hash in entry["section_hashes"].items():
                current_content = current_sections.get(name, "")
                if self._hash_bytes(current_content.encode()) != recorded_hash:
                    return "customized"
            return "stock-managed"

        # For full files, compare whole-file hash
        current_hash = self._hash_file(rel_path)
        recorded_hash = entry.get("sha256", "")

        if current_hash == recorded_hash:
            return "stock-managed"
        return "customized"
