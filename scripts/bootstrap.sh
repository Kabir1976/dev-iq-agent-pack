#!/usr/bin/env bash
# Dev.IQ Agent Pack — Bootstrap Installer
# Version : 0.9.0
# Usage   : bash scripts/bootstrap.sh [--target=<path>] [--mode=trial|committed]
#           [--preset=pod|solo|portable] [--graduate] [--uninstall] [--hooks]
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
UNINSTALL=false
INCLUDE_HOOKS=false
PRESET=""

for arg in "$@"; do
  case "$arg" in
    --target=*)   TARGET="${arg#*=}" ;;
    --mode=*)     MODE="${arg#*=}" ;;
    --preset=*)   PRESET="${arg#*=}" ;;
    --graduate)   GRADUATE=true ;;
    --uninstall)  UNINSTALL=true ;;
    --hooks)      INCLUDE_HOOKS=true ;;
    --help|-h)
      cat << EOF
Dev.IQ Agent Pack — Bootstrap Installer v${PACK_VERSION}

Usage:
  bash scripts/bootstrap.sh [options]

Options:
  --target=<path>    Target repository root (default: current directory)
  --mode=trial       Install locally, invisible to git until you graduate
  --mode=committed   Install files visibly so the team can commit them
  --preset=pod       Team pod: committed + hooks
  --preset=solo      Solo dev: trial, no hooks
  --preset=portable  Minimal: committed, no hooks
  --graduate         Convert a trial install to committed mode
  --uninstall        Remove Dev.IQ from the target repository
  --hooks            Also install the hooks/ directory

Examples:
  bash /path/to/dev-iq/scripts/bootstrap.sh
  bash /path/to/dev-iq/scripts/bootstrap.sh --preset=solo
  bash /path/to/dev-iq/scripts/bootstrap.sh --preset=pod
  bash /path/to/dev-iq/scripts/bootstrap.sh --target=/path/to/repo --graduate
  bash /path/to/dev-iq/scripts/bootstrap.sh --target=/path/to/repo --uninstall
EOF
      exit 0
      ;;
    *) die "Unknown argument: '$arg'. Run with --help for usage." ;;
  esac
done

# ── Apply preset ──────────────────────────────────────────────────
if [[ -n "$PRESET" ]]; then
  case "$PRESET" in
    pod)       MODE="committed"; INCLUDE_HOOKS=true  ;;
    solo)      MODE="trial";     INCLUDE_HOOKS=false ;;
    portable)  MODE="committed"; INCLUDE_HOOKS=false ;;
    *) die "Unknown preset: '$PRESET'. Use: pod | solo | portable" ;;
  esac
fi

# ── Validate prerequisites ────────────────────────────────────────
# git is required for .git/info/exclude (trial mode) and remote detection.
command -v git >/dev/null 2>&1 || die "git is required but not found."

[[ -d "$TARGET" ]]      || die "Target directory not found: $TARGET"
[[ -d "$TARGET/.git" ]] || die "Target is not a git repository: $TARGET"
TARGET="$(cd "$TARGET" && pwd)"

# ── Auto-detect project context ───────────────────────────────────
DETECTED_TRACKER="ado"
DETECTED_VCS="github"
DETECTED_ADO_ORG=""
DETECTED_ADO_PROJECT=""
DETECTED_LANG=""
DETECTED_FRAMEWORK=""

detect_context() {
  local remote_url
  remote_url=$(git -C "$TARGET" remote get-url origin 2>/dev/null || true)

  # Tracker + VCS from git remote URL
  if [[ "$remote_url" =~ dev\.azure\.com ]]; then
    DETECTED_TRACKER="ado"
    DETECTED_VCS="ado-repos"
    # Handles: https://dev.azure.com/ORG/PROJECT/_git/REPO
    #      and https://ORG@dev.azure.com/ORG/PROJECT/_git/REPO
    if [[ "$remote_url" =~ dev\.azure\.com/([^/@]+)/([^/]+) ]]; then
      DETECTED_ADO_ORG="https://dev.azure.com/${BASH_REMATCH[1]}"
      DETECTED_ADO_PROJECT="${BASH_REMATCH[2]}"
    fi
  elif [[ "$remote_url" =~ github\.com ]]; then
    DETECTED_VCS="github"
    DETECTED_TRACKER="github-issues"
  elif [[ "$remote_url" =~ gitlab\.com ]]; then
    DETECTED_VCS="gitlab"
  elif [[ "$remote_url" =~ bitbucket\.org ]]; then
    DETECTED_VCS="bitbucket"
  fi

  # Language from project files (checked in priority order)
  if [[ -f "$TARGET/package.json" ]]; then
    if [[ -f "$TARGET/tsconfig.json" ]]; then
      DETECTED_LANG="typescript"
    else
      DETECTED_LANG="javascript"
    fi
  elif [[ -f "$TARGET/requirements.txt" || -f "$TARGET/pyproject.toml" || -f "$TARGET/setup.py" ]]; then
    DETECTED_LANG="python"
  elif [[ -f "$TARGET/pom.xml" ]]; then
    DETECTED_LANG="java"
  elif find "$TARGET" -maxdepth 4 -name "*.csproj" -print -quit 2>/dev/null | grep -q '.'; then
    DETECTED_LANG="csharp"
  elif ls "$TARGET"/build.gradle* 2>/dev/null | grep -q '.'; then
    DETECTED_LANG="java"
  elif [[ -f "$TARGET/go.mod" ]]; then
    DETECTED_LANG="go"
  elif [[ -f "$TARGET/Gemfile" ]]; then
    DETECTED_LANG="ruby"
  elif [[ -f "$TARGET/Cargo.toml" ]]; then
    DETECTED_LANG="rust"
  fi

  # Framework from package.json dependencies
  if [[ -f "$TARGET/package.json" ]]; then
    local pkg
    pkg=$(cat "$TARGET/package.json" 2>/dev/null || true)
    if printf '%s' "$pkg" | grep -q '"next"'; then
      DETECTED_FRAMEWORK="nextjs"
    elif printf '%s' "$pkg" | grep -q '"react"'; then
      DETECTED_FRAMEWORK="react"
    elif printf '%s' "$pkg" | grep -q '"@angular/core"'; then
      DETECTED_FRAMEWORK="angular"
    elif printf '%s' "$pkg" | grep -q '"vue"'; then
      DETECTED_FRAMEWORK="vue"
    elif printf '%s' "$pkg" | grep -q '"@nestjs/core"'; then
      DETECTED_FRAMEWORK="nestjs"
    elif printf '%s' "$pkg" | grep -q '"express"'; then
      DETECTED_FRAMEWORK="express"
    fi
  elif [[ -f "$TARGET/requirements.txt" ]]; then
    local reqs
    reqs=$(cat "$TARGET/requirements.txt" 2>/dev/null || true)
    if printf '%s' "$reqs" | grep -qi "fastapi"; then
      DETECTED_FRAMEWORK="fastapi"
    elif printf '%s' "$reqs" | grep -qi "django"; then
      DETECTED_FRAMEWORK="django"
    elif printf '%s' "$reqs" | grep -qi "flask"; then
      DETECTED_FRAMEWORK="flask"
    fi
  fi
}

detect_context

# ── Detect existing install ───────────────────────────────────────
MANIFEST="$TARGET/.dev-iq/.install-manifest.json"
IS_UPGRADE=false

if [[ -f "$MANIFEST" ]]; then
  IS_UPGRADE=true
  PREV_VERSION=$(grep '"version"' "$MANIFEST" | sed 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || echo "unknown")
  PREV_MODE=$(grep '"mode"' "$MANIFEST" | sed 's/.*"mode":[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || echo "trial")
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

  sed -i.bak 's/"mode": "trial"/"mode": "committed"/' "$MANIFEST" 2>/dev/null \
    && rm -f "${MANIFEST}.bak" \
    || warn "Could not update manifest mode — edit .dev-iq/.install-manifest.json manually."

  ok "Graduated to committed mode."
  echo ""
  log "Dev.IQ files are now visible to git."
  log "Next: git add the dev-iq files and open a team PR."
  exit 0
fi

# ── Uninstall mode ────────────────────────────────────────────────
if [[ "$UNINSTALL" == true ]]; then
  echo ""
  log "Removing Dev.IQ Agent Pack from: $TARGET"
  echo ""

  if [[ -t 0 ]]; then
    read -rp "  This will delete Dev.IQ files from $TARGET. Continue? [y/N] " _confirm
    [[ "${_confirm,,}" == "y" ]] || { log "Uninstall cancelled."; exit 0; }
  fi

  for dir in ".github/skills" ".github/instructions" ".github/agents" ".claude/agents"; do
    if [[ -d "$TARGET/$dir" ]]; then
      rm -rf "${TARGET:?}/$dir"
      ok "Removed : $dir"
    fi
  done

  for file in ".claude/skills.md"; do
    if [[ -f "$TARGET/$file" ]]; then
      rm -f "$TARGET/$file"
      ok "Removed : $file"
    fi
  done

  CLAUDE_DST="$TARGET/CLAUDE.md"
  if [[ -f "$CLAUDE_DST" ]] && grep -qF "$MARKER_START" "$CLAUDE_DST" 2>/dev/null; then
    sed -i.bak "/${MARKER_START//\//\\/}/,/${MARKER_END//\//\\/}/d" "$CLAUDE_DST" 2>/dev/null \
      && rm -f "${CLAUDE_DST}.bak" \
      || warn "Could not remove Dev.IQ block from CLAUDE.md — delete the block between $MARKER_START and $MARKER_END manually."
    ok "Removed Dev.IQ block from CLAUDE.md."
    [[ -s "$CLAUDE_DST" ]] || { rm -f "$CLAUDE_DST"; ok "Removed empty CLAUDE.md."; }
  fi

  EXCLUDE="$TARGET/.git/info/exclude"
  if [[ -f "$EXCLUDE" ]] && grep -qF "# dev-iq" "$EXCLUDE" 2>/dev/null; then
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

  if [[ -d "$TARGET/.dev-iq" ]]; then
    rm -rf "${TARGET:?}/.dev-iq"
    ok "Removed : .dev-iq/"
  fi

  echo ""
  ok "Dev.IQ removed from $TARGET."
  log "Your code, tests, and configs were not touched."
  exit 0
fi

# ── Select install mode ───────────────────────────────────────────
if [[ -z "$MODE" ]]; then
  if [[ -t 0 ]]; then
    echo ""
    echo -e "  ${C_BLD}Just you, or the whole team?${C_RST}"
    echo ""
    echo -e "  ${C_BLD}[1]${C_RST} Just me    — installed locally, invisible to git until you're ready"
    echo -e "  ${C_BLD}[2]${C_RST} Whole team — files go into git; commit and share straight away"
    echo ""
    read -rp "  [1/2] (default: 1): " _choice
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
log "  Target   : $TARGET"
log "  Mode     : $MODE${PRESET:+ (preset: $PRESET)}"
if [[ -n "$DETECTED_LANG" ]]; then
log "  Detected : ${DETECTED_LANG}${DETECTED_FRAMEWORK:+ / $DETECTED_FRAMEWORK} · ${DETECTED_TRACKER} · ${DETECTED_VCS}"
fi
log "─────────────────────────────────────────────"
echo ""

# ── File copy helpers ─────────────────────────────────────────────
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

_copy_dir() {
  local src="$1" dst="$2"
  while IFS= read -r -d '' file; do
    rel="${file#"$src"/}"
    _copy_file "$file" "$dst/$rel" false
  done < <(find "$src" -type f -print0)
}

# ── Install pack-owned files ──────────────────────────────────────
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

# ── Pre-fill config.yaml with auto-detected values ────────────────
prefill_config() {
  local cfg="$1"
  [[ -f "$cfg" ]]              || return
  [[ "$IS_UPGRADE" == false ]] || return

  local _filled=false

  # tracker.type: config default is "ado"; overwrite with detected value.
  if [[ -n "$DETECTED_TRACKER" ]]; then
    sed -i.bak "s/type: \"ado\"/type: \"${DETECTED_TRACKER}\"/" "$cfg" \
      && rm -f "${cfg}.bak"
    # signals.intent.source mirrors tracker
    sed -i.bak "s/source: \"ado\"/source: \"${DETECTED_TRACKER}\"/" "$cfg" \
      && rm -f "${cfg}.bak"
    _filled=true
  fi

  # vcs.type: config default is "github"; only overwrite when different.
  if [[ -n "$DETECTED_VCS" && "$DETECTED_VCS" != "github" ]]; then
    sed -i.bak "s/type: \"github\"/type: \"${DETECTED_VCS}\"/" "$cfg" \
      && rm -f "${cfg}.bak"
    _filled=true
  fi

  # ado.org_url — empty string placeholder.
  if [[ -n "$DETECTED_ADO_ORG" ]]; then
    sed -i.bak "s|org_url: \"\"|org_url: \"${DETECTED_ADO_ORG}\"|" "$cfg" \
      && rm -f "${cfg}.bak"
    _filled=true
  fi

  # ado.project — first empty project: "" in the file.
  if [[ -n "$DETECTED_ADO_PROJECT" ]]; then
    awk -v val="$DETECTED_ADO_PROJECT" \
      '!done && /project: ""/{sub(/project: ""/, "project: \"" val "\""); done=1} 1' \
      "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
    _filled=true
  fi

  # stack.languages — first "    - """.
  if [[ -n "$DETECTED_LANG" ]]; then
    awk -v val="$DETECTED_LANG" \
      '!done && /    - ""/{sub(/    - ""/, "    - \"" val "\""); done=1} 1' \
      "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
    _filled=true
  fi

  # stack.frameworks — first remaining "    - """.
  if [[ -n "$DETECTED_FRAMEWORK" ]]; then
    awk -v val="$DETECTED_FRAMEWORK" \
      '!done && /    - ""/{sub(/    - ""/, "    - \"" val "\""); done=1} 1' \
      "$cfg" > "${cfg}.tmp" && mv "${cfg}.tmp" "$cfg"
    _filled=true
  fi

  [[ "$_filled" == true ]] && ok "Config pre-filled : .dev-iq/config.yaml"
}

prefill_config "$TARGET/.dev-iq/config.yaml"

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
    {
      printf '%s\n' "$MARKER_START"
      cat "$CLAUDE_SRC"
      printf '%s\n' "$MARKER_END"
    } > "$CLAUDE_DST"
    ok "Created CLAUDE.md with Dev.IQ instructions."
    return
  fi

  if grep -qF "$MARKER_START" "$CLAUDE_DST" 2>/dev/null; then
    # Remove old block, re-append updated content at end.
    sed -i.bak "/${MARKER_START//\//\\/}/,/${MARKER_END//\//\\/}/d" "$CLAUDE_DST" \
      && rm -f "${CLAUDE_DST}.bak"
    {
      printf '\n\n%s\n' "$MARKER_START"
      cat "$CLAUDE_SRC"
      printf '%s\n' "$MARKER_END"
    } >> "$CLAUDE_DST"
    ok "Updated Dev.IQ block in existing CLAUDE.md."
  else
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

# ── Create artifact store ─────────────────────────────────────────
mkdir -p "$TARGET/.dev-iq/artifacts/adrs"
mkdir -p "$TARGET/.dev-iq/artifacts/rollback-plans"
mkdir -p "$TARGET/.dev-iq/artifacts/user-stories"
mkdir -p "$TARGET/.dev-iq/artifacts/pr-reviews"
mkdir -p "$TARGET/.dev-iq/artifacts/signals"
_copy_file "$PACK_ROOT/.dev-iq/artifacts/.gitignore" "$TARGET/.dev-iq/artifacts/.gitignore" false
_copy_file "$PACK_ROOT/.dev-iq/artifacts/README.md"  "$TARGET/.dev-iq/artifacts/README.md"  false
ok "Artifact store created : .dev-iq/artifacts/"

# ── Write install manifest ────────────────────────────────────────
mkdir -p "$TARGET/.dev-iq"
HOOKS_BOOL=$( [[ "$INCLUDE_HOOKS" == true ]] && echo "true" || echo "false" )
UPGRADE_BOOL=$( [[ "$IS_UPGRADE" == true ]] && echo "true" || echo "false" )

_NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +%s)
cat > "$MANIFEST" << EOF
{
  "version": "$PACK_VERSION",
  "installed_at": "$_NOW",
  "mode": "$MODE",
  "pack_source": "$PACK_ROOT",
  "hooks_installed": $HOOKS_BOOL,
  "is_upgrade": $UPGRADE_BOOL,
  "detected": {
    "tracker": "${DETECTED_TRACKER}",
    "vcs": "${DETECTED_VCS}",
    "language": "${DETECTED_LANG}",
    "framework": "${DETECTED_FRAMEWORK}"
  }
}
EOF
ok "Manifest written : .dev-iq/.install-manifest.json"

# ── Done ──────────────────────────────────────────────────────────
echo ""
echo -e "  ${C_GRN}${C_BLD}Dev.IQ ${PACK_VERSION} is ready.${C_RST}"
echo ""
echo -e "  Open Copilot Chat or Claude Code, select ${C_BLD}Dev-IQ${C_RST}, and type:"
echo ""
echo -e "    ${C_BLD}/explain-code${C_RST}"
echo ""
echo -e "  That's it."
echo ""
if [[ -z "$DETECTED_LANG" ]]; then
  echo -e "  Language not detected — open ${C_BLD}.dev-iq/config.yaml${C_RST} and fill in ${C_BLD}stack.languages${C_RST}."
  echo ""
fi
if [[ "$MODE" == "trial" ]]; then
  echo -e "  Share with the team later:"
  echo -e "    ${C_BLD}bash /path/to/dev-iq/scripts/bootstrap.sh --target=$(pwd) --graduate${C_RST}"
  echo ""
fi
