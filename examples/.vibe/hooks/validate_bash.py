#!/usr/bin/env python3
"""
VibeFlow Bash Guard Hook
Blocks the Bash bypass routes that the Edit/Write guards cannot see:
- destructive git (force push, push to main/master, reset --hard, clean -fd, ...)
- file writes via redirection / tee / sed -i / rm / mv / cp into guarded paths
  (tests, linter configs, the guards themselves, the kill switch)

PreToolUse hook (matcher: Bash). Exit code 2 blocks the tool call.

This is a guardrail for a COOPERATIVE agent, not an adversarial sandbox:
quote/whitespace obfuscation is normalized, but eval / aliases / variable
indirection cannot be matched from the command string and are out of scope.

GENERATED FILE — Do not edit manually.
Source: core/schema/policy.yaml
Generator: core/generators/generate_hooks.py
"""

import fnmatch
import json
import os
import re
import sys

# ---------------------------
# Role-based edit permissions (mirrors validate_access.py)
# ---------------------------
ROLE_EDIT_ALLOW = {

    "Iris": [

        "vision.md",

        "plan.md",

        ".vibe/**",

    ],

    "Coding Agent (Claude Code / Codex)": [

        "src/*",

        "tests/*",

        "**/*.test.*",

        "**/__tests__/*",

        ".vibe/spec/**",

        ".vibe/project_state.yaml",

        ".vibe/sessions/*.yaml",

        ".vibe/state.yaml",

        ".vibe/test-results.log",

    ],

}

# Always writable regardless of role (state files)
ALWAYS_ALLOW = [

    ".vibe/project_state.yaml",

    ".vibe/sessions/*.yaml",

    ".vibe/state.yaml",

]

# Writable via bash regardless of role (evidence/report capture)
SAFE_WRITE_EXTRA = [".vibe/reports/*", ".vibe/reports/**"]

# The guards themselves + the kill switch — no role may write these via bash
GUARD_PATTERNS = [
    ".vibe/hooks/*", ".vibe/hooks/**",
    ".vibe/policy.yaml",
    ".vibe/generated-manifest.json",
    ".claude/settings.json", ".claude/settings.local.json",
    ".claude/settings*.json",
]

# Test files: create/modify them with Write/Edit so TestGuard can see it —
# never via a bash redirect.
TEST_PATTERNS = [
    "tests", "tests/*", "tests/**",
    "test", "test/*", "test/**",
    "**/*.test.*", "**/*.spec.*",
    "__tests__", "**/__tests__/**",
]

# Linter / formatter configs — making lint pass by weakening config is forbidden.
LINT_CONFIG_PATTERNS = [
    ".eslintrc", ".eslintrc.*", "eslint.config.*",
    ".prettierrc", ".prettierrc.*", "prettier.config.*",
    "tsconfig.json", "tsconfig.*.json",
    "pyproject.toml", "setup.cfg", ".flake8",
    "ruff.toml", ".ruff.toml", ".pylintrc", "mypy.ini",
    "biome.json", ".stylelintrc", ".stylelintrc.*",
]

# Destructive git that is ALWAYS denied (no override)
ABSOLUTE_GIT_DENY = [
    r"\bgit\s+push\b[^|&;\n]*(--force-with-lease|--force|(?<!\w)-f(?!\w))",
    r"\bgit\s+push\b[^|&;\n]*\s(main|master)(\s|$|:)",
    r"\bgit\s+branch\b[^|&;\n]*\s-D\b",
    r"\bgit\s+filter-branch\b",
    r"\bgit\s+update-ref\b",
]

# Destructive git that a human can authorize once via an approval checkpoint
APPROVAL_GIT_OPS = [
    r"\bgit\s+reset\b[^|&;\n]*--hard\b",
    r"\bgit\s+clean\b[^|&;\n]*\s-[a-zA-Z]*f",
]

APPROVAL_FILE = ".vibe/checkpoints/destructive-op-approved"


def project_root() -> str:
    return os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()


def read_current_role_from_file(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                s = line.strip()
                if s.startswith("current_role:"):
                    return s.split(":", 1)[1].strip().strip('"').strip("'")
    except FileNotFoundError:
        return ""
    return ""


def resolve_current_role(root: str) -> str:
    session_id = os.environ.get("VIBEFLOW_SESSION")
    if session_id:
        session_path = os.path.join(root, ".vibe", "sessions", f"{session_id}.yaml")
        role = read_current_role_from_file(session_path)
        if role:
            return role
    return read_current_role_from_file(os.path.join(root, ".vibe", "state.yaml"))


def _normalize_path(s: str) -> str:
    s = s.strip().strip('"').strip("'")
    if s.startswith("./"):
        s = s[2:]
    if len(s) > 1 and s.endswith("/"):
        s = s[:-1]
    return s


def match_any(path: str, patterns: list) -> bool:
    p = _normalize_path(path)
    for pat in patterns:
        if fnmatch.fnmatch(p, pat) or fnmatch.fnmatch(p, f"**/{pat}"):
            return True
    return False


def is_external_target(target: str) -> bool:
    """Writes outside the project (or to /dev/null) are not our concern."""
    t = target.strip().strip('"').strip("'")
    if t in ("/dev/null", "/dev/stdout", "/dev/stderr"):
        return True
    if t.startswith("/tmp/") or t == "/tmp":
        return True
    # absolute paths outside the project dir
    if t.startswith("/"):
        root = os.path.realpath(project_root())
        return not os.path.realpath(t).startswith(root)
    return False


def extract_write_targets(cmd: str) -> list:
    """Best-effort extraction of files a command writes to."""
    targets = []
    # redirections: > file / >> file  — exclude 2>, &>, >&, >|
    for m in re.finditer(r"(?<![0-9&>])>>?\s*([^\s|&;><]+)", cmd):
        targets.append(m.group(1))
    # tee [-a] FILE...
    for m in re.finditer(r"\btee\b\s+((?:-\S+\s+)*)([^\s|&;<>]+)", cmd):
        targets.append(m.group(2))
    # sed -i ... <files>  (last token of the segment)
    for m in re.finditer(r"\bsed\b([^|&;\n]*?)\s-i\b([^|&;\n]*)", cmd):
        toks = [t for t in m.group(2).split() if not t.startswith("-")]
        if toks:
            targets.append(toks[-1])
    # rm / mv / cp <targets>
    for m in re.finditer(r"\b(?:rm|mv|cp)\b\s+([^|&;\n]+)", cmd):
        for tok in m.group(1).split():
            if not tok.startswith("-"):
                targets.append(tok)
    return [t for t in targets if t]


def block(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(2)


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    if payload.get("tool_name", "") != "Bash":
        sys.exit(0)

    command = (payload.get("tool_input", {}) or {}).get("command", "")
    if not command:
        sys.exit(0)

    # Normalize quotes/escapes so obfuscated spellings still match.
    norm = re.sub(r"['\"\\]", "", command)
    root = project_root()
    role = resolve_current_role(root) or "Iris"
    allow = ROLE_EDIT_ALLOW.get(role, [])

    # 1) Absolute-deny destructive git
    for pat in ABSOLUTE_GIT_DENY:
        if re.search(pat, norm):
            block(
                "[VibeFlow BashGuard — 破壊的 git 操作]\n"
                f"このコマンドは禁止された git 操作を含みます:\n  {command}\n\n"
                "force push / main・master への直接 push / branch -D /\n"
                "filter-branch / update-ref は実行できません。\n"
                "feature ブランチで作業し、PR 経由でマージしてください。"
            )

    # 2) Approval-gated destructive git (reset --hard, clean -fd)
    needs_approval = any(re.search(pat, norm) for pat in APPROVAL_GIT_OPS)
    if needs_approval:
        approval_path = os.path.join(root, APPROVAL_FILE)
        if os.path.isfile(approval_path):
            try:
                os.remove(approval_path)  # one-shot consume
            except OSError:
                pass
        else:
            block(
                "[VibeFlow BashGuard — 破壊的操作の確認が必要]\n"
                f"このコマンドは破壊的です:\n  {command}\n\n"
                "実行するには PO の承認が必要です。承認後、\n"
                f"  {APPROVAL_FILE}\n"
                "を作成（内容 'approved'）してから再実行してください"
                "（承認は 1 回で消費されます）。"
            )

    # 3) Write-bypass to guarded paths
    for target in extract_write_targets(norm):
        if is_external_target(target):
            continue
        if match_any(target, ALWAYS_ALLOW) or match_any(target, SAFE_WRITE_EXTRA):
            continue
        if match_any(target, GUARD_PATTERNS):
            block(
                "[VibeFlow BashGuard — ガード改竄の禁止]\n"
                f"bash 経由で保護対象 '{target}' に書き込むことはできません。\n\n"
                "hook / policy / manifest / settings は VibeFlow framework の\n"
                "schema を修正して `vibeflow generate` で更新してください。"
            )
        if match_any(target, TEST_PATTERNS):
            block(
                "[VibeFlow BashGuard — テスト改竄の禁止]\n"
                f"bash 経由でテスト '{target}' を書き換え/削除できません。\n\n"
                "テストの作成・編集は Write/Edit で行ってください\n"
                "（TestGuard が変更を検査できるようにするため）。"
            )
        if match_any(target, LINT_CONFIG_PATTERNS):
            block(
                "[VibeFlow BashGuard — LintGuard]\n"
                f"bash 経由で linter 設定 '{target}' を編集できません。\n"
                "設定を緩めるのではなくコードを修正してください。"
            )
        if not match_any(target, allow):
            block(
                "[VibeFlow BashGuard]\n"
                f"current_role='{role}' では bash 経由で '{target}' に\n"
                "書き込めません。正しいロールに遷移し、Write/Edit を使ってください。"
            )

    sys.exit(0)


if __name__ == "__main__":
    main()
