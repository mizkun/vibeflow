#!/usr/bin/env python3
"""
VibeFlow Generate All — Orchestrator for all generators.
Runs generators in correct order, records results in manifest.

Usage:
    python3 core/generators/generate_all.py --schema-dir core/schema --project-dir . --framework-dir /path/to/vibeflow
    python3 core/generators/generate_all.py --schema-dir core/schema --project-dir . --framework-dir /path/to/vibeflow --target hooks
    python3 core/generators/generate_all.py --schema-dir core/schema --project-dir . --framework-dir /path/to/vibeflow --diff
"""

import argparse
import os
import sys
import tempfile
import shutil
from pathlib import Path

# Ensure core package is importable
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from core.generators.generate_hooks import generate_validate_access, copy_static_hooks
from core.generators.generate_settings import generate_settings
from core.generators.generate_policy import generate_policy
from core.generators.generate_docs import generate_role_docs
from core.generators.generate_claude_md import load_schemas, update_managed_sections
from core.generators.generate_agents_md import generate_agents_md
from core.generators.manifest import Manifest

# Valid targets for --target
VALID_TARGETS = ("hooks", "settings", "policy", "docs", "claude_md", "agents_md", "state", "manifest")

# Generation order: policy → hooks → settings → docs → claude_md → agents_md → state → manifest
GENERATION_ORDER = ["policy", "hooks", "settings", "docs", "claude_md", "agents_md", "state", "manifest"]


def run_target(target: str, schema_dir: str, project_dir: str, framework_dir: str,
               manifest: Manifest, generated_files: list) -> None:
    """Run a single generation target."""
    project = Path(project_dir)

    if target == "policy":
        vibe_dir = str(project / ".vibe")
        os.makedirs(vibe_dir, exist_ok=True)
        generate_policy(os.path.join(schema_dir, "policy.yaml"), vibe_dir)
        generated_files.append((".vibe/policy.yaml", "core/schema/policy.yaml"))

    elif target == "hooks":
        hooks_dir = str(project / ".vibe" / "hooks")
        os.makedirs(hooks_dir, exist_ok=True)
        generate_validate_access(os.path.join(schema_dir, "policy.yaml"), hooks_dir)
        copy_static_hooks(hooks_dir)
        for hook_file in ("validate_access.py", "validate_write.sh", "validate_step7a.py"):
            if (project / ".vibe" / "hooks" / hook_file).exists():
                generated_files.append(
                    (f".vibe/hooks/{hook_file}", "core/schema/policy.yaml")
                )

    elif target == "settings":
        claude_dir = str(project / ".claude")
        os.makedirs(claude_dir, exist_ok=True)
        generate_settings(schema_dir, claude_dir)
        generated_files.append((".claude/settings.json", "core/schema/policy.yaml"))

    elif target == "docs":
        roles_dir = str(project / ".vibe" / "roles")
        os.makedirs(roles_dir, exist_ok=True)
        generate_role_docs(schema_dir, roles_dir)
        # Record each generated role doc
        if (project / ".vibe" / "roles").exists():
            for md_file in sorted((project / ".vibe" / "roles").glob("*.md")):
                generated_files.append(
                    (f".vibe/roles/{md_file.name}", "core/schema/roles.yaml")
                )

    elif target == "claude_md":
        claude_md = project / "CLAUDE.md"
        if claude_md.exists():
            content = claude_md.read_text()
            if "VF:BEGIN" in content:
                schemas = load_schemas(schema_dir)
                updated = update_managed_sections(content, schemas)
                claude_md.write_text(updated)
                generated_files.append(("CLAUDE.md", "core/schema"))
                print(f"Generated: {claude_md}")
            else:
                print(
                    f"WARNING: {claude_md} has no VF:BEGIN/VF:END markers. "
                    f"Skipping. Add markers manually to enable managed sections.",
                    file=sys.stderr,
                )

    elif target == "agents_md":
        agents_md_path = str(project / "AGENTS.md")
        generate_agents_md(schema_dir, agents_md_path)
        generated_files.append(("AGENTS.md", "core/schema"))

    elif target == "state":
        # Copy state templates (project_state.yaml + sessions/iris-main.yaml)
        import shutil

        fw = Path(framework_dir)

        # project_state.yaml
        src_ps = fw / "examples" / ".vibe" / "project_state.yaml"
        dest_ps = project / ".vibe" / "project_state.yaml"
        if src_ps.exists() and not dest_ps.exists():
            os.makedirs(dest_ps.parent, exist_ok=True)
            shutil.copy2(str(src_ps), str(dest_ps))
            print(f"Generated: {dest_ps}")
        if dest_ps.exists():
            generated_files.append((".vibe/project_state.yaml", "core/schema/project_state.yaml"))

        # sessions/iris-main.yaml
        src_iris = fw / "examples" / ".vibe" / "sessions" / "iris-main.yaml"
        dest_iris = project / ".vibe" / "sessions" / "iris-main.yaml"
        if src_iris.exists() and not dest_iris.exists():
            os.makedirs(dest_iris.parent, exist_ok=True)
            shutil.copy2(str(src_iris), str(dest_iris))
            print(f"Generated: {dest_iris}")
        if dest_iris.exists():
            generated_files.append((".vibe/sessions/iris-main.yaml", "core/schema/session_state.yaml"))

    elif target == "manifest":
        # Record all previously generated files in the manifest
        for rel_path, source in generated_files:
            abs_path = project / rel_path
            if abs_path.exists():
                if rel_path == "CLAUDE.md":
                    manifest.record(rel_path, source, file_type="partial",
                                    managed_sections=["roles", "workflow", "hook_list"])
                else:
                    manifest.record(rel_path, source)
        manifest.save()
        print(f"Generated: {project / '.vibe' / 'generated-manifest.json'}")


def run_diff(schema_dir: str, project_dir: str, framework_dir: str,
             targets: list) -> None:
    """Show what would be generated without writing files."""
    # Generate into a temp directory and compare
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_project = Path(tmpdir)
        project = Path(project_dir)

        # Copy existing CLAUDE.md if it exists (needed for partial generation)
        if (project / "CLAUDE.md").exists():
            shutil.copy2(project / "CLAUDE.md", tmp_project / "CLAUDE.md")

        manifest = Manifest(tmpdir)
        generated_files = []

        for target in targets:
            if target == "manifest":
                continue  # Skip manifest in diff mode
            run_target(target, schema_dir, tmpdir, framework_dir, manifest, generated_files)

        # Compare and report
        print("Files that would be generated/updated:")
        print("")
        has_changes = False
        for rel_path, _ in generated_files:
            tmp_file = tmp_project / rel_path
            project_file = project / rel_path
            if not tmp_file.exists():
                continue

            if not project_file.exists():
                print(f"  + {rel_path} (new)")
                has_changes = True
            else:
                tmp_content = tmp_file.read_bytes()
                proj_content = project_file.read_bytes()
                if tmp_content != proj_content:
                    print(f"  ~ {rel_path} (modified)")
                    has_changes = True
                else:
                    print(f"  = {rel_path} (unchanged)")

        if not has_changes:
            print("  (no changes)")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate all VibeFlow project files from schema")
    parser.add_argument("--schema-dir", required=True, help="Path to schema directory")
    parser.add_argument("--project-dir", required=True, help="Project root directory")
    parser.add_argument("--framework-dir", required=True, help="VibeFlow framework directory")
    parser.add_argument("--target", choices=VALID_TARGETS,
                        help="Generate only a specific target")
    parser.add_argument("--diff", action="store_true",
                        help="Show what would be generated without writing")
    args = parser.parse_args()

    # Determine which targets to run
    if args.target:
        targets = [args.target]
    else:
        targets = list(GENERATION_ORDER)

    if args.diff:
        run_diff(args.schema_dir, args.project_dir, args.framework_dir, targets)
        return

    # Validate schema dir
    schema_path = Path(args.schema_dir)
    if not (schema_path / "policy.yaml").exists():
        print(f"ERROR: {schema_path / 'policy.yaml'} not found", file=sys.stderr)
        sys.exit(1)

    # Read VERSION for manifest
    version_file = Path(args.framework_dir) / "VERSION"
    version = version_file.read_text().strip() if version_file.exists() else "unknown"

    manifest = Manifest(args.project_dir, generator_version=version)
    generated_files = []

    for target in targets:
        try:
            run_target(target, args.schema_dir, args.project_dir,
                       args.framework_dir, manifest, generated_files)
        except Exception as e:
            print(f"ERROR in {target}: {e}", file=sys.stderr)
            sys.exit(1)

    print(f"\nGenerated {len(generated_files)} files successfully.")


if __name__ == "__main__":
    main()
