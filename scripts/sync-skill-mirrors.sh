#!/bin/bash
# sync-skill-mirrors.sh
# Sync skills from skills/ (SSOT) to local and packaged mirrors.
#
# Why:
#   Windows checkout with core.symlinks=false turns repository symlinks into
#   plain text files. Claude Code ignores those files when building the slash
#   command list, so the harness-* entry skills disappear before SessionStart
#   repair hooks can run.
#
# This script keeps skills as real directories in:
#   - .agents/skills/
#   - codex/.codex/skills/
#   - opencode/skills/ (generated through build-opencode.js)
#
# Source of truth:
#   - skills/ for shared skills
#   - skills-codex/ for Codex-only variants
#
# Sync scope:
#   - All skill directories that exist in BOTH the resolved SSOT and a mirror root
#   - New skills added only to skills/ are NOT auto-propagated (add manually)
#   - routing-rules.md is synced if present in both
#
# Usage:
#   ./scripts/sync-skill-mirrors.sh          # overwrite mirrors from skills/
#   ./scripts/sync-skill-mirrors.sh --check  # verify mirrors match skills/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SHARED_SSOT_DIR="$PLUGIN_ROOT/skills"
CODEX_SSOT_DIR="$PLUGIN_ROOT/skills-codex"

# Mirror roots (skills/ is the SSOT, not a mirror)
MIRROR_ROOTS=(
  ".agents/skills"
  "codex/.codex/skills"
  "opencode/skills"
)

MODE="sync"
if [ "${1:-}" = "--check" ]; then
  MODE="check"
elif [ -n "${1:-}" ]; then
  echo "Usage: $0 [--check]" >&2
  exit 2
fi

sync_skill() {
  local skill="$1"
  local mirror_root="$2"
  local src
  src="$(resolve_src_dir "$skill" "$mirror_root")"
  local dst_root="$PLUGIN_ROOT/$mirror_root"
  local dst="$dst_root/$skill"

  mkdir -p "$dst_root"
  rm -rf "$dst"
  cp -R "$src" "$dst"
  echo "synced $mirror_root/$skill"
}

normalize_opencode_skill_name() {
  printf '%s\n' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

is_opencode_skipped_skill() {
  case "$1" in
    test-*|x-*|allow1|cc-update-review|claude-codex-upstream-update|harness-release-internal|zz-review-empty|zz-review-escape)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

extract_markdown_body() {
  local file="$1"

  awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { in_frontmatter = 0; body_started = 1; next }
    in_frontmatter { next }
    { print }
  ' "$file"
}

check_opencode_mirror() {
  if ! node "$PLUGIN_ROOT/scripts/validate-opencode.js"; then
    return 1
  fi

  local expected_file actual_file
  expected_file="$(mktemp)"
  actual_file="$(mktemp)"
  trap 'rm -f "$expected_file" "$actual_file"' RETURN

  for entry in "$SHARED_SSOT_DIR"/*/; do
    [ -d "$entry" ] || continue
    local skill
    skill="$(basename "$entry")"
    [ -f "$entry/SKILL.md" ] || continue
    if is_opencode_skipped_skill "$skill"; then
      continue
    fi
    normalize_opencode_skill_name "$skill" >> "$expected_file"
  done

  find "$PLUGIN_ROOT/opencode/skills" -mindepth 2 -maxdepth 2 -type f -name "SKILL.md" \
    | while IFS= read -r skill_file; do
        basename "$(dirname "$skill_file")"
      done > "$actual_file"

  sort -u -o "$expected_file" "$expected_file"
  sort -u -o "$actual_file" "$actual_file"

  if ! diff -u "$expected_file" "$actual_file"; then
    echo "drift opencode/skills generated skill set" >&2
    return 1
  fi

  for entry in "$SHARED_SSOT_DIR"/*/; do
    [ -d "$entry" ] || continue
    local skill opencode_skill source_dir mirror_dir source_body mirror_body
    skill="$(basename "$entry")"
    [ -f "$entry/SKILL.md" ] || continue
    if is_opencode_skipped_skill "$skill"; then
      continue
    fi

    opencode_skill="$(normalize_opencode_skill_name "$skill")"
    mirror_dir="$PLUGIN_ROOT/opencode/skills/$opencode_skill"
    source_dir="$SHARED_SSOT_DIR/$skill"
    [ -d "$mirror_dir" ] || {
      echo "missing opencode skill mirror: $opencode_skill" >&2
      return 1
    }

    source_body="$(mktemp)"
    mirror_body="$(mktemp)"
    trap 'rm -f "$expected_file" "$actual_file" "$source_body" "$mirror_body"' RETURN
    extract_markdown_body "$source_dir/SKILL.md" > "$source_body"
    extract_markdown_body "$mirror_dir/SKILL.md" > "$mirror_body"
    if ! diff -u "$source_body" "$mirror_body" >/dev/null; then
      echo "drift opencode/skills/$opencode_skill/SKILL.md body" >&2
      diff -u "$source_body" "$mirror_body" >&2 || true
      return 1
    fi

    if ! diff -qr --exclude='.DS_Store' --exclude='SKILL.md' --exclude='CLAUDE.md' --exclude='node_modules' --exclude='coverage' --exclude='.claude' --exclude='IMPLEMENTATION_*' --exclude='TASK_*' "$source_dir" "$mirror_dir" >/dev/null; then
      echo "drift opencode/skills/$opencode_skill support files" >&2
      diff -qr --exclude='.DS_Store' --exclude='SKILL.md' --exclude='CLAUDE.md' --exclude='node_modules' --exclude='coverage' --exclude='.claude' --exclude='IMPLEMENTATION_*' --exclude='TASK_*' "$source_dir" "$mirror_dir" >&2 || true
      return 1
    fi
  done

  echo "ok opencode/skills"
}

check_skill() {
  local skill="$1"
  local mirror_root="$2"
  local src
  src="$(resolve_src_dir "$skill" "$mirror_root")"
  local dst="$PLUGIN_ROOT/$mirror_root/$skill"

  if [ ! -d "$dst" ]; then
    echo "missing $mirror_root/$skill" >&2
    return 1
  fi

  if [ -L "$dst" ]; then
    echo "symlink $mirror_root/$skill" >&2
    return 1
  fi

  if ! diff -qr --exclude='.DS_Store' --exclude='.claude' "$src" "$dst" >/dev/null; then
    echo "drift $mirror_root/$skill" >&2
    return 1
  fi

  echo "ok $mirror_root/$skill"
}

resolve_src_dir() {
  local skill="$1"
  local mirror_root="$2"

  if [ "$mirror_root" = "codex/.codex/skills" ] && [ -d "$CODEX_SSOT_DIR/$skill" ]; then
    printf '%s\n' "$CODEX_SSOT_DIR/$skill"
    return 0
  fi

  printf '%s\n' "$SHARED_SSOT_DIR/$skill"
}

FAILURES=0
for mirror_root in "${MIRROR_ROOTS[@]}"; do
  mirror_dir="$PLUGIN_ROOT/$mirror_root"
  [ -d "$mirror_dir" ] || continue

  if [ "$mirror_root" = "opencode/skills" ]; then
    if [ "$MODE" = "sync" ]; then
      node "$PLUGIN_ROOT/scripts/build-opencode.js"
    else
      if ! check_opencode_mirror; then
        FAILURES=$((FAILURES + 1))
      fi
    fi
    continue
  fi

  # Discovery: sync every skill directory that exists in both SSOT and mirror
  for entry in "$mirror_dir"/*/; do
    [ -d "$entry" ] || continue
    skill="$(basename "$entry")"

    # Skip non-skill entries
    [ "$skill" = "node_modules" ] && continue
    [ "$skill" = ".git" ] && continue

    # Only sync if the resolved SSOT has this skill
    if [ ! -d "$(resolve_src_dir "$skill" "$mirror_root")" ]; then
      continue
    fi

    if [ "$MODE" = "sync" ]; then
      sync_skill "$skill" "$mirror_root"
    else
      if ! check_skill "$skill" "$mirror_root"; then
        FAILURES=$((FAILURES + 1))
      fi
    fi
  done

  # Also sync routing-rules.md if present in both
  if [ -f "$SHARED_SSOT_DIR/routing-rules.md" ] && [ -f "$mirror_dir/routing-rules.md" ]; then
    if [ "$MODE" = "sync" ]; then
      cp "$SHARED_SSOT_DIR/routing-rules.md" "$mirror_dir/routing-rules.md"
      echo "synced $mirror_root/routing-rules.md"
    else
      if ! diff -q "$SHARED_SSOT_DIR/routing-rules.md" "$mirror_dir/routing-rules.md" >/dev/null; then
        echo "drift $mirror_root/routing-rules.md" >&2
        FAILURES=$((FAILURES + 1))
      else
        echo "ok $mirror_root/routing-rules.md"
      fi
    fi
  fi
done

if [ "$MODE" = "check" ] && [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
