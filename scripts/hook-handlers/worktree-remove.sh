#!/bin/bash
# worktree-remove.sh — WorktreeRemove hook handler
# Breezing サブエージェント終了時の worktree 固有リソースをクリーンアップ
#
# 入力 (stdin JSON):
#   session_id, cwd, hook_event_name
#
# 設計: worktree 固有の一時ファイルのみ担当
#       セッション全体のクリーンアップは SessionEnd が担当

set -euo pipefail

# === stdin から JSON ペイロードを読み取り ===
INPUT=""
if [ ! -t 0 ]; then
  INPUT="$(cat 2>/dev/null)"
fi

# ペイロードが空の場合はスキップ
if [ -z "${INPUT}" ]; then
  echo '{"decision":"approve","reason":"WorktreeRemove: no payload"}'
  exit 0
fi

# === フィールド抽出 ===
SESSION_ID=""
CWD=""

if command -v jq >/dev/null 2>&1; then
  _jq_parsed="$(echo "${INPUT}" | jq -r '[
    (.session_id // ""),
    (.cwd // "")
  ] | @tsv' 2>/dev/null)"
  if [ -n "${_jq_parsed}" ]; then
    IFS=$'\t' read -r SESSION_ID CWD <<< "${_jq_parsed}"
  fi
  unset _jq_parsed
elif command -v python3 >/dev/null 2>&1; then
  _parsed="$(echo "${INPUT}" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('session_id', ''))
    print(d.get('cwd', ''))
except:
    print('')
    print('')
" 2>/dev/null)"
  SESSION_ID="$(echo "${_parsed}" | sed -n '1p')"
  CWD="$(echo "${_parsed}" | sed -n '2p')"
fi

if [ -z "${SESSION_ID}" ]; then
  echo '{"decision":"approve","reason":"WorktreeRemove: no session_id"}'
  exit 0
fi

# === worktree 固有の一時ファイルをクリーンアップ ===

# Codex プロンプト一時ファイル（セッション固有のものを優先）
rm -f /tmp/codex-prompt-*.md 2>/dev/null || true

# Harness Codex ログ（セッション固有）
rm -f /tmp/harness-codex-*.log 2>/dev/null || true

# worktree-info.json のクリーンアップ
if [ -n "${CWD}" ] && [ -f "${CWD}/.claude/state/worktree-info.json" ]; then
  rm -f "${CWD}/.claude/state/worktree-info.json" 2>/dev/null || true
fi

# === レスポンス ===
echo '{"decision":"approve","reason":"WorktreeRemove: cleaned up worktree resources"}'
exit 0
