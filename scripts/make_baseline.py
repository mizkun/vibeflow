#!/usr/bin/env python3
"""Generate a baseline hash DB for a VibeFlow release.

Records SHA256 of every file under examples/ so a later `vibeflow upgrade`
can classify a manifest-less project of this version (stock-managed vs
customized). Run this on a VERSION bump.

Usage:
    python3 scripts/make_baseline.py <version>   # e.g. 6.0.0
    python3 scripts/make_baseline.py             # uses ./VERSION
"""

import hashlib
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = REPO_ROOT / "examples"

# Volatile / non-distributed files that should not anchor a baseline.
SKIP_SUFFIXES = (".pyc",)
SKIP_NAMES = {".DS_Store"}
SKIP_REL_PREFIXES = (
    ".vibe/generated-manifest.json",
    ".vibe/runs/",
    ".vibe/reports/",
    ".vibe/checkpoints/",
)


def _hash(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build(version: str) -> dict:
    files = {}
    for p in sorted(EXAMPLES.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(EXAMPLES).as_posix()
        if (p.suffix in SKIP_SUFFIXES or p.name in SKIP_NAMES
                or any(rel.startswith(pre) for pre in SKIP_REL_PREFIXES)
                or "__pycache__" in rel):
            continue
        files[rel] = {"sha256": _hash(p)}
    return {"version": version, "files": files}


def main(argv) -> int:
    version = argv[0] if argv else (REPO_ROOT / "VERSION").read_text().strip()
    out = REPO_ROOT / "core" / "baselines" / f"v{version}.json"
    out.write_text(json.dumps(build(version), indent=2, sort_keys=True) + "\n")
    print(f"Wrote {out} ({len(json.loads(out.read_text())['files'])} files)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
