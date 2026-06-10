#!/usr/bin/env bash
# correction-signatures.sh — heuristics for detecting correction edits.
# Sourced by detect and session-end scripts. Exit 0 always.

# ---------------------------------------------------------------------------
# is_correction_edit SESSION_LOG CURR_FILE
#   Returns 0 (true) if CURR_FILE appears in SESSION_LOG within the last
#   CORRECTION_WINDOW_SECONDS seconds (default 30), indicating a re-edit.
# ---------------------------------------------------------------------------
is_correction_edit() {
  local log_file="$1" curr_file="$2"
  local window="${CORRECTION_WINDOW_SECONDS:-30}"

  [[ -f "$log_file" ]] || return 1
  [[ -n "$curr_file" ]] || return 1

  local now
  now=$(date +%s 2>/dev/null) || return 1

  local cutoff=$(( now - window ))

  # Read log lines, find prior edits to the same file within the window
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    local ts file
    if command -v jq &>/dev/null; then
      ts=$(printf '%s' "$line" | jq -r '.ts // empty' 2>/dev/null)
      file=$(printf '%s' "$line" | jq -r '.file // empty' 2>/dev/null)
    else
      ts=$(printf '%s' "$line" | grep -o '"ts":"[^"]*"' | sed 's/"ts":"//;s/"//')
      file=$(printf '%s' "$line" | grep -o '"file":"[^"]*"' | sed 's/"file":"//;s/"//')
    fi

    [[ -z "$ts" || -z "$file" ]] && continue
    [[ "$file" != "$curr_file" ]] && continue

    # ts may be ISO or epoch; normalise to epoch
    local ts_epoch
    if [[ "$ts" =~ ^[0-9]+$ ]]; then
      ts_epoch="$ts"
    else
      ts_epoch=$(date -d "$ts" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${ts%%.*}" +%s 2>/dev/null) || continue
    fi

    if (( ts_epoch >= cutoff )); then
      return 0  # same file edited within the window — correction
    fi
  done < "$log_file"

  return 1
}

# ---------------------------------------------------------------------------
# extract_skill_from_session_log LOG_FILE
#   Reads the most recent "skill" field from the session log.
#   Outputs the skill name or empty string.
# ---------------------------------------------------------------------------
extract_skill_from_session_log() {
  local log_file="$1"
  [[ -f "$log_file" ]] || return 0

  local skill=""
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local s
    if command -v jq &>/dev/null; then
      s=$(printf '%s' "$line" | jq -r '.skill // empty' 2>/dev/null)
    else
      s=$(printf '%s' "$line" | grep -o '"skill":"[^"]*"' | sed 's/"skill":"//;s/"//')
    fi
    [[ -n "$s" ]] && skill="$s"
  done < "$log_file"

  printf '%s' "$skill"
}
