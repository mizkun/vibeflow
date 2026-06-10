"""Single source of truth for UI-task detection (VibeFlow v6).

qa_judge, dispatcher and issue_generator used to carry three diverging
keyword lists with naive substring matching — 'ui' matched inside
'build', so a CI fix could hard-fail QA for a missing Playwright run.

Rules:
- English keywords match on word boundaries.
- Japanese keywords keep substring matching (\\b does not work between
  CJK characters), which is safe because the keywords are content words.
- Priority: explicit flag > qa:ui label > changed-file extensions >
  keyword fallback on title/body.
"""

from __future__ import annotations

import re
from typing import Any, Dict

# File extensions that indicate UI changes
UI_FILE_EXTENSIONS = {
    ".tsx", ".jsx", ".vue", ".svelte", ".html",
    ".css", ".scss", ".less", ".sass",
}

# English keywords: word-boundary matched
UI_KEYWORDS_EN = [
    "ui", "page", "screen", "component", "layout", "design",
    "css", "style", "button", "form", "modal", "dialog",
    "animation", "responsive", "dashboard",
]

# Japanese keywords: substring matched
UI_KEYWORDS_JA = [
    "画面", "表示", "デザイン", "ダッシュボード", "レイアウト",
    "コンポーネント", "ボタン", "フォーム", "モーダル",
]

_EN_PATTERN = re.compile(
    r"\b(?:" + "|".join(re.escape(kw) for kw in UI_KEYWORDS_EN) + r")\b",
    re.IGNORECASE,
)


def text_mentions_ui(text: str) -> bool:
    """True if the text mentions UI work (boundary-matched EN, substring JA)."""
    if not text:
        return False
    if _EN_PATTERN.search(text):
        return True
    return any(kw in text for kw in UI_KEYWORDS_JA)


def is_ui_task(context: Dict[str, Any]) -> bool:
    """Determine if a task involves UI changes.

    Args:
        context: Dict with optional keys:
            - has_ui_changes: bool (explicit flag)
            - labels: list of str (qa:ui forces UI)
            - changed_files: list of file paths
            - issue_title / issue_body: str
    """
    if context.get("has_ui_changes"):
        return True

    if "qa:ui" in context.get("labels", []):
        return True

    for f in context.get("changed_files", []):
        for ext in UI_FILE_EXTENSIONS:
            if f.endswith(ext):
                return True

    title = context.get("issue_title", "") or ""
    body = context.get("issue_body", "") or ""
    return text_mentions_ui(f"{title} {body}")
