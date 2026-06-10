"""Unit tests for the runtime deploy contract, in pytest form.

Mirrors test_runtime_deploy.sh but with real tracebacks (the bash tests
pipe python through `2>/dev/null`, hiding the diagnosis on failure)."""

import ast
import importlib
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
RUNTIME = REPO_ROOT / "core" / "runtime"

RUNTIME_MODULES = sorted(
    p.stem for p in RUNTIME.glob("*.py") if p.name != "__init__.py"
)


def test_all_runtime_modules_import_flat(flat_runtime):
    """Every runtime module must import by bare name from a flat dir —
    the layout setup/upgrade actually deploy into .vibe/runtime/."""
    sys.path.insert(0, str(flat_runtime))
    try:
        failures = []
        for mod in RUNTIME_MODULES:
            sys.modules.pop(mod, None)
            try:
                importlib.import_module(mod)
            except Exception as e:  # noqa: BLE001
                failures.append(f"{mod}: {type(e).__name__}: {e}")
        assert not failures, "flat import failures:\n" + "\n".join(failures)
    finally:
        sys.path.remove(str(flat_runtime))
        for mod in RUNTIME_MODULES:
            sys.modules.pop(mod, None)


@pytest.mark.parametrize("mod", RUNTIME_MODULES)
def test_no_future_import_trapped_in_docstring(mod):
    """`from __future__ import annotations` must be a real statement, not
    text inside the module docstring (a silent no-op)."""
    src = (RUNTIME / f"{mod}.py").read_text(encoding="utf-8")
    if "from __future__" not in src:
        return
    tree = ast.parse(src)
    real = any(
        isinstance(n, ast.ImportFrom) and n.module == "__future__"
        for n in ast.walk(tree)
    )
    assert real, f"{mod}.py: future import is trapped inside the docstring"
