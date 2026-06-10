#!/usr/bin/env bash
# skill-improve-reflect.sh — analyse a session log and summarise corrections.
# Usage: skill-improve-reflect.sh SESSION_LOG_FILE
# Outputs a human-readable summary to stdout. Always exits 0.
# Compatible with bash 3 (macOS default) — no associative arrays.

set -euo pipefail 2>/dev/null || true

LOG_FILE="${1:-}"
[[ -z "$LOG_FILE" || ! -f "$LOG_FILE" ]] && exit 0

# ---------------------------------------------------------------------------
# If jq is available, use it for accurate counting
# ---------------------------------------------------------------------------
if command -v jq &>/dev/null; then
  TOTAL_EDITS=$(jq -rs '[.[] | select(.file != null)] | length' "$LOG_FILE" 2>/dev/null) || TOTAL_EDITS=0
  TOTAL_CORRECTIONS=$(jq -rs '[.[] | select(.is_correction==true)] | length' "$LOG_FILE" 2>/dev/null) || TOTAL_CORRECTIONS=0
  UNIQUE_FILES=$(jq -rs '[.[] | select(.file != null) | .file] | unique | length' "$LOG_FILE" 2>/dev/null) || UNIQUE_FILES=0

  echo "[DI Hindsight] Session reflection:"
  echo "  Files edited : ${UNIQUE_FILES}"
  echo "  Corrections  : ${TOTAL_CORRECTIONS}"

  if (( TOTAL_CORRECTIONS > 0 )); then
    echo "  Files with corrections:"
    jq -rs '[.[] | select(.is_correction==true)] | group_by(.file) | .[] | "    - \(.[0].file) (\(length) correction(s))"' \
      "$LOG_FILE" 2>/dev/null || true
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# Fallback: pure grep/awk counting (no associative arrays)
# ---------------------------------------------------------------------------
TOTAL_EDITS=$(grep -c '"event":"tool.use"' "$LOG_FILE" 2>/dev/null) || TOTAL_EDITS=0
TOTAL_CORRECTIONS=$(grep -c '"is_correction":true' "$LOG_FILE" 2>/dev/null) || TOTAL_CORRECTIONS=0
UNIQUE_FILES=$(grep -o '"file":"[^"]*"' "$LOG_FILE" 2>/dev/null | sort -u | wc -l | tr -d ' ') || UNIQUE_FILES=0

echo "[DI Hindsight] Session reflection:"
echo "  Files edited : ${UNIQUE_FILES}"
echo "  Corrections  : ${TOTAL_CORRECTIONS}"

if (( TOTAL_CORRECTIONS > 0 )); then
  echo "  Files with corrections:"
  grep '"is_correction":true' "$LOG_FILE" 2>/dev/null \
    | grep -o '"file":"[^"]*"' \
    | sed 's/"file":"//;s/"//' \
    | sort | uniq -c \
    | awk '{print "    - "$2" ("$1" correction(s))"}' || true
fi

exit 0
