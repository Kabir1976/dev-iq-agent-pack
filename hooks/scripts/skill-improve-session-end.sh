#!/usr/bin/env bash
# skill-improve-session-end.sh — fires at Stop; consolidates session log.
# Promotes repeated correction patterns and updates edit-frequency.json.
# Always exits 0.

set -euo pipefail 2>/dev/null || true

PACK_ROOT="${DI_PACK_ROOT:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"

# Respect hindsight_enabled flag in .dev-iq/config.yaml (default: enabled)
_ENABLED=$(grep -m1 "hindsight_enabled:" "${PACK_ROOT}/.dev-iq/config.yaml" 2>/dev/null \
  | sed 's/.*:[[:space:]]*//' | tr -d '"' | xargs)
[[ "$_ENABLED" == "false" ]] && exit 0

SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
SESSION_LOG="${PACK_ROOT}/hooks/state/session-${SESSION_ID}.jsonl"
LESSONS_FILE="${PACK_ROOT}/hooks/state/dismissed-lessons.json"
FREQ_FILE="${PACK_ROOT}/hooks/state/edit-frequency.json"
CONFIG_FILE="${PACK_ROOT}/hooks/config/skill-improve.config.json"

# Source utilities
# shellcheck source=lib/json-utils.sh
source "${PACK_ROOT}/hooks/scripts/lib/json-utils.sh" 2>/dev/null || true
# shellcheck source=lib/correction-signatures.sh
source "${PACK_ROOT}/hooks/scripts/lib/correction-signatures.sh" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Read config
# ---------------------------------------------------------------------------
MIN_CORRECTIONS=2
if command -v jq &>/dev/null && [[ -f "$CONFIG_FILE" ]]; then
  MIN_CORRECTIONS=$(jq -r '.min_corrections_to_promote // 2' "$CONFIG_FILE" 2>/dev/null) || MIN_CORRECTIONS=2
fi
MAX_LESSONS=20
if command -v jq &>/dev/null && [[ -f "$CONFIG_FILE" ]]; then
  MAX_LESSONS=$(jq -r '.max_lessons // 20' "$CONFIG_FILE" 2>/dev/null) || MAX_LESSONS=20
fi

# ---------------------------------------------------------------------------
# 1. Bail early if no session log
# ---------------------------------------------------------------------------
[[ -f "$SESSION_LOG" ]] || {
  bash "${PACK_ROOT}/hooks/scripts/track-telemetry.sh" "session.end" 2>/dev/null || true
  exit 0
}

# ---------------------------------------------------------------------------
# 2. Count corrections per file in this session
# ---------------------------------------------------------------------------
TODAY=$(date +"%Y-%m-%d" 2>/dev/null || date +%Y-%m-%d)

if command -v jq &>/dev/null; then
  # Build a map of file -> correction count using jq
  CORR_SUMMARY=$(jq -rs '[.[] | select(.is_correction==true)] | group_by(.file) | map({file: .[0].file, count: length})' \
    "$SESSION_LOG" 2>/dev/null) || CORR_SUMMARY="[]"

  CORR_COUNT=$(printf '%s' "$CORR_SUMMARY" | jq 'length' 2>/dev/null) || CORR_COUNT=0

  # ---------------------------------------------------------------------------
  # 3. Promote files with >= MIN_CORRECTIONS to dismissed-lessons.json
  # ---------------------------------------------------------------------------
  if (( CORR_COUNT > 0 )) && [[ -f "$LESSONS_FILE" ]]; then
    printf '%s' "$CORR_SUMMARY" | jq -c ".[] | select(.count >= ${MIN_CORRECTIONS})" 2>/dev/null | \
    while IFS= read -r entry; do
      FILE=$(printf '%s' "$entry" | jq -r '.file' 2>/dev/null)
      COUNT=$(printf '%s' "$entry" | jq -r '.count' 2>/dev/null)

      # Check if a lesson already exists for this file
      EXISTING_ID=$(jq -r --arg f "$FILE" \
        '.dismissed[] | select(.pattern | contains($f)) | .id' \
        "$LESSONS_FILE" 2>/dev/null | head -1)

      if [[ -n "$EXISTING_ID" ]]; then
        # Update frequency and last_seen
        TMP="${LESSONS_FILE}.tmp.$$"
        jq --arg id "$EXISTING_ID" --arg ts "$TODAY" --argjson c "$COUNT" \
          '(.dismissed[] | select(.id==$id)) |= (.frequency += $c | .last_seen = $ts)' \
          "$LESSONS_FILE" 2>/dev/null > "$TMP" \
          && mv "$TMP" "$LESSONS_FILE" 2>/dev/null || rm -f "$TMP"
      else
        # Check lesson cap
        CURRENT=$(jq '.dismissed | length' "$LESSONS_FILE" 2>/dev/null) || CURRENT=0
        if (( CURRENT < MAX_LESSONS )); then
          SAFE_FILE=$(printf '%s' "$FILE" | sed 's/\\/\\\\/g;s/"/\\"/g')
          LESSON_ID="lesson-$(date +%s)-${RANDOM}"
          NEW_LESSON="{\"id\":\"${LESSON_ID}\",\"pattern\":\"repeated edit to ${SAFE_FILE}\",\"lesson\":\"Review ${SAFE_FILE} carefully — it was re-edited ${COUNT} time(s) this session.\",\"frequency\":${COUNT},\"last_seen\":\"${TODAY}\"}"
          json_append_array "$LESSONS_FILE" "$NEW_LESSON" 2>/dev/null || true
        fi
      fi
    done
  fi

  # ---------------------------------------------------------------------------
  # 4. Update edit-frequency.json for the skill seen this session
  # ---------------------------------------------------------------------------
  SKILL=$(extract_skill_from_session_log "$SESSION_LOG" 2>/dev/null) || SKILL=""
  if [[ -n "$SKILL" && -f "$FREQ_FILE" ]]; then
    CURRENT_INV=$(jq -r --arg s "$SKILL" '.edits[$s].invocations // 0' "$FREQ_FILE" 2>/dev/null) || CURRENT_INV=0
    CURRENT_CORR=$(jq -r --arg s "$SKILL" '.edits[$s].corrections // 0' "$FREQ_FILE" 2>/dev/null) || CURRENT_CORR=0
    NEW_INV=$(( CURRENT_INV + 1 ))
    NEW_CORR=$(( CURRENT_CORR + CORR_COUNT ))
    TMP="${FREQ_FILE}.tmp.$$"
    jq --arg s "$SKILL" --argjson inv "$NEW_INV" --argjson corr "$NEW_CORR" \
      '.edits[$s] = {invocations: $inv, corrections: $corr}' \
      "$FREQ_FILE" 2>/dev/null > "$TMP" \
      && mv "$TMP" "$FREQ_FILE" 2>/dev/null || rm -f "$TMP"
  fi
fi

# ---------------------------------------------------------------------------
# 5. Remove session temp file
# ---------------------------------------------------------------------------
rm -f "$SESSION_LOG" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 6. Prune stale session logs (older than retention period)
# ---------------------------------------------------------------------------
RETENTION_DAYS=7
if command -v jq &>/dev/null && [[ -f "$CONFIG_FILE" ]]; then
  RETENTION_DAYS=$(jq -r '.session_log_retention_days // 7' "$CONFIG_FILE" 2>/dev/null) || RETENTION_DAYS=7
fi
find "${PACK_ROOT}/hooks/state" -name "session-*.jsonl" -mtime "+${RETENTION_DAYS}" -delete 2>/dev/null || true

# ---------------------------------------------------------------------------
# 7. Emit telemetry
# ---------------------------------------------------------------------------
bash "${PACK_ROOT}/hooks/scripts/track-telemetry.sh" "session.end" 2>/dev/null || true

exit 0
