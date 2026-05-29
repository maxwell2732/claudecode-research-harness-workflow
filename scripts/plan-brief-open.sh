#!/bin/bash
# scripts/plan-brief-open.sh
# Phase 65.1.2 - OS-specific browser auto-open dispatch for Plan Brief HTML
#
# Usage: ./scripts/plan-brief-open.sh <html_path>
#
# 動作:
#   - macOS: `open <path>` で default browser に dispatch
#   - Linux: `xdg-open <path>` (xdg-utils 必須)
#   - Windows (Git Bash / MSYS): `start "" <path>`
#   - 不明な OS: stderr に警告し、stdout に path を出力 (best-effort)
#
# Skip 条件:
#   - 環境変数 BROWSER=true … CI 環境想定。open は skip し、stdout に path だけ出力
#   - 環境変数 PLAN_BRIEF_NO_OPEN=1 … 明示的な opt-out
#
# Exit code:
#   - 0: open 成功 (または skip 成功)
#   - 2: 引数不正
#   - その他: open コマンドの exit code (best-effort なので fail-soft)

set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <html_path>

引数:
  <html_path>            開きたい HTML ファイルの絶対パスまたは相対パス

環境変数:
  BROWSER=true           open を skip し path だけ stdout 出力
  PLAN_BRIEF_NO_OPEN=1   open を skip し path だけ stdout 出力 (明示 opt-out)
USAGE
  exit 2
}

if [[ $# -lt 1 ]]; then
  echo "ERROR: html_path is required" >&2
  usage
fi

HTML_PATH="$1"

if [[ ! -f "$HTML_PATH" ]]; then
  echo "ERROR: html_path does not exist: $HTML_PATH" >&2
  exit 2
fi

# 絶対パスに正規化 (relative path だと open が誤動作する OS があるため)
case "$HTML_PATH" in
  /*) ABS_PATH="$HTML_PATH" ;;
  *)  ABS_PATH="$(pwd)/$HTML_PATH" ;;
esac

# CI 環境または明示 opt-out なら skip
if [[ "${BROWSER:-}" == "true" || "${PLAN_BRIEF_NO_OPEN:-}" == "1" ]]; then
  printf '%s\n' "$ABS_PATH"
  echo "INFO: skipped browser open (BROWSER=true or PLAN_BRIEF_NO_OPEN=1)" >&2
  exit 0
fi

UNAME_S="$(uname -s 2>/dev/null || echo unknown)"

case "$UNAME_S" in
  Darwin)
    if command -v open >/dev/null 2>&1; then
      open "$ABS_PATH"
      printf '%s\n' "$ABS_PATH"
    else
      echo "WARN: 'open' not found on Darwin (unexpected). Falling back to stdout." >&2
      printf '%s\n' "$ABS_PATH"
    fi
    ;;
  Linux)
    if command -v xdg-open >/dev/null 2>&1; then
      xdg-open "$ABS_PATH" >/dev/null 2>&1 &
      printf '%s\n' "$ABS_PATH"
    else
      echo "WARN: 'xdg-open' not found on Linux. Install xdg-utils to enable auto-open." >&2
      printf '%s\n' "$ABS_PATH"
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    if command -v start >/dev/null 2>&1; then
      start "" "$ABS_PATH"
      printf '%s\n' "$ABS_PATH"
    elif command -v cmd.exe >/dev/null 2>&1; then
      cmd.exe /c start "" "$ABS_PATH"
      printf '%s\n' "$ABS_PATH"
    else
      echo "WARN: 'start' / 'cmd.exe' not found on Windows-like shell. Falling back to stdout." >&2
      printf '%s\n' "$ABS_PATH"
    fi
    ;;
  *)
    echo "WARN: unknown OS ($UNAME_S). Skipping auto-open." >&2
    printf '%s\n' "$ABS_PATH"
    ;;
esac
