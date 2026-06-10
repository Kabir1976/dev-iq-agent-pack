#!/usr/bin/env bash
# json-utils.sh — portable JSON helpers for Hindsight Hooks
# No mandatory external dependencies; uses jq when available.
# All functions exit 0 on error to avoid interrupting the developer's workflow.

# ---------------------------------------------------------------------------
# json_read_field FILE KEY
#   Read a top-level scalar field from a flat JSON object.
#   Tries jq first, falls back to grep/sed.
# ---------------------------------------------------------------------------
json_read_field() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0

  if command -v jq &>/dev/null; then
    jq -r --arg k "$key" '.[$k] // empty' "$file" 2>/dev/null
    return 0
  fi

  # Fallback: grep the key and strip surrounding quotes/whitespace
  grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null \
    | sed 's/.*:[[:space:]]*"\(.*\)"/\1/' \
    | head -1
}

# ---------------------------------------------------------------------------
# json_append_array FILE OBJECT
#   Append OBJECT (a raw JSON string) to the "dismissed" array inside FILE.
#   Creates the file with an empty array if missing.
# ---------------------------------------------------------------------------
json_append_array() {
  local file="$1" object="$2"
  local tmp="${file}.tmp.$$"

  # Bootstrap empty structure if needed
  if [[ ! -f "$file" ]]; then
    printf '{"dismissed":[]}\n' > "$file" 2>/dev/null || return 0
  fi

  if command -v jq &>/dev/null; then
    jq --argjson obj "$object" '.dismissed += [$obj]' "$file" 2>/dev/null > "$tmp" \
      && mv "$tmp" "$file" 2>/dev/null || rm -f "$tmp"
    return 0
  fi

  # Fallback: naive sed injection before the closing bracket of the array
  # Only safe for well-formed single-line or simple multi-line arrays.
  local content
  content=$(cat "$file" 2>/dev/null) || return 0
  # Insert before the last ] that closes the dismissed array
  local updated
  updated=$(printf '%s' "$content" | sed 's/\(\][ \t\n]*}\)/,'"$(printf '%s' "$object" | sed 's/[&/\]/\\&/g')"'\1/')
  # If array was empty, the above adds a leading comma — fix it
  updated=$(printf '%s' "$updated" | sed 's/\[,/[/')
  printf '%s\n' "$updated" > "$tmp" 2>/dev/null \
    && mv "$tmp" "$file" 2>/dev/null || rm -f "$tmp"
}

# ---------------------------------------------------------------------------
# json_set_nested FILE KEY1 KEY2 VALUE
#   Sets file[key1][key2] = value (numeric).
#   Used for edit-frequency.json: json_set_nested file "edits" "skill-name" 5
# ---------------------------------------------------------------------------
json_set_nested() {
  local file="$1" key1="$2" key2="$3" value="$4"
  local tmp="${file}.tmp.$$"

  if [[ ! -f "$file" ]]; then
    printf '{"edits":{}}\n' > "$file" 2>/dev/null || return 0
  fi

  if command -v jq &>/dev/null; then
    jq --arg k1 "$key1" --arg k2 "$key2" --argjson v "$value" \
      '.[$k1][$k2] = $v' "$file" 2>/dev/null > "$tmp" \
      && mv "$tmp" "$file" 2>/dev/null || rm -f "$tmp"
    return 0
  fi

  # Fallback not implemented for nested — silently skip
  return 0
}

# ---------------------------------------------------------------------------
# jsonl_append FILE LINE
#   Append a single JSON line to a .jsonl file, creating it if needed.
# ---------------------------------------------------------------------------
jsonl_append() {
  local file="$1" line="$2"
  mkdir -p "$(dirname "$file")" 2>/dev/null || true
  printf '%s\n' "$line" >> "$file" 2>/dev/null || true
}
