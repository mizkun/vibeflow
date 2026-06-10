"""Pytest config for VibeFlow runtime unit tests.

Adds the repo root to sys.path so `from core.runtime import ...` works,
and exposes a flat-deploy fixture (modules copied by basename, the way
they actually land in a project's .vibe/runtime/).
"""

import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

import pytest  # noqa: E402


@pytest.fixture
def flat_runtime(tmp_path):
    """Copy core/runtime/*.py flat into a temp dir (no package), mirroring
    how setup/upgrade deploy them into .vibe/runtime/. Returns the dir."""
    dest = tmp_path / "runtime"
    dest.mkdir()
    for py in (REPO_ROOT / "core" / "runtime").glob("*.py"):
        if py.name == "__init__.py":
            continue
        shutil.copy2(py, dest / py.name)
    return dest
