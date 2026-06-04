#!/usr/bin/env bash
# Dev.IQ Agent Pack — Bootstrap Installer
# Version : 0.9.0
# Usage   : bash scripts/bootstrap.sh [--target=<path>] [--mode=trial|committed] [--graduate] [--hooks]
set -euo pipefail

PACK_VERSION="0.9.0"
PACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKER_START="<!-- dev-iq:start -->"
MARKER_END="<!-- dev-iq:end -->"

# ── Terminal colours (only when writing to a real TTY) ────────────
if [[ -t 1 ]]; then
  C_GRN='\033[0;32m'; C_YLW='\033[1;33m'; C_RED='\033[0;31m'
  C_BLD='\033[1m';    C_RST='\033[0m'
else
  C_GRN=''; C_YLW=''; C_RED=''; C_BLD=''; C_RST=''
fi

log()  { echo -e "${C_BLD}[dev-iq]${C_RST} $*"; }
ok()   { echo -e "${C_GRN}[dev-iq] ✓${C_RST} $*"; }
warn() { echo -e "${C_YLW}[dev-iq] ⚠${C_RST} $*"; }
die()  { echo -e "${C_RED}[dev-iq] ✗${C_RST} $*" >&2; exit 1; }

# ── Parse arguments ───────────────────────────────────────────────
TARGET="$(pwd)"
MODE=""
GRADUATE=false
INCLUDE_HOOKS=false

for arg in "$@"; do
  case "$arg" in
    --target=*)  TARGET="${arg#*=}" ;;
    --mode=*)    MODE="${arg#*=}" ;;
    --graduate)  GRADUATE=true ;;
    --hooks)     INCLUDE_HOOKS=true ;;
    --help|-h)
      cat << EOF
Dev.IQ Agent Pack — Bootstrap Installer v${PACK_VERSION}

Usage:
  bash scripts/bootstrap.sh [options]

Options:
  --target=<path>       Target repository root (default: current directory)
  --mode=trial          Install without touching git history (uses .git/info/exclude)
  --mode=committed      Install files visibly so the team can commit them
  --graduate            Convert a trial install to committed mode
  --hooks               Also install the hooks/ directory
  --help                Show this help message

Examples:
  # Fresh install, interactive mode selection:
  bash /path/to/dev-iq/scripts/bootstrap.sh

  # Install into another repo, trial mode:
  bash /path/to/dev-iq/scripts/bootstrap.sh --target=/path/to/repo --mode=trial

  # Update an existing install:
  bash /path/to/dev-iq/scripts/bootstrap.sh --target=/path/to/repo --mode=committed

  # Graduate a trial install to committed:
  bash /path/to/dev-iq/scripts/bootstrap.sh --target=/path/to/repo --graduate
EOF
      exit 0
      ;;
    *) die "Unknown argument: '$arg'. Run with --help for usage." ;;
  esac
done

# ── Validate prerequisites ────────────────────────────────────────
command -v python3 >/dev/null 2>&1 || die "python3 is required but not found."
command -v git     >/dev/null 2>&1 || die "git is required but not found."

[[ -d "$TARGET" ]]      || die "Target directory not found: $TARGET"
[[ -d "$TARGET/.git" ]] || die "Target is not a git repository: $TARGET"
TARGET="$(cd "$TARGET" && pwd)"  # normalise to absolute path

# ── Detect existing install ───────────────────────────────────────
MANIFEST="$TARGET/.dev-iq/.install-manifest.json"
IS_UPGRADE=false

if [[ -f "$MANIFEST" ]]; then
  IS_UPGRADE=true
  PREV_VERSION=$(python3 -c "import json; d=json.load(open('$MANIFEST')); print(d.get('version','unknown'))" 2>/dev/null || echo "unknown")
  PREV_MODE=$(python3 -c "import json; d=json.load(open('$MANIFEST')); print(d.get('mode','trial'))" 2>/dev/null || echo "trial")
  echo ""
  log "Existing Dev.IQ install detected."
  log "  Installed version : v${PREV_VERSION}"
  log "  New pack version  : v${PACK_VERSION}"
  log "  Current mode      : ${PREV_MODE}"
  echo ""
fi

# ── Graduate mode ─────────────────────────────────────────────────
if [[ "$GRADUATE" == true ]]; then
  [[ "$IS_UPGRADE" == true ]] || die "No existing install found. Run bootstrap first, then --graduate."

  EXCLUDE="$TARGET/.git/info/exclude"
  if [[ -f "$EXCLUDE" ]] && grep -qF "# dev-iq" "$EXCLUDE" 2>/dev/null; then
    # Strip dev-iq block from exclude file
    grep -v "^# dev-iq" "$EXCLUDE" \
      | grep -v "^\.github/skills" \
      | grep -v "^\.github/instructions" \
      | grep -v "^\.github/agents" \
      | grep -v "^\.claude/agents" \
      | grep -v "^\.claude/skills" \
      | grep -v "^\.dev-iq" \
      | grep -v "^hooks/" \
      | grep -v "^CLAUDE\.md" \
      > "$EXCLUDE.tmp" && mv "$EXCLUDE.tmp" "$EXCLUDE"
    ok "Removed trial entries from .git/info/exclude."
  fi

  python3 - "$MANIFEST" << 'PYEOF'
import json, datetime, sys
path = sys.argv[1]
with open(path) as f:
    d = json.load(f)
d["mode"] = "committed"
d["graduated_at"] = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
with open(path, "w") as f:
    json.dump(d, f, indent=2)
PYEOF

  ok "Graduated to committed mode."
  echo ""
  log "Dev.IQ files are now visible to git."
  log "Next: review the files, then git add and open a team PR."
  exit 0
fi

# ── Select install mode ───────────────────────────────────────────
if [[ -z "$MODE" ]]; then
  if [[ -t 0 ]]; then
    echo ""
    log "Select install mode:"
    echo ""
    echo -e "  ${C_BLD}[1] trial${C_RST}     — local only, completely invisible to git"
    echo -e "            Files go in .git/info/exclude — the codebase is not modified."
    echo -e "            Graduate to committed later when the team is ready."
    echo ""
    echo -e "  ${C_BLD}[2] committed${C_RST} — files visible to git"
    echo -e "            Team can review, commit, and share the pack as a normal PR."
    echo ""
    read -rp "  Choice [1/2] (default: 1): " _choice
    [[ "${_choice:-1}" == "2" ]] && MODE="committed" || MODE="trial"
  else
    MODE="trial"
  fi
fi

[[ "$MODE" == "trial" || "$MODE" == "committed" ]] \
  || die "Invalid mode: '$MODE'. Use 'trial' or 'committed'."

echo ""
log "─────────────────────────────────────────────"
log "  Dev.IQ Agent Pack v${PACK_VERSION}"
log "  Target : $TARGET"
log "  Mode   : $MODE"
log "─────────────────────────────────────────────"
echo ""

# ── File copy helpers ─────────────────────────────────────────────

# Copy a single file to dst.
# If preserve=true and dst already exists, skip it (user has configured it).
_copy_file() {
  local src="$1" dst="$2" preserve="${3:-false}"
  mkdir -p "$(dirname "$dst")"
  if [[ "$preserve" == "true" && -f "$dst" ]]; then
    warn "Preserved existing : ${dst#"$TARGET/"}"
    return
  fi
  cp "$src" "$dst"
  ok "Installed : ${dst#"$TARGET/"}"
}

# Recursively copy all files in src/ to dst/. Never preserves — pack owns these.
_copy_dir() {
  local src="$1" dst="$2"
  while IFS= read -r -d '' file; do
    rel="${file#"$src"/}"
    _copy_file "$file" "$dst/$rel" false
  done < <(find "$src" -type f -print0)
}

# ── Install pack-owned files (always up to date) ──────────────────
_copy_dir "$PACK_ROOT/.github/skills"       "$TARGET/.github/skills"
_copy_dir "$PACK_ROOT/.github/instructions" "$TARGET/.github/instructions"
_copy_dir "$PACK_ROOT/.github/agents"       "$TARGET/.github/agents"
_copy_dir "$PACK_ROOT/.claude/agents"       "$TARGET/.claude/agents"
_copy_file "$PACK_ROOT/.claude/skills.md"   "$TARGET/.claude/skills.md"

# ── Install user-configured stubs (preserve if already filled in) ─
_copy_file "$PACK_ROOT/.dev-iq/config.yaml"          "$TARGET/.dev-iq/config.yaml"          true
_copy_file "$PACK_ROOT/.dev-iq/governance.md"         "$TARGET/.dev-iq/governance.md"         true
_copy_file "$PACK_ROOT/.dev-iq/maturity-profile.md"   "$TARGET/.dev-iq/maturity-profile.md"   true
_copy_file "$PACK_ROOT/.dev-iq/telemetry-overlay.md"  "$TARGET/.dev-iq/telemetry-overlay.md"  true

# ── Install hooks (optional) ──────────────────────────────────────
if [[ "$INCLUDE_HOOKS" == true ]]; then
  _copy_dir "$PACK_ROOT/hooks" "$TARGET/hooks"
  ok "Hooks installed."
fi

# ── CLAUDE.md injection ───────────────────────────────────────────
CLAUDE_SRC="$PACK_ROOT/CLAUDE.md"
CLAUDE_DST="$TARGET/CLAUDE.md"

_inject_claude_md() {
  if [[ ! -f "$CLAUDE_DST" ]]; then
    # No existing CLAUDE.md — create it with markers
    {
      printf '%s\n' "$MARKER_START"
      cat "$CLAUDE_SRC"
      printf '%s\n' "$MARKER_END"
    } > "$CLAUDE_DST"
    ok "Created CLAUDE.md with Dev.IQ instructions."
    return
  fi

  if grep -qF "$MARKER_START" "$CLAUDE_DST" 2>/dev/null; then
    # Upgrade path — replace the existing marker block
    python3 - "$CLAUDE_DST" "$CLAUDE_SRC" "$MARKER_START" "$MARKER_END" << 'PYEOF'
import sys

dst_path, src_path, marker_start, marker_end = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open(dst_path) as f:
    original = f.read()
with open(src_path) as f:
    new_content = f.read()

new_block = marker_start + "\n" + new_content + "\n" + marker_end

start_idx = original.find(marker_start)
end_idx   = original.find(marker_end)

if start_idx == -1 or end_idx == -1:
    sys.exit("Marker not found — this should not happen.")

after_end = end_idx + len(marker_end)
result = original[:start_idx] + new_block + original[after_end:]

with open(dst_path, "w") as f:
    f.write(result)
PYEOF
    ok "Updated Dev.IQ block in existing CLAUDE.md."
  else
    # First-time append — existing CLAUDE.md with no dev-iq section yet
    {
      printf '\n\n'
      printf '%s\n' "$MARKER_START"
      cat "$CLAUDE_SRC"
      printf '%s\n' "$MARKER_END"
    } >> "$CLAUDE_DST"
    ok "Appended Dev.IQ instructions to existing CLAUDE.md."
  fi
}

_inject_claude_md

# ── Trial mode: add paths to .git/info/exclude ───────────────────
if [[ "$MODE" == "trial" ]]; then
  EXCLUDE="$TARGET/.git/info/exclude"
  mkdir -p "$(dirname "$EXCLUDE")"
  touch "$EXCLUDE"

  if grep -qF "# dev-iq" "$EXCLUDE" 2>/dev/null; then
    warn "Trial mode entries already present in .git/info/exclude."
  else
    cat >> "$EXCLUDE" << EOF

# dev-iq — trial install v${PACK_VERSION}
.github/skills/
.github/instructions/
.github/agents/
.claude/agents/
.claude/skills.md
.dev-iq/
CLAUDE.md
EOF
    [[ "$INCLUDE_HOOKS" == true ]] && printf 'hooks/\n' >> "$EXCLUDE"
    ok "Dev.IQ paths added to .git/info/exclude (invisible to git)."
  fi
fi

# ── Write install manifest ────────────────────────────────────────
mkdir -p "$TARGET/.dev-iq"
HOOKS_BOOL=$( [[ "$INCLUDE_HOOKS" == true ]] && echo "true" || echo "false" )
UPGRADE_BOOL=$( [[ "$IS_UPGRADE" == true ]] && echo "true" || echo "false" )

python3 - << PYEOF
import json, datetime

manifest = {
    "version":          "$PACK_VERSION",
    "installed_at":     datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "mode":             "$MODE",
    "pack_source":      "$PACK_ROOT",
    "hooks_installed":  $HOOKS_BOOL,
    "is_upgrade":       $UPGRADE_BOOL
}

with open("$MANIFEST", "w") as f:
    json.dump(manifest, f, indent=2)
PYEOF
ok "Manifest written : .dev-iq/.install-manifest.json"

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo -e "  ${C_GRN}${C_BLD}Dev.IQ Agent Pack v${PACK_VERSION} installed successfully. (${MODE} mode)${C_RST}"
echo ""
echo -e "  ${C_BLD}Next steps:${C_RST}"
echo -e "  1. Edit ${C_BLD}.dev-iq/config.yaml${C_RST}"
echo -e "     Set: client name · maturity tier (early/mid/higher) · tracker type (ado/jira)"
echo -e "  2. Open VS Code in this project"
echo -e "  3. In Copilot Chat or Claude Code, select the ${C_BLD}Dev-IQ${C_RST} agent"
echo -e "  4. Type ${C_BLD}/${C_RST} to see all available skills"
echo -e "  5. Run ${C_BLD}/explain-code${C_RST} on any file to verify the install"
echo ""
if [[ "$MODE" == "trial" ]]; then
  echo -e "  To share with your team when ready:"
  echo -e "  ${C_BLD}bash /path/to/dev-iq/scripts/bootstrap.sh --target=$TARGET --graduate${C_RST}"
  echo ""
fi
