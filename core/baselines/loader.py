#!/usr/bin/env python3
from __future__ import annotations
"""
VibeFlow Baseline Loader
Classifies project files against known baseline hashes.

Used by upgrade to determine which files are safe to overwrite (stock-managed),
which have been customized by the user, and which are unknown.

Classification:
- stock-managed: file matches baseline hash (unmodified)
- customized: file exists in baseline but hash differs (user modified)
- unknown: file not in baseline
"""

import hashlib
import json
from pathlib import Path


def _hash_file(path: Path) -> str:
    """Compute SHA256 hash of a file."""
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def load_baseline(version: str, baselines_dir: str | None = None) -> dict:
    """Load a baseline hash DB for a given version."""
    if baselines_dir:
        base_path = Path(baselines_dir)
    else:
        base_path = Path(__file__).parent

    baseline_file = base_path / f"v{version}.json"
    if not baseline_file.exists():
        return {}

    with open(baseline_file) as f:
        return json.load(f)


def classify_file(
    project_dir: str,
    rel_path: str,
    version: str,
    baselines_dir: str | None = None,
) -> str:
    """Classify a single file against the baseline.

    Returns: "stock-managed", "customized", or "unknown"
    """
    baseline = load_baseline(version, baselines_dir)
    files = baseline.get("files", {})

    if rel_path not in files:
        return "unknown"

    entry = files[rel_path]

    # Generated files (e.g., settings.json from heredoc) can't be hash-compared
    if entry.get("type") == "generated":
        abs_path = Path(project_dir) / rel_path
        return "stock-managed" if abs_path.exists() else "unknown"

    abs_path = Path(project_dir) / rel_path
    if not abs_path.exists():
        return "unknown"

    current_hash = _hash_file(abs_path)
    baseline_hash = entry.get("sha256", "")

    if current_hash == baseline_hash:
        return "stock-managed"
    return "customized"


def classify_project(
    project_dir: str,
    version: str,
    baselines_dir: str | None = None,
) -> dict[str, str]:
    """Classify all baseline-tracked files in a project.

    Returns: dict mapping rel_path → classification
    """
    baseline = load_baseline(version, baselines_dir)
    files = baseline.get("files", {})
    project = Path(project_dir)

    results = {}
    for rel_path in files:
        abs_path = project / rel_path
        if abs_path.exists():
            results[rel_path] = classify_file(
                project_dir, rel_path, version, baselines_dir
            )

    return results
