#!/bin/bash
# worktree-create.sh — WorktreeCreate hook handler
# Breezing 並列ワーカー用の worktree 環境を初期化する
#
# 入力 (stdin JSON):
#   session_id, cwd, hook_event_name
#
# 設計: WorktreeCreate/Remove は worktree 固有リソースのみ担当
#       SessionEnd はセッション全体リソースを担当（分離設計）

set -euo pipefail

# === stdin から JSON ペイロードを読み取り ===
INPUT=""
if [ ! -t 0 ]; then
  INPUT="$(cat 2>/dev/null)"
fi

# ペイロードが空の場合はスキップ
if [ -z "${INPUT}" ]; then
  echo '{"decision":"approve","reason":"WorktreeCreate: no payload"}'
  exit 0
fi

# === フィールド抽出 ===
SESSION_ID=""
CWD=""

looks_like_hook_decision_json() {
  local value
  value="$(printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

  case "${value}" in
    \{*) ;;
    *) return 1 ;;
  esac

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "${value}" \
      | jq -e 'type == "object" and has("decision") and has("reason")' >/dev/null 2>&1
    return $?
  fi

  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "${value}" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    raise SystemExit(1)

raise SystemExit(0 if isinstance(data, dict) and "decision" in data and "reason" in data else 1)
' >/dev/null 2>&1
    return $?
  fi

  case "${value}" in
    *'"decision"'*'"reason"'*) return 0 ;;
    *) return 1 ;;
  esac
}

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

if [ -z "${CWD}" ]; then
  echo '{"decision":"approve","reason":"WorktreeCreate: no cwd"}'
  exit 0
fi

if looks_like_hook_decision_json "${CWD}"; then
  echo '{"decision":"approve","reason":"WorktreeCreate: invalid cwd"}'
  exit 0
fi

# === worktree 内に .claude/state/ ディレクトリを確保 ===
WORKTREE_STATE_DIR="${CWD}/.claude/state"
mkdir -p "${WORKTREE_STATE_DIR}" 2>/dev/null || true

# === ワーカー ID を記録（Breezing チームでの識別用） ===
WORKTREE_INFO_FILE="${WORKTREE_STATE_DIR}/worktree-info.json"

if command -v jq >/dev/null 2>&1; then
  jq -nc \
    --arg worker_id "${SESSION_ID}" \
    --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg cwd "${CWD}" \
    '{"worker_id":$worker_id,"created_at":$created_at,"cwd":$cwd}' \
    > "${WORKTREE_INFO_FILE}" 2>/dev/null || true
elif command -v python3 >/dev/null 2>&1; then
  python3 -c "
import json, sys
print(json.dumps({
    'worker_id': sys.argv[1],
    'created_at': sys.argv[2],
    'cwd': sys.argv[3]
}, ensure_ascii=False))
" "${SESSION_ID}" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${CWD}" \
    > "${WORKTREE_INFO_FILE}" 2>/dev/null || true
else
  # フォールバック: シンプルな JSON 書き出し
  printf '{"worker_id":"%s","created_at":"%s","cwd":"%s"}\n' \
    "${SESSION_ID//\"/\\\"}" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "${CWD//\"/\\\"}" \
    > "${WORKTREE_INFO_FILE}" 2>/dev/null || true
fi

# === レスポンス ===
echo '{"decision":"approve","reason":"WorktreeCreate: initialized worktree state"}'
exit 0
