#!/bin/bash

# VibeFlow Test: v6 — Structured Spec Verification Engine
# Tests core/runtime/spec_verify.py: static verification of Story/Contract spec.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

SPEC_VERIFY="${FRAMEWORK_DIR}/core/runtime/spec_verify.py"

# ──────────────────────────────────────────────
# Fixture: a project with structured spec + matching source files
# ──────────────────────────────────────────────
create_spec_fixture() {
    local dir="${1:-$TEST_DIR}"
    cd "$dir"

    mkdir -p .vibe/spec/stories .vibe/spec/contracts
    mkdir -p src/pneuma_core/memory src/pneuma_core/models src/pneuma_core/runtime
    mkdir -p tests/memory

    # source files referenced by the spec
    echo "def recall(): pass" > src/pneuma_core/memory/recall.py
    echo "def save_episode(): pass" > src/pneuma_core/memory/store.py
    echo "class Character: pass" > src/pneuma_core/models/character.py
    echo "x = 1" > src/pneuma_core/runtime/engine.py
    echo "def test_x(): pass" > tests/memory/test_personality_bias.py

    # Story: memory
    cat > .vibe/spec/stories/memory.yaml << 'YAML'
id: memory
one_liner: 記憶レイヤー
invariants:
  - id: personality-biased-recall
    text: 性格が違えば想起される記憶が変わる
    test: tests/memory/test_personality_bias.py
    source_ref: src/pneuma_core/memory/recall.py:recall
  - id: importance-threshold
    text: importance が閾値未満なら保存されない
    source_ref: src/pneuma_core/memory/store.py:save_episode
source_files:
  - src/pneuma_core/memory/
depends_on:
  - models
YAML

    # Story: models
    cat > .vibe/spec/stories/models.yaml << 'YAML'
id: models
one_liner: ドメインモデル
invariants:
  - id: character-has-name
    text: Character は name を必ず持つ
source_files:
  - src/pneuma_core/models/
YAML

    # Contract: character
    cat > .vibe/spec/contracts/character.yaml << 'YAML'
id: character
schema_ref: pneuma_core.models.character.Character
producers:
  - src/pneuma_core/models/character.py
consumers:
  - src/pneuma_core/runtime/engine.py
story: models
YAML
}

# Run the verifier; echoes combined stdout, exit code captured separately
run_verify() {
    python3 "$SPEC_VERIFY" "$TEST_DIR/.vibe/spec" "$TEST_DIR" 2>&1
}

# ──────────────────────────────────────────────
describe "spec_verify — module exists"

test_module_exists() {
    assert_file_exists "$SPEC_VERIFY" "core/runtime/spec_verify.py must exist"
}
run_test "spec_verify.py runtime exists" test_module_exists

# ──────────────────────────────────────────────
describe "spec_verify — valid spec passes"

test_valid_spec_passes() {
    create_spec_fixture
    local out
    out=$(run_verify) || { fail "verifier exited non-zero on valid spec"; return 1; }
    echo "$out" | grep -q "RESULT: PASS" || { fail "expected RESULT: PASS, got: $out"; return 1; }
    return 0
}
run_test "valid spec yields RESULT: PASS and exit 0" test_valid_spec_passes

test_valid_spec_stats() {
    create_spec_fixture
    local out
    out=$(run_verify)
    echo "$out" | grep -q "stories: 2" || { fail "expected 2 stories: $out"; return 1; }
    echo "$out" | grep -q "contracts: 1" || { fail "expected 1 contract: $out"; return 1; }
    return 0
}
run_test "reports story/contract counts" test_valid_spec_stats

test_pending_count() {
    create_spec_fixture
    local out
    out=$(run_verify)
    # 3 invariants total; only personality-biased-recall has a test → 2 pending
    echo "$out" | grep -qi "pending" || { fail "expected pending count in output: $out"; return 1; }
    echo "$out" | grep -q "2" || { fail "expected 2 pending invariants: $out"; return 1; }
    return 0
}
run_test "reports pending (untested) invariant count" test_pending_count

# ──────────────────────────────────────────────
describe "spec_verify — structural errors"

test_missing_required_field() {
    create_spec_fixture
    # remove required field one_liner from models story
    cat > "$TEST_DIR/.vibe/spec/stories/models.yaml" << 'YAML'
id: models
invariants: []
source_files:
  - src/pneuma_core/models/
YAML
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero exit on missing field"; return 1; }
    echo "$out" | grep -q "RESULT: FAIL" || { fail "expected RESULT: FAIL: $out"; return 1; }
    echo "$out" | grep -qi "one_liner" || { fail "error should name missing field one_liner: $out"; return 1; }
    return 0
}
run_test "missing required field is an error" test_missing_required_field

test_id_filename_mismatch() {
    create_spec_fixture
    # story file name says models but id says wrong-id
    cat > "$TEST_DIR/.vibe/spec/stories/models.yaml" << 'YAML'
id: wrong-id
one_liner: ドメインモデル
invariants: []
source_files:
  - src/pneuma_core/models/
YAML
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero exit on id/filename mismatch"; return 1; }
    echo "$out" | grep -qi "wrong-id\|filename\|mismatch" || { fail "error should flag id/filename mismatch: $out"; return 1; }
    return 0
}
run_test "id must match filename" test_id_filename_mismatch

test_dangling_story_reference() {
    create_spec_fixture
    # contract references a story that does not exist
    cat > "$TEST_DIR/.vibe/spec/contracts/character.yaml" << 'YAML'
id: character
schema_ref: pneuma_core.models.character.Character
producers:
  - src/pneuma_core/models/character.py
consumers:
  - src/pneuma_core/runtime/engine.py
story: nonexistent-story
YAML
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero exit on dangling story ref"; return 1; }
    echo "$out" | grep -qi "nonexistent-story" || { fail "error should name dangling story ref: $out"; return 1; }
    return 0
}
run_test "contract.story must reference an existing story" test_dangling_story_reference

# ──────────────────────────────────────────────
describe "spec_verify — drift detection (stale paths)"

test_missing_source_file() {
    create_spec_fixture
    # delete a source file the spec still references → stale spec
    rm -rf "$TEST_DIR/src/pneuma_core/models"
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero exit on missing source file"; return 1; }
    echo "$out" | grep -qi "models" || { fail "error should name the stale path: $out"; return 1; }
    return 0
}
run_test "missing source_files path is an error" test_missing_source_file

test_missing_test_path() {
    create_spec_fixture
    # invariant references a test file that does not exist
    rm -f "$TEST_DIR/tests/memory/test_personality_bias.py"
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero exit on missing test path"; return 1; }
    echo "$out" | grep -qi "test_personality_bias" || { fail "error should name the missing test: $out"; return 1; }
    return 0
}
run_test "invariant test path that does not exist is an error" test_missing_test_path

# ──────────────────────────────────────────────
describe "spec_verify — more drift & robustness"

test_malformed_yaml() {
    create_spec_fixture
    printf 'id: [unclosed\n  bad: indent\n' > "$TEST_DIR/.vibe/spec/stories/broken.yaml"
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero exit on malformed YAML"; return 1; }
    echo "$out" | grep -qi "parse error\|broken" || { fail "should report a parse error: $out"; return 1; }
    return 0
}
run_test "malformed YAML is a parse error, not a crash" test_malformed_yaml

test_dangling_depends_on() {
    create_spec_fixture
    cat > "$TEST_DIR/.vibe/spec/stories/memory.yaml" << 'YAML'
id: memory
one_liner: 記憶レイヤー
invariants: []
source_files:
  - src/pneuma_core/memory/
depends_on:
  - ghost-domain
YAML
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero exit on dangling depends_on"; return 1; }
    echo "$out" | grep -qi "ghost-domain" || { fail "error should name dangling depends_on: $out"; return 1; }
    return 0
}
run_test "story.depends_on must reference an existing story" test_dangling_depends_on

test_contract_producer_drift() {
    create_spec_fixture
    # delete the producer file the contract still references
    rm -f "$TEST_DIR/src/pneuma_core/models/character.py"
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero exit on producer drift"; return 1; }
    echo "$out" | grep -qi "character.py\|producers" || { fail "error should flag producer drift: $out"; return 1; }
    return 0
}
run_test "contract producer path drift is an error" test_contract_producer_drift

test_stale_source_ref() {
    create_spec_fixture
    cat > "$TEST_DIR/.vibe/spec/stories/memory.yaml" << 'YAML'
id: memory
one_liner: 記憶レイヤー
invariants:
  - id: importance-threshold
    text: importance が閾値未満なら保存されない
    source_ref: src/pneuma_core/memory/gone.py:save_episode
source_files:
  - src/pneuma_core/memory/
YAML
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero exit on stale source_ref"; return 1; }
    echo "$out" | grep -qi "gone.py\|source_ref" || { fail "error should flag stale source_ref: $out"; return 1; }
    return 0
}
run_test "stale invariant source_ref (with :symbol) is an error" test_stale_source_ref

test_non_list_field() {
    create_spec_fixture
    cat > "$TEST_DIR/.vibe/spec/stories/models.yaml" << 'YAML'
id: models
one_liner: ドメインモデル
invariants: []
source_files: src/pneuma_core/models/
YAML
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero exit on non-list source_files"; return 1; }
    echo "$out" | grep -qi "must be a list" || { fail "error should flag non-list field: $out"; return 1; }
    return 0
}
run_test "non-list field (source_files as string) is an error" test_non_list_field

test_stale_schema_ref_warns() {
    create_spec_fixture
    cat > "$TEST_DIR/.vibe/spec/contracts/character.yaml" << 'YAML'
id: character
schema_ref: pneuma_core.ghost.Thing
producers:
  - src/pneuma_core/models/character.py
consumers:
  - src/pneuma_core/runtime/engine.py
story: models
YAML
    local out
    out=$(run_verify) || { fail "unresolvable schema_ref should warn, not fail"; return 1; }
    echo "$out" | grep -q "RESULT: PASS" || { fail "schema_ref drift should be a warning, still PASS: $out"; return 1; }
    echo "$out" | grep -qi "schema_ref" || { fail "should warn about schema_ref: $out"; return 1; }
    return 0
}
run_test "unresolvable schema_ref is a warning (not a hard error)" test_stale_schema_ref_warns

# ──────────────────────────────────────────────
describe "spec_verify — robustness & symbol drift (codex follow-up)"

test_non_string_list_element() {
    create_spec_fixture
    cat > "$TEST_DIR/.vibe/spec/stories/models.yaml" << 'YAML'
id: models
one_liner: ドメインモデル
invariants: []
source_files:
  - 123
YAML
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero on non-string source_files element"; return 1; }
    echo "$out" | grep -qi "string" || { fail "should flag non-string path element, not crash: $out"; return 1; }
    return 0
}
run_test "non-string list element is a structural error (not a crash)" test_non_string_list_element

test_stale_source_ref_symbol() {
    create_spec_fixture
    # recall.py exists and defines recall(); point source_ref at a missing symbol
    cat > "$TEST_DIR/.vibe/spec/stories/memory.yaml" << 'YAML'
id: memory
one_liner: 記憶レイヤー
invariants:
  - id: importance-threshold
    text: importance が閾値未満なら保存されない
    source_ref: src/pneuma_core/memory/recall.py:nonexistent_func
source_files:
  - src/pneuma_core/memory/
YAML
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero on stale source_ref symbol"; return 1; }
    echo "$out" | grep -qi "nonexistent_func\|symbol" || { fail "should flag missing symbol: $out"; return 1; }
    return 0
}
run_test "stale invariant source_ref symbol is an error" test_stale_source_ref_symbol

test_source_ref_symbol_only_imported() {
    create_spec_fixture
    # a file that only IMPORTS the symbol — does not define it
    echo "from somewhere import recall" > "$TEST_DIR/src/pneuma_core/memory/proxy.py"
    cat > "$TEST_DIR/.vibe/spec/stories/memory.yaml" << 'YAML'
id: memory
one_liner: 記憶レイヤー
invariants:
  - id: importance-threshold
    text: importance ルール
    source_ref: src/pneuma_core/memory/proxy.py:recall
source_files:
  - src/pneuma_core/memory/
YAML
    local out rc
    out=$(run_verify) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "expected non-zero: source_ref symbol is only imported, not defined"; return 1; }
    echo "$out" | grep -qi "symbol" || { fail "should flag imported-not-defined symbol: $out"; return 1; }
    return 0
}
run_test "source_ref symbol that is only imported (not defined) is an error" test_source_ref_symbol_only_imported

# ──────────────────────────────────────────────
describe "spec_verify — vibeflow CLI subcommand"

test_cli_subcommand_passes() {
    create_spec_fixture
    local out rc
    cd "$TEST_DIR"
    out=$(bash "${FRAMEWORK_DIR}/bin/vibeflow" spec-verify 2>&1) && rc=0 || rc=$?
    [ "$rc" -eq 0 ] || { fail "vibeflow spec-verify should exit 0 on valid spec: $out"; return 1; }
    echo "$out" | grep -q "RESULT: PASS" || { fail "expected RESULT: PASS from CLI: $out"; return 1; }
    return 0
}
run_test "vibeflow spec-verify runs the verifier on the project" test_cli_subcommand_passes

test_cli_subcommand_fails_on_drift() {
    create_spec_fixture
    rm -rf "$TEST_DIR/src/pneuma_core/models"
    local out rc
    cd "$TEST_DIR"
    out=$(bash "${FRAMEWORK_DIR}/bin/vibeflow" spec-verify 2>&1) && rc=0 || rc=$?
    [ "$rc" -ne 0 ] || { fail "vibeflow spec-verify should exit non-zero on drift"; return 1; }
    return 0
}
run_test "vibeflow spec-verify exits non-zero on spec drift" test_cli_subcommand_fails_on_drift

# ──────────────────────────────────────────────
describe "spec_verify — empty directory placeholders"

test_empty_dir_source_files_is_error() {
    create_spec_fixture
    # A Story pointing at an empty directory is a placeholder for
    # unimplemented work — it must not pass as As-Is spec.
    mkdir -p "$TEST_DIR/apps/aituber"
    cat > .vibe/spec/stories/aituber.yaml << 'YAML'
id: aituber
one_liner: 未実装のプレースホルダ
invariants: []
source_files:
  - apps/aituber/
YAML
    local out rc=0
    out=$(run_verify) || rc=$?
    [ "$rc" -ne 0 ] || { fail "empty-directory source_files must fail verification"; return 1; }
    echo "$out" | grep -q "empty directory" || { fail "error should mention empty directory, got: $out"; return 1; }
    return 0
}
run_test "empty directory in source_files is an error" test_empty_dir_source_files_is_error

test_gitkeep_only_dir_is_error() {
    create_spec_fixture
    mkdir -p "$TEST_DIR/apps/ghost"
    touch "$TEST_DIR/apps/ghost/.gitkeep"
    cat > .vibe/spec/stories/ghost.yaml << 'YAML'
id: ghost
one_liner: .gitkeep だけのプレースホルダ
invariants: []
source_files:
  - apps/ghost/
YAML
    local rc=0
    run_verify > /dev/null || rc=$?
    [ "$rc" -ne 0 ] || { fail ".gitkeep-only directory must fail verification"; return 1; }
    return 0
}
run_test ".gitkeep-only directory is an error" test_gitkeep_only_dir_is_error

test_nested_files_dir_passes() {
    create_spec_fixture
    # Files nested in subdirectories must count (no false positives on
    # parent-directory references)
    mkdir -p "$TEST_DIR/apps/real/sub"
    echo "x = 1" > "$TEST_DIR/apps/real/sub/mod.py"
    cat > .vibe/spec/stories/real.yaml << 'YAML'
id: real
one_liner: ネストしたファイルを持つ実装済みドメイン
invariants: []
source_files:
  - apps/real/
YAML
    local out rc=0
    out=$(run_verify) || rc=$?
    if [ "$rc" -ne 0 ]; then
        fail "directory with nested files must pass, got: $out"
        return 1
    fi
    return 0
}
run_test "directory with only nested files passes" test_nested_files_dir_passes

# ──────────────────────────────────────────────
describe "spec_verify --run-tests — invariant execution layer"

# Fixture with bash-runnable invariant tests (no pytest/node dependency)
create_runnable_spec_fixture() {
    cd "$TEST_DIR"
    mkdir -p .vibe/spec/stories src/core tests
    echo "x = 1" > src/core/mod.py
    printf '#!/bin/bash\nexit 0\n' > tests/inv_ok.sh
    printf '#!/bin/bash\necho broken; exit 1\n' > tests/inv_fail.sh
    cat > .vibe/spec/stories/core.yaml << 'YAML'
id: core
one_liner: コアドメイン
invariants:
  - id: holds
    text: 守られている不変条件
    test: tests/inv_ok.sh
  - id: broken
    text: 破られている不変条件
    test: tests/inv_fail.sh
  - id: unproven
    text: テストのない不変条件
source_files:
  - src/core/
YAML
}

run_verify_tests_json() {
    python3 "$SPEC_VERIFY" "$TEST_DIR/.vibe/spec" "$TEST_DIR" --run-tests --json 2>/dev/null
}

test_run_tests_reports_three_states() {
    create_runnable_spec_fixture
    local out rc=0
    out=$(run_verify_tests_json) || rc=$?
    [ "$rc" -ne 0 ] || { fail "a violated invariant must make --run-tests exit non-zero"; return 1; }
    echo "$out" | python3 -c "
import json, sys
r = json.load(sys.stdin)
inv = {i['id']: i['status'] for i in r.get('invariants', [])}
assert inv.get('holds') == 'verified', f'passing test must be verified: {inv}'
assert inv.get('broken') == 'violated', f'failing test must be violated: {inv}'
assert inv.get('unproven') == 'pending', f'untested invariant stays pending: {inv}'
print('OK')
" | grep -q OK || { fail "expected verified/violated/pending statuses, got: $out"; return 1; }
    return 0
}
run_test "--run-tests yields verified / violated / pending" test_run_tests_reports_three_states

test_run_tests_all_green_exits_zero() {
    create_runnable_spec_fixture
    # make the broken one pass
    printf '#!/bin/bash\nexit 0\n' > "$TEST_DIR/tests/inv_fail.sh"
    local rc=0
    run_verify_tests_json > /dev/null || rc=$?
    assert_equals "0" "$rc" "all invariant tests green → exit 0"
}
run_test "--run-tests exits 0 when all invariant tests pass" test_run_tests_all_green_exits_zero

test_run_tests_without_flag_unchanged() {
    create_runnable_spec_fixture
    # without --run-tests the failing test must NOT affect the verdict
    local rc=0
    python3 "$SPEC_VERIFY" "$TEST_DIR/.vibe/spec" "$TEST_DIR" > /dev/null 2>&1 || rc=$?
    assert_equals "0" "$rc" "static mode must not run tests"
}
run_test "static mode (no flag) does not execute tests" test_run_tests_without_flag_unchanged

test_healthcheck_uses_run_tests() {
    assert_file_contains "${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-healthcheck/SKILL.md" \
        "run-tests" "healthcheck must run the invariant execution layer" || return 1
}
run_test "healthcheck SKILL runs spec-verify --run-tests" test_healthcheck_uses_run_tests

# ──────────────────────────────────────────────
describe "spec_verify — pending invariant convergence pressure"

test_json_lists_pending_invariants() {
    create_runnable_spec_fixture
    local out
    out=$(python3 "$SPEC_VERIFY" "$TEST_DIR/.vibe/spec" "$TEST_DIR" --json 2>/dev/null) || true
    echo "$out" | python3 -c "
import json, sys
r = json.load(sys.stdin)
pend = r.get('stats', {}).get('pending_invariants')
assert isinstance(pend, list), f'stats.pending_invariants must be a list: {pend}'
ids = {(p['story'], p['id']) for p in pend}
assert ('core', 'unproven') in ids, f'untested invariant must be listed: {ids}'
assert ('core', 'holds') not in ids, f'tested invariants must not be listed: {ids}'
print('OK')
" | grep -q OK || { fail "pending invariant list missing or wrong, got: $out"; return 1; }
    return 0
}
run_test "--json lists pending invariants (story/id/text)" test_json_lists_pending_invariants

test_healthcheck_records_spec_health() {
    local f="${FRAMEWORK_DIR}/examples/.claude/skills/vibeflow-healthcheck/SKILL.md"
    assert_file_contains "$f" "Spec Health" \
        "healthcheck must record a Spec Health line into STATUS.md" || return 1
    assert_file_contains "$f" "直近 10 行" \
        "Spec Health history must be bounded (STATUS.md is Tier-1 always-loaded)" || return 1
    assert_file_contains "$f" "補強 Issue" \
        "healthcheck must propose a reinforcement issue when pending stagnates" || return 1
}
run_test "healthcheck records Spec Health and proposes reinforcement issues" test_healthcheck_records_spec_health

# ──────────────────────────────────────────────
print_summary
