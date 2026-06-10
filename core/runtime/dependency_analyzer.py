"""Dependency Analysis for VibeFlow v6 Iris-Only Architecture.
Analyzes issue dependencies and determines execution order.
Supports parallel batch detection and cycle detection.
"""

from __future__ import annotations

import re
from typing import Any, Dict, List, Set


def analyze(issues: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Analyze dependencies between issues and group into execution batches.

    Args:
        issues: List of issue dicts with number, title, body.

    Returns:
        Dict with:
            - batches: list of lists of issue numbers (parallel groups)
            - dependencies: dict mapping issue number to list of deps
            - warnings: list of warning strings
            - cycles: list of cycle descriptions
    """
    issue_numbers = {i["number"] for i in issues}
    deps = _extract_dependencies(issues, issue_numbers)

    # Detect cycles
    cycles = _detect_cycles(deps, issue_numbers)
    warnings = [f"Circular dependency detected: {c}" for c in cycles]

    # Topological sort into batches
    batches = _topological_batches(deps, issue_numbers)

    return {
        "batches": batches,
        "dependencies": deps,
        "warnings": warnings,
        "cycles": cycles,
    }


def execution_order(issues: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Return issues sorted in execution order (respecting dependencies).

    Issues without dependencies come first. Dependent issues come after
    their dependencies.
    """
    issue_map = {i["number"]: i for i in issues}
    issue_numbers = set(issue_map.keys())
    deps = _extract_dependencies(issues, issue_numbers)
    batches = _topological_batches(deps, issue_numbers)

    ordered = []
    for batch in batches:
        for num in sorted(batch):
            if num in issue_map:
                ordered.append(issue_map[num])

    return ordered


# "this blocks #N" / "blocking #N" / "before #N" means N depends on THIS —
# the reverse edge. Treating it as a forward dependency manufactured a
# false cycle whenever the blocked issue also said "depends on #this".
_BLOCKS_RE = re.compile(r"\b(?:blocks?|blocking|before)\s+#(\d+)", re.IGNORECASE)


def _extract_dependencies(
    issues: List[Dict[str, Any]], valid_numbers: Set[int]
) -> Dict[int, List[int]]:
    """Extract directional dependency relationships from issue bodies."""
    deps: Dict[int, List[int]] = {i["number"]: [] for i in issues}

    for issue in issues:
        num = issue["number"]
        body = issue.get("body", "") or ""

        # Reverse edges: "this blocks #N" → N depends on this issue.
        for ref in _BLOCKS_RE.findall(body):
            ref_num = int(ref)
            if ref_num in valid_numbers and ref_num != num:
                deps[ref_num].append(num)

        # Forward edges: every other "#N" → this issue depends on N.
        # Strip the blocks-clauses first so their numbers aren't double-counted.
        forward_body = _BLOCKS_RE.sub("", body)
        for ref in re.findall(r"#(\d+)", forward_body):
            ref_num = int(ref)
            if ref_num in valid_numbers and ref_num != num and ref_num not in deps[num]:
                deps[num].append(ref_num)

    return deps


def _topological_batches(
    deps: Dict[int, List[int]], all_numbers: Set[int]
) -> List[List[int]]:
    """Group issues into execution batches using topological sort.

    Each batch contains issues that can run in parallel.
    """
    remaining = set(all_numbers)
    completed: Set[int] = set()
    batches: List[List[int]] = []

    max_iterations = len(all_numbers) + 1
    for _ in range(max_iterations):
        if not remaining:
            break

        # Find issues whose dependencies are all completed
        batch = []
        for num in sorted(remaining):
            issue_deps = deps.get(num, [])
            if all(d in completed or d not in all_numbers for d in issue_deps):
                batch.append(num)

        if not batch:
            # Remaining issues have unresolvable deps (cycles)
            batch = sorted(remaining)
            batches.append(batch)
            break

        batches.append(batch)
        completed.update(batch)
        remaining -= set(batch)

    return batches


def _detect_cycles(
    deps: Dict[int, List[int]], all_numbers: Set[int]
) -> List[str]:
    """Detect circular dependencies using DFS."""
    cycles = []
    visited: Set[int] = set()
    in_stack: Set[int] = set()

    def dfs(node: int, path: List[int]) -> None:
        if node in in_stack:
            cycle_start = path.index(node)
            cycle = path[cycle_start:] + [node]
            cycles.append(" → ".join(f"#{n}" for n in cycle))
            return
        if node in visited:
            return

        visited.add(node)
        in_stack.add(node)
        path.append(node)

        for dep in deps.get(node, []):
            if dep in all_numbers:
                dfs(dep, path)

        path.pop()
        in_stack.remove(node)

    for num in sorted(all_numbers):
        if num not in visited:
            dfs(num, [])

    return cycles
