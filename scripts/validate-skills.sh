#!/usr/bin/env bash
# Validates frontmatter in all SKILL.md files and agent .md files.
# Usage: bash scripts/validate-skills.sh
# Exit 0 = all valid. Exit 1 = validation failures found.
# No external dependencies — requires only bash and awk (standard on macOS/Linux/WSL/Git Bash).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/.github/skills"
AGENTS_DIR="$ROOT/.github/agents"

SKILL_REQUIRED=(name description di_signal maturity_required status)
SKILL_VALID_MATURITY=(early mid higher)
SKILL_VALID_STATUS=(approved draft deprecated)
AGENT_REQUIRED=(description)

errors=0

get_fm_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    /^---/ { delimiters++; next }
    delimiters == 1 && $0 ~ "^" key ":" {
      sub("^" key ":[ \t]*", "")
      print; exit
    }
    delimiters >= 2 { exit }
  ' "$file"
}

has_frontmatter() {
  local count
  count=$(grep -c '^---' "$1" 2>/dev/null || echo 0)
  [ "$count" -ge 2 ]
}

in_array() {
  local val="$1"; shift
  for item in "$@"; do [ "$item" = "$val" ] && return 0; done
  return 1
}

validate_skill() {
  local file="$1"
  local rel="${file#"$ROOT"/}"
  local file_errors=0
  local val

  if ! has_frontmatter "$file"; then
    echo "  FAIL  no frontmatter found: $rel"
    errors=$((errors + 1))
    return
  fi

  for field in "${SKILL_REQUIRED[@]}"; do
    val=$(get_fm_value "$file" "$field")
    if [ -z "$val" ]; then
      echo "  FAIL  missing '$field': $rel"
      file_errors=$((file_errors + 1))
    fi
  done

  val=$(get_fm_value "$file" "maturity_required")
  if [ -n "$val" ] && ! in_array "$val" "${SKILL_VALID_MATURITY[@]}"; then
    echo "  FAIL  invalid maturity_required '$val' (expected: ${SKILL_VALID_MATURITY[*]}): $rel"
    file_errors=$((file_errors + 1))
  fi

  val=$(get_fm_value "$file" "status")
  if [ -n "$val" ] && ! in_array "$val" "${SKILL_VALID_STATUS[@]}"; then
    echo "  FAIL  invalid status '$val' (expected: ${SKILL_VALID_STATUS[*]}): $rel"
    file_errors=$((file_errors + 1))
  fi

  if [ "$file_errors" -eq 0 ]; then
    echo "  OK    $rel"
  else
    errors=$((errors + file_errors))
  fi
}

validate_agent() {
  local file="$1"
  local rel="${file#"$ROOT"/}"
  local file_errors=0
  local val

  if ! has_frontmatter "$file"; then
    echo "  FAIL  no frontmatter found: $rel"
    errors=$((errors + 1))
    return
  fi

  for field in "${AGENT_REQUIRED[@]}"; do
    val=$(get_fm_value "$file" "$field")
    if [ -z "$val" ]; then
      echo "  FAIL  missing '$field': $rel"
      file_errors=$((file_errors + 1))
    fi
  done

  if [ "$file_errors" -eq 0 ]; then
    echo "  OK    $rel"
  else
    errors=$((errors + file_errors))
  fi
}

echo ""
echo "Validating skills..."
if [ -d "$SKILLS_DIR" ]; then
  for skill_dir in "$SKILLS_DIR"/*/; do
    [ -f "${skill_dir}SKILL.md" ] && validate_skill "${skill_dir}SKILL.md"
  done
fi

echo ""
echo "Validating agents..."
if [ -d "$AGENTS_DIR" ]; then
  for agent_file in "$AGENTS_DIR"/*.md; do
    [ -f "$agent_file" ] && validate_agent "$agent_file"
  done
fi

echo ""
if [ "$errors" -eq 0 ]; then
  echo "All files valid."
  exit 0
else
  echo "$errors error(s) found."
  exit 1
fi
