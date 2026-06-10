#!/usr/bin/env bash
# skill-improve-session-start.sh — fires at session start.
# Loads past correction lessons and outputs them as context for the agent.
# Always exits 0.

set -euo pipefail 2>/dev/null || true

PACK_ROOT="${DI_PACK_ROOT:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
LESSONS_FILE="${PACK_ROOT}/hooks/state/dismissed-lessons.json"
SESSION_LOG="${PACK_ROOT}/hooks/state/session-${SESSION_ID}.jsonl"

# Source utilities
# shellcheck source=lib/json-utils.sh
source "${PACK_ROOT}/hooks/scripts/lib/json-utils.sh" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 1. Output dismissed lessons as numbered context lines
# ---------------------------------------------------------------------------
if [[ -f "$LESSONS_FILE" ]]; then
  if command -v jq &>/dev/null; then
    COUNT=$(jq '.dismissed | length' "$LESSONS_FILE" 2>/dev/null) || COUNT=0
    if (( COUNT > 0 )); then
      echo ""
      echo "[DI Hindsight] Correction patterns from previous sessions:"
      jq -r '.dismissed[] | "  \(.id): \(.lesson)"' "$LESSONS_FILE" 2>/dev/null | \
        awk '{print NR". "$0}' || true
      echo ""
    fi
  else
    # Fallback: naive grep for "lesson" fields
    if grep -q '"lesson"' "$LESSONS_FILE" 2>/dev/null; then
      echo ""
      echo "[DI Hindsight] Correction patterns from previous sessions:"
      grep -o '"lesson":"[^"]*"' "$LESSONS_FILE" 2>/dev/null \
        | sed 's/"lesson":"//;s/"//' \
        | awk '{print NR". "$0}' || true
      echo ""
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 2. Record session start in session log
# ---------------------------------------------------------------------------
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%s")
jsonl_append "$SESSION_LOG" \
  "{\"ts\":\"${TS}\",\"event\":\"session.start\",\"session_id\":\"${SESSION_ID}\"}" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 3. Emit telemetry
# ---------------------------------------------------------------------------
bash "${PACK_ROOT}/hooks/scripts/track-telemetry.sh" "session.start" 2>/dev/null || true

exit 0
