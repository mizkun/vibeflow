#!/bin/bash
# VibeFlow Migration Helpers
# Common functions for migration scripts. Source this in migration scripts.

# --- Color output ---

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- File operations (idempotent) ---

# Copy file if destination doesn't exist (won't overwrite)
copy_if_absent() {
  local src="$1"
  local dst="$2"
  if [ ! -f "$dst" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    log_ok "  作成: $dst"
  else
    log_warn "  スキップ（既存）: $dst"
  fi
}

# Create directory if it doesn't exist
ensure_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    log_ok "  作成: $dir/"
  fi
}

# --- CLAUDE.md operations ---

# Append section to file if marker not present
append_section_if_absent() {
  local file="$1"
  local marker="$2"
  local content="$3"

  if ! grep -qF "$marker" "$file" 2>/dev/null; then
    echo "" >> "$file"
    echo "$content" >> "$file"
    log_ok "  追記: $marker → $(basename "$file")"
  else
    log_warn "  スキップ（既存セクション）: $marker"
  fi
}

# Replace section between start_marker and end_marker with new_content
replace_section() {
  local file="$1"
  local start_marker="$2"
  local end_marker="$3"
  local new_content="$4"

  if grep -qF "$start_marker" "$file" 2>/dev/null; then
    python3 -c "
import sys
content = open('$file', 'r').read()
start = content.find('''$start_marker''')
end = content.find('''$end_marker''', start + len('''$start_marker'''))
if start >= 0 and end >= 0:
    new = content[:start] + sys.stdin.read() + '\n' + content[end:]
    open('$file', 'w').write(new)
elif start >= 0:
    new = content[:start] + sys.stdin.read()
    open('$file', 'w').write(new)
" <<< "$new_content"
    log_ok "  置換: $start_marker → $(basename "$file")"
  else
    echo "" >> "$file"
    echo "$new_content" >> "$file"
    log_ok "  追記（新規）: $start_marker → $(basename "$file")"
  fi
}

# --- state.yaml operations ---

# Add YAML field if not present (requires yq)
add_yaml_field_if_absent() {
  local file="$1"
  local key="$2"
  local value="$3"

  if command -v yq &>/dev/null; then
    if ! yq -e "$key" "$file" &>/dev/null; then
      yq -i "$key = $value" "$file"
      log_ok "  追加: $key → $(basename "$file")"
    else
      log_warn "  スキップ（既存キー）: $key"
    fi
  else
    # Fallback: simple grep check and append
    local simple_key
    simple_key=$(echo "$key" | sed 's/^\.//' | sed 's/\..*$//')
    if ! grep -q "^${simple_key}:" "$file" 2>/dev/null; then
      echo "" >> "$file"
      echo "# Added by migration" >> "$file"
      echo "${simple_key}: ${value}" >> "$file"
      log_ok "  追加（フォールバック）: $key → $(basename "$file")"
    else
      log_warn "  スキップ（既存キー）: $key"
    fi
  fi
}

# --- Hook operations ---

# Insert hook rule if marker not present
insert_hook_rule_if_absent() {
  local file="$1"
  local marker="$2"
  local rule="$3"
  local position="${4:-top}"  # "top" or "bottom"

  if [ ! -f "$file" ]; then
    log_warn "  スキップ（ファイル不在）: $file"
    return
  fi

  if ! grep -qF "$marker" "$file" 2>/dev/null; then
    if [ "$position" = "top" ]; then
      local tmp=$(mktemp)
      head -1 "$file" > "$tmp"
      echo "" >> "$tmp"
      echo "$rule" >> "$tmp"
      tail -n +2 "$file" >> "$tmp"
      mv "$tmp" "$file"
      chmod +x "$file"
    else
      echo "" >> "$file"
      echo "$rule" >> "$file"
    fi
    log_ok "  挿入: $marker → $(basename "$file")"
  else
    log_warn "  スキップ（既存ルール）: $marker"
  fi
}
