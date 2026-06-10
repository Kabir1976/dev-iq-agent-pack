#!/usr/bin/env bash
# skill-improve-detect.sh — PostToolUse hook; detects correction edits.
# Reads JSON from stdin (Claude Code hook format). Always exits 0.

set -euo pipefail 2>/dev/null || true

PACK_ROOT="${DI_PACK_ROOT:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"

# Respect hindsight_enabled flag in .dev-iq/config.yaml (default: enabled)
_ENABLED=$(grep -m1 "hindsight_enabled:" "${PACK_ROOT}/.dev-iq/config.yaml" 2>/dev/null \
  | sed 's/.*:[[:space:]]*//' | tr -d '"' | xargs)
[[ "$_ENABLED" == "false" ]] && exit 0

SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
SESSION_LOG="${PACK_ROOT}/hooks/state/session-${SESSION_ID}.jsonl"

# Source utilities
# shellcheck source=lib/json-utils.sh
source "${PACK_ROOT}/hooks/scripts/lib/json-utils.sh" 2>/dev/null || true
# shellcheck source=lib/correction-signatures.sh
source "${PACK_ROOT}/hooks/scripts/lib/correction-signatures.sh" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 1. Parse stdin
# ---------------------------------------------------------------------------
STDIN=$(cat 2>/dev/null) || STDIN=""
[[ -z "$STDIN" ]] && exit 0

if command -v jq &>/dev/null; then
  TOOL_NAME=$(printf '%s' "$STDIN" | jq -r '.tool_name // empty' 2>/dev/null)
  FILE_PATH=$(printf '%s' "$STDIN" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  TOOL_NAME=$(printf '%s' "$STDIN" | grep -o '"tool_name":"[^"]*"' | sed 's/"tool_name":"//;s/"//')
  FILE_PATH=$(printf '%s' "$STDIN" | grep -o '"file_path":"[^"]*"' | sed 's/"file_path":"//;s/"//')
fi

# ---------------------------------------------------------------------------
# 2. Only act on Edit / Write / MultiEdit
# ---------------------------------------------------------------------------
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

[[ -z "$FILE_PATH" ]] && exit 0

# ---------------------------------------------------------------------------
# 3. Check if this looks like a correction (same file written twice within window)
# ---------------------------------------------------------------------------
IS_CORRECTION="false"
if is_correction_edit "$SESSION_LOG" "$FILE_PATH" 2>/dev/null; then
  IS_CORRECTION="true"
fi

# ---------------------------------------------------------------------------
# 4. Append event to session JSONL log
# ---------------------------------------------------------------------------
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +%s)
# Escape file path for JSON (replace backslash then double-quote)
SAFE_FILE=$(printf '%s' "$FILE_PATH" | sed 's/\\/\\\\/g;s/"/\\"/g')

jsonl_append "$SESSION_LOG" \
  "{\"ts\":\"${TS}\",\"event\":\"tool.use\",\"tool\":\"${TOOL_NAME}\",\"file\":\"${SAFE_FILE}\",\"is_correction\":${IS_CORRECTION}}" \
  2>/dev/null || true

# ---------------------------------------------------------------------------
# 5. Emit telemetry
# ---------------------------------------------------------------------------
EVENT="tool.detect"
[[ "$IS_CORRECTION" == "true" ]] && EVENT="tool.correct"

EXTRA=",\"tool\":\"${TOOL_NAME}\",\"file\":\"${SAFE_FILE}\",\"is_correction\":${IS_CORRECTION}"
bash "${PACK_ROOT}/hooks/scripts/track-telemetry.sh" "$EVENT" "$EXTRA" 2>/dev/null || true

exit 0
