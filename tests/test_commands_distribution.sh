#!/bin/bash

# Tests that every slash command advertised in README.md is actually
# distributed to projects, and that the Playwright MCP example points
# at a package that exists on npm.
#
# Background: README/CLAUDE.md advertised /execute-issue, /execute-all
# and /patch, but create_commands.sh never deployed them — a PO typing
# the documented command got "unknown command" with no way to recover.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"

readme_commands() {
    # Extract command names from README's command table rows: | `/cmd ...` | ... |
    grep -E '^\| `/' "${FRAMEWORK_DIR}/README.md" \
        | sed -E 's/^\| `\/([a-z0-9-]+).*/\1/'
}

test_readme_commands_have_sources() {
    local missing=""
    local cmd
    while IFS= read -r cmd; do
        [ -f "${FRAMEWORK_DIR}/lib/commands/${cmd}.md" ] || missing="${missing} ${cmd}"
    done < <(readme_commands)
    if [ -n "$missing" ]; then
        fail "README advertises commands with no lib/commands source:${missing}"
        return 1
    fi
    return 0
}

test_readme_commands_in_distribution_list() {
    local missing=""
    local cmd
    while IFS= read -r cmd; do
        grep -q "\"${cmd}:" "${FRAMEWORK_DIR}/lib/create_commands.sh" || missing="${missing} ${cmd}"
    done < <(readme_commands)
    if [ -n "$missing" ]; then
        fail "README advertises commands missing from create_commands.sh deploy list:${missing}"
        return 1
    fi
    return 0
}

test_readme_commands_in_examples() {
    local missing=""
    local cmd
    while IFS= read -r cmd; do
        [ -f "${FRAMEWORK_DIR}/examples/.claude/commands/${cmd}.md" ] || missing="${missing} ${cmd}"
    done < <(readme_commands)
    if [ -n "$missing" ]; then
        fail "README advertises commands missing from examples/.claude/commands:${missing}"
        return 1
    fi
    return 0
}

test_mcp_example_uses_real_package() {
    local f="${FRAMEWORK_DIR}/examples/.mcp.json.example"
    assert_file_not_contains "$f" "@anthropic-ai/mcp-playwright" \
        ".mcp.json.example must not reference the nonexistent @anthropic-ai/mcp-playwright" || return 1
    assert_file_contains "$f" "@playwright/mcp" \
        ".mcp.json.example should reference @playwright/mcp" || return 1
}

test_playwright_docs_use_real_package() {
    local f="${FRAMEWORK_DIR}/docs/playwright.md"
    assert_file_not_contains "$f" "@anthropic-ai/mcp-playwright" \
        "docs/playwright.md must not reference the nonexistent @anthropic-ai/mcp-playwright" || return 1
    assert_file_contains "$f" "@playwright/mcp" \
        "docs/playwright.md should reference @playwright/mcp" || return 1
}

describe "Command distribution — README ⇄ deploy consistency"
run_test "README commands all have lib/commands sources" test_readme_commands_have_sources
run_test "README commands are all in the create_commands deploy list" test_readme_commands_in_distribution_list
run_test "README commands all exist in examples/.claude/commands" test_readme_commands_in_examples

describe "Playwright MCP example — package must exist on npm"
run_test ".mcp.json.example uses @playwright/mcp" test_mcp_example_uses_real_package
run_test "docs/playwright.md uses @playwright/mcp" test_playwright_docs_use_real_package

print_summary
