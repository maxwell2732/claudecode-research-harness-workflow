#!/bin/bash
# harness-review-closeout.sh
# Lightweight harness-review closeout helper for --quick / --codex-closeout paths.
#
# Usage: bash scripts/harness-review-closeout.sh [options]

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=0
PARALLEL_TESTS=0
JSON=0
BASE_REF=""
COMMIT_REF=""
TARGET_MODE="auto"
TEST_COMMANDS=()

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/harness-review-closeout.sh [options]

Options:
  --dry-run             Print the review/test plan without running Codex review.
  --parallel-tests      Run --test commands concurrently.
  --base REF            Review REF..HEAD.
  --commit REF          Review a single commit. Base becomes REF^.
  --uncommitted         Review working tree against HEAD, including untracked files.
  --test CMD            Focused test command. May be repeated.
  --json                Emit a compact JSON summary.
  -h, --help            Show help.
USAGE
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --parallel-tests)
      PARALLEL_TESTS=1
      shift
      ;;
    --base)
      BASE_REF="${2:-}"
      TARGET_MODE="branch_range"
      shift 2
      ;;
    --base=*)
      BASE_REF="${1#*=}"
      TARGET_MODE="branch_range"
      shift
      ;;
    --commit)
      COMMIT_REF="${2:-}"
      TARGET_MODE="commit"
      shift 2
      ;;
    --commit=*)
      COMMIT_REF="${1#*=}"
      TARGET_MODE="commit"
      shift
      ;;
    --uncommitted)
      TARGET_MODE="working_tree"
      BASE_REF="HEAD"
      shift
      ;;
    --test)
      TEST_COMMANDS+=("${2:-}")
      shift 2
      ;;
    --test=*)
      TEST_COMMANDS+=("${1#*=}")
      shift
      ;;
    --json)
      JSON=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ "$TARGET_MODE" = "commit" ]; then
  if [ -z "$COMMIT_REF" ]; then
    echo "--commit requires a ref" >&2
    exit 2
  fi
  BASE_REF="${COMMIT_REF}^"
elif [ "$TARGET_MODE" = "auto" ]; then
  if [ -n "$(git -C "$ROOT_DIR" status --porcelain 2>/dev/null)" ]; then
    TARGET_MODE="working_tree"
    BASE_REF="HEAD"
  elif git -C "$ROOT_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    TARGET_MODE="branch_range"
    BASE_REF="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')"
  elif git -C "$ROOT_DIR" rev-parse --verify origin/main >/dev/null 2>&1; then
    TARGET_MODE="branch_range"
    BASE_REF="origin/main"
  else
    TARGET_MODE="commit"
    COMMIT_REF="HEAD"
    BASE_REF="HEAD^"
  fi
fi

if [ -z "$BASE_REF" ]; then
  echo "base ref could not be determined" >&2
  exit 2
fi

REVIEW_COMMAND="bash $ROOT_DIR/scripts/codex-companion.sh review --base ${BASE_REF} --json"
CODEX_AVAILABLE=0
FALLBACK=""
REVIEW_STATUS="not_run"

if bash "$ROOT_DIR/scripts/codex-companion.sh" setup --json >/dev/null 2>&1; then
  CODEX_AVAILABLE=1
else
  FALLBACK="codex unavailable; use full manual pass"
fi

if [ "$DRY_RUN" -eq 0 ] && [ "$CODEX_AVAILABLE" -eq 1 ]; then
  if bash "$ROOT_DIR/scripts/codex-companion.sh" review --base "$BASE_REF" --json; then
    REVIEW_STATUS="passed"
  else
    REVIEW_STATUS="failed"
  fi
elif [ "$DRY_RUN" -eq 1 ]; then
  REVIEW_STATUS="dry_run"
fi

TEST_STATUS="not_run"
if [ "${#TEST_COMMANDS[@]}" -gt 0 ]; then
  TEST_STATUS="passed"
  if [ "$PARALLEL_TESTS" -eq 1 ]; then
    PIDS=()
    for test_cmd in "${TEST_COMMANDS[@]}"; do
      bash -lc "$test_cmd" &
      PIDS+=("$!")
    done
    for pid in "${PIDS[@]}"; do
      if ! wait "$pid"; then
        TEST_STATUS="failed"
      fi
    done
  else
    for test_cmd in "${TEST_COMMANDS[@]}"; do
      if ! bash -lc "$test_cmd"; then
        TEST_STATUS="failed"
      fi
    done
  fi
fi

if [ "$JSON" -eq 1 ]; then
  printf '{'
  printf '"schema_version":"harness-review-closeout.v1",'
  printf '"target":"%s",' "$(json_escape "$TARGET_MODE")"
  printf '"base_ref":"%s",' "$(json_escape "$BASE_REF")"
  printf '"review_command":"%s",' "$(json_escape "$REVIEW_COMMAND")"
  printf '"review_status":"%s",' "$(json_escape "$REVIEW_STATUS")"
  printf '"test_status":"%s",' "$(json_escape "$TEST_STATUS")"
  printf '"codex_available":%s,' "$([ "$CODEX_AVAILABLE" -eq 1 ] && echo true || echo false)"
  printf '"fallback":"%s",' "$(json_escape "$FALLBACK")"
  printf '"accepted_findings":[],"rejected_findings":[],"clean_result":%s' "$([ "$REVIEW_STATUS" != "failed" ] && [ "$TEST_STATUS" != "failed" ] && echo true || echo false)"
  printf '}\n'
else
  echo "harness-review closeout plan"
  echo "target: $TARGET_MODE"
  echo "base_ref: $BASE_REF"
  echo "review_command: $REVIEW_COMMAND"
  echo "codex_available: $CODEX_AVAILABLE"
  [ -n "$FALLBACK" ] && echo "fallback: $FALLBACK"
  echo "review_status: $REVIEW_STATUS"
  echo "test_status: $TEST_STATUS"
  if [ "${#TEST_COMMANDS[@]}" -gt 0 ]; then
    echo "tests:"
    printf '  - %s\n' "${TEST_COMMANDS[@]}"
  fi
fi

if [ "$REVIEW_STATUS" = "failed" ] || [ "$TEST_STATUS" = "failed" ]; then
  exit 1
fi

if [ "$CODEX_AVAILABLE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
  exit 3
fi
