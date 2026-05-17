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
print_summary
