#!/usr/bin/env bash
# skill-improve-apply.sh — output dismissed lessons as agent context on demand.
# Can be called mid-session or at any time. Always exits 0.

set -euo pipefail 2>/dev/null || true

PACK_ROOT="${DI_PACK_ROOT:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"
LESSONS_FILE="${PACK_ROOT}/hooks/state/dismissed-lessons.json"
PREFIX="[DI Hindsight]"

[[ -f "$LESSONS_FILE" ]] || exit 0

# ---------------------------------------------------------------------------
# Output lessons as a numbered context block
# ---------------------------------------------------------------------------
if command -v jq &>/dev/null; then
  COUNT=$(jq '.dismissed | length' "$LESSONS_FILE" 2>/dev/null) || COUNT=0
  if (( COUNT == 0 )); then
    echo "${PREFIX} No correction patterns recorded yet."
    exit 0
  fi

  echo ""
  echo "${PREFIX} Active correction patterns (${COUNT}):"
  jq -r '.dismissed[] | "  [\(.id)] \(.lesson)  [seen \(.frequency)x, last \(.last_seen)]"' \
    "$LESSONS_FILE" 2>/dev/null | awk '{print NR". "$0}' || true
  echo ""
else
  # Fallback
  if ! grep -q '"lesson"' "$LESSONS_FILE" 2>/dev/null; then
    echo "${PREFIX} No correction patterns recorded yet."
    exit 0
  fi

  echo ""
  echo "${PREFIX} Active correction patterns:"
  grep -o '"lesson":"[^"]*"' "$LESSONS_FILE" 2>/dev/null \
    | sed 's/"lesson":"//;s/"//' \
    | awk '{print NR". "$0}' || true
  echo ""
fi

exit 0
