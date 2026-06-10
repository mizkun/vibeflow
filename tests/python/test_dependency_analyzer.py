"""Unit tests for dependency_analyzer — the false-cycle bug a grep test
can't see: 'blocks #N' and 'depends on #N' were both treated as a
forward dependency, manufacturing a cycle out of a correct ordering."""

from core.runtime import dependency_analyzer as da


def test_real_cycle_is_detected():
    issues = [
        {"number": 1, "title": "A", "body": "Depends on #2"},
        {"number": 2, "title": "B", "body": "Depends on #1"},
    ]
    result = da.analyze(issues)
    assert result["cycles"], f"a genuine A<->B cycle must be detected: {result}"


def test_blocks_is_not_a_forward_dependency():
    # #1 blocks #2  (=> #2 depends on #1), #2 depends on #1.
    # These agree; there is NO cycle. The old code read 'blocks #2' as
    # '#1 depends on #2' and reported a false cycle.
    issues = [
        {"number": 1, "title": "Backend", "body": "This blocks #2"},
        {"number": 2, "title": "Frontend", "body": "Depends on #1"},
    ]
    result = da.analyze(issues)
    assert not result["cycles"], f"'blocks' + 'depends on' is not a cycle: {result}"


def test_blocks_creates_the_reverse_edge():
    issues = [
        {"number": 1, "title": "Backend", "body": "blocks #2"},
        {"number": 2, "title": "Frontend", "body": ""},
    ]
    order = da.execution_order(issues)
    nums = [i["number"] for i in order]
    assert nums.index(1) < nums.index(2), (
        f"#1 blocks #2, so #1 must come first: {nums}"
    )


def test_plain_depends_still_orders():
    issues = [
        {"number": 3, "title": "Deploy", "body": "Depends on #1 and #2"},
        {"number": 1, "title": "Backend", "body": ""},
        {"number": 2, "title": "Frontend", "body": ""},
    ]
    order = da.execution_order(issues)
    nums = [i["number"] for i in order]
    assert nums.index(3) > nums.index(1) and nums.index(3) > nums.index(2), (
        f"#3 depends on #1 and #2, so it must come last: {nums}"
    )
