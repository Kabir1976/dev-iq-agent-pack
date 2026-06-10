#!/usr/bin/env bash
# track-telemetry.sh — write DI Hindsight events to local log or webhook.
# Usage: track-telemetry.sh EVENT_TYPE [EXTRA_JSON_FIELDS]
# Always exits 0.

set -euo pipefail 2>/dev/null || true

PACK_ROOT="${DI_PACK_ROOT:-$(cd "$(dirname "$0")/../../.." 2>/dev/null && pwd)}"
CONFIG_FILE="${PACK_ROOT}/.dev-iq/config.yaml"
LOG_FILE="${PACK_ROOT}/hooks/logs/skill-improve.log"
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"

EVENT_TYPE="${1:-unknown}"
EXTRA="${2:-}"

# ---------------------------------------------------------------------------
# Read config values using grep/sed (no yq dependency)
# ---------------------------------------------------------------------------
read_config() {
  local key="$1"
  grep -m1 "^[[:space:]]*${key}:" "$CONFIG_FILE" 2>/dev/null \
    | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" | xargs
}

SINK=$(read_config "telemetry_sink")
SINK="${SINK:-local}"

WEBHOOK_URL=$(read_config "telemetry_webhook_url")

# Exit silently if sink is none
[[ "$SINK" == "none" ]] && exit 0

# ---------------------------------------------------------------------------
# Build the event JSON payload
# ---------------------------------------------------------------------------
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

PAYLOAD="{\"event\":\"${EVENT_TYPE}\",\"session_id\":\"${SESSION_ID}\",\"ts\":\"${TS}\""
if [[ -n "$EXTRA" ]]; then
  # EXTRA should be a comma-prefixed JSON fragment, e.g. ,"file":"foo.ts"
  PAYLOAD="${PAYLOAD}${EXTRA}"
fi
PAYLOAD="${PAYLOAD}}"

# ---------------------------------------------------------------------------
# Local sink: append to log file
# ---------------------------------------------------------------------------
if [[ "$SINK" == "local" || "$SINK" != "webhook" ]]; then
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
  printf '%s\n' "$PAYLOAD" >> "$LOG_FILE" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Webhook sink: POST (fire-and-forget, 3s timeout)
# ---------------------------------------------------------------------------
if [[ "$SINK" == "webhook" && -n "$WEBHOOK_URL" ]]; then
  curl -s --max-time 3 -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" &>/dev/null || true
fi

exit 0
