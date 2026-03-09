#!/usr/bin/env python3
"""
VibeFlow Manifest-aware Upgrade
Safely upgrades project files using manifest or baseline hash classification.

Classification:
- stock-managed: auto-update (safe to overwrite)
- customized: skip + warning (user modified)
- unknown: backup + warning

Usage:
    python3 core/upgrade.py --project-dir . --framework-dir /path/to/vibeflow
    python3 core/upgrade.py --project-dir . --framework-dir /path/to/vibeflow --dry-run
    python3 core/upgrade.py --project-dir . --framework-dir /path/to/vibeflow --allow-dirty
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# Ensure core package is importable
sys.path.insert(0, str(Path(__file__).parent.parent))

from core.baselines.loader import classify_file, load_baseline
from core.generators.manifest import Manifest


# Source map: where to find the latest version of each managed file
# Maps project-relative path → framework-relative source path
def build_source_map(framework_dir: str) -> dict[str, str]:
    """Build mapping from project paths to framework source files."""
    fw = Path(framework_dir)
    source_map = {}

    # examples/.vibe/hooks/* → .vibe/hooks/*
    hooks_dir = fw / "examples" / ".vibe" / "hooks"
    if hooks_dir.exists():
        for f in hooks_dir.iterdir():
            if f.is_file() and not f.name.startswith(".") and f.name != "__pycache__":
                source_map[f".vibe/hooks/{f.name}"] = str(f)

    # examples/.vibe/policy.yaml → .vibe/policy.yaml
    policy = fw / "examples" / ".vibe" / "policy.yaml"
    if policy.exists():
        source_map[".vibe/policy.yaml"] = str(policy)

    # examples/.vibe/context/STATUS.md → .vibe/context/STATUS.md
    status = fw / "examples" / ".vibe" / "context" / "STATUS.md"
    if status.exists():
        source_map[".vibe/context/STATUS.md"] = str(status)

    # examples/.vibe/roles/* → .vibe/roles/*
    roles_dir = fw / "examples" / ".vibe" / "roles"
    if roles_dir.exists():
        for f in roles_dir.iterdir():
            if f.is_file() and not f.name.startswith("."):
                source_map[f".vibe/roles/{f.name}"] = str(f)

    # lib/commands/* → .claude/commands/*
    cmds_dir = fw / "lib" / "commands"
    if cmds_dir.exists():
        for f in cmds_dir.iterdir():
            if f.is_file() and not f.name.startswith("."):
                source_map[f".claude/commands/{f.name}"] = str(f)

    # examples/.github/ISSUE_TEMPLATE/* → .github/ISSUE_TEMPLATE/*
    templates_dir = fw / "examples" / ".github" / "ISSUE_TEMPLATE"
    if templates_dir.exists():
        for f in templates_dir.iterdir():
            if f.is_file() and not f.name.startswith("."):
                source_map[f".github/ISSUE_TEMPLATE/{f.name}"] = str(f)

    # examples/CLAUDE.md → CLAUDE.md (only if not partial)
    claude_md = fw / "examples" / "CLAUDE.md"
    if claude_md.exists():
        source_map["CLAUDE.md"] = str(claude_md)

    return source_map


def is_dirty_tree(project_dir: str) -> bool:
    """Check if the git working tree has uncommitted changes."""
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=project_dir,
            capture_output=True,
            text=True,
        )
        return bool(result.stdout.strip())
    except Exception:
        return False


def detect_project_version(project_dir: str) -> str:
    """Detect the project's vibeflow version."""
    version_file = Path(project_dir) / ".vibe" / "version"
    if version_file.exists():
        return version_file.read_text().strip()
    return "3.5.0"  # Default assumption for legacy projects


def classify_with_manifest_or_baseline(
    project_dir: str, framework_dir: str
) -> tuple[dict[str, str], str]:
    """Classify files using manifest (preferred) or baseline (fallback).

    Returns: (classifications dict, method used)
    """
    project = Path(project_dir)
    manifest_path = project / ".vibe" / "generated-manifest.json"

    if manifest_path.exists():
        # Use manifest
        manifest = Manifest(project_dir)
        source_map = build_source_map(framework_dir)
        classifications = {}
        for rel_path in source_map:
            abs_path = project / rel_path
            if abs_path.exists():
                classifications[rel_path] = manifest.classify(rel_path)
            else:
                classifications[rel_path] = "new"
        return classifications, "manifest"

    # Fallback to baseline
    version = detect_project_version(project_dir)
    baselines_dir = str(Path(framework_dir) / "core" / "baselines")
    source_map = build_source_map(framework_dir)
    classifications = {}
    for rel_path in source_map:
        abs_path = project / rel_path
        if abs_path.exists():
            classifications[rel_path] = classify_file(
                project_dir, rel_path, version, baselines_dir
            )
        else:
            classifications[rel_path] = "new"
    return classifications, "baseline"


def run_upgrade(
    project_dir: str,
    framework_dir: str,
    dry_run: bool = False,
) -> dict:
    """Execute the upgrade and return a report."""
    project = Path(project_dir)
    source_map = build_source_map(framework_dir)
    classifications, method = classify_with_manifest_or_baseline(
        project_dir, framework_dir
    )

    report = {
        "timestamp": datetime.now().isoformat(),
        "method": method,
        "framework_version": "unknown",
        "project_version": detect_project_version(project_dir),
        "actions": [],
    }

    version_file = Path(framework_dir) / "VERSION"
    if version_file.exists():
        report["framework_version"] = version_file.read_text().strip()

    for rel_path, classification in sorted(classifications.items()):
        source = source_map.get(rel_path)
        if not source:
            continue

        action = {
            "file": rel_path,
            "classification": classification,
            "action": "skip",
        }

        if classification in ("stock-managed", "new"):
            action["action"] = "update"
            if not dry_run:
                abs_path = project / rel_path
                os.makedirs(abs_path.parent, exist_ok=True)
                shutil.copy2(source, abs_path)

        elif classification == "customized":
            action["action"] = "skip (customized — manual review needed)"

        elif classification == "unknown":
            action["action"] = "skip (unknown — backup recommended)"
            if not dry_run:
                abs_path = project / rel_path
                if abs_path.exists():
                    backup_path = abs_path.with_suffix(abs_path.suffix + ".backup")
                    shutil.copy2(abs_path, backup_path)
                    action["backup"] = str(backup_path.relative_to(project))

        report["actions"].append(action)

    # Write report
    if not dry_run:
        report_dir = project / ".vibe" / "upgrade-reports"
        os.makedirs(report_dir, exist_ok=True)
        report_file = report_dir / f"upgrade-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        with open(report_file, "w") as f:
            json.dump(report, f, indent=2)
            f.write("\n")

        # Update version
        version_file_project = project / ".vibe" / "version"
        if report["framework_version"] != "unknown":
            version_file_project.write_text(report["framework_version"] + "\n")

    return report


def format_report(report: dict, dry_run: bool = False) -> str:
    """Format upgrade report for human display."""
    lines = []

    if dry_run:
        lines.append("Upgrade Plan (dry-run — no files changed)")
    else:
        lines.append("Upgrade Report")
    lines.append("───────────────")
    lines.append(f"  Method: {report['method']}")
    lines.append(f"  From: v{report['project_version']} → v{report['framework_version']}")
    lines.append("")

    updated = [a for a in report["actions"] if a["action"] == "update"]
    skipped = [a for a in report["actions"] if "skip" in a["action"]]

    if updated:
        lines.append(f"  Will update ({len(updated)} files):")
        for a in updated:
            lines.append(f"    ✓ {a['file']} [{a['classification']}]")

    if skipped:
        lines.append(f"  Will skip ({len(skipped)} files):")
        for a in skipped:
            lines.append(f"    ⚠ {a['file']} — {a['action']}")

    lines.append("───────────────")

    if skipped and not dry_run:
        lines.append("  Review skipped files manually and update as needed.")

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="VibeFlow Manifest-aware Upgrade")
    parser.add_argument("--project-dir", required=True, help="Project root directory")
    parser.add_argument("--framework-dir", required=True, help="VibeFlow framework directory")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show upgrade plan without making changes")
    parser.add_argument("--allow-dirty", action="store_true",
                        help="Allow upgrade with uncommitted changes")
    args = parser.parse_args()

    # Check for dirty tree
    if not args.allow_dirty and not args.dry_run:
        if is_dirty_tree(args.project_dir):
            print(
                "ERROR: Working tree has uncommitted changes.\n"
                "Commit or stash changes before upgrading.\n"
                "Use --allow-dirty to override.",
                file=sys.stderr,
            )
            sys.exit(1)

    report = run_upgrade(args.project_dir, args.framework_dir, args.dry_run)
    print(format_report(report, args.dry_run))

    if not args.dry_run:
        updated = sum(1 for a in report["actions"] if a["action"] == "update")
        print(f"\nUpgraded {updated} files.")


if __name__ == "__main__":
    main()
