#!/bin/bash
# stop-session-evaluator.sh
# Stop フックのセッション完了評価
#
# prompt type の代替として、確実に有効な JSON を出力する command type フック。
# セッション状態を検査し、停止を許可 or ブロックの判定を行う。
# CC 2.1.47+: stdin から last_assistant_message を読み取り session.json に記録する。
#
# Input:  stdin (JSON: { stop_hook_active, transcript_path, last_assistant_message, ... })
# Output: {"ok": true} or {"ok": false, "reason": "..."}
#
# Issue: #42 - Stop hook "JSON validation failed" on every turn

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# path-utils.sh の読み込み
if [ -f "${PARENT_DIR}/path-utils.sh" ]; then
  source "${PARENT_DIR}/path-utils.sh"
fi

# detect_project_root が定義されているか確認してから呼び出す
if declare -F detect_project_root > /dev/null 2>&1; then
  PROJECT_ROOT="${PROJECT_ROOT:-$(detect_project_root 2>/dev/null || pwd)}"
else
  PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
fi

STATE_FILE="${PROJECT_ROOT}/.claude/state/session.json"

# jq がなければ即座に ok を返す（安全なフォールバック）
if ! command -v jq &> /dev/null; then
  echo '{"ok":true}'
  exit 0
fi

# ポータブル timeout 検出
_TIMEOUT=""
if command -v timeout > /dev/null 2>&1; then
  _TIMEOUT="timeout"
elif command -v gtimeout > /dev/null 2>&1; then
  _TIMEOUT="gtimeout"
fi

# stdin から Hook ペイロードを読み取る（サイズ制限 + タイムアウト付き）
PAYLOAD=""
if [ -t 0 ]; then
  # stdin が TTY の場合はスキップ（テスト実行時等）
  :
else
  if [ -n "$_TIMEOUT" ]; then
    PAYLOAD=$($_TIMEOUT 5 head -c 65536 2>/dev/null || true)
  else
    # timeout 未搭載: dd でバイト数上限を保証（POSIX 標準）
    PAYLOAD=$(dd bs=65536 count=1 2>/dev/null || true)
  fi
fi

# last_assistant_message のメタデータを session.json に記録（内容はハッシュ化）
if [ -n "$PAYLOAD" ] && [ -f "$STATE_FILE" ]; then
  LAST_MSG=$(echo "$PAYLOAD" | jq -r '.last_assistant_message // ""' 2>/dev/null || true)
  if [ -n "$LAST_MSG" ] && [ "$LAST_MSG" != "null" ]; then
    # メッセージ長とハッシュのみ記録（平文内容は保存しない）
    MSG_LENGTH=${#LAST_MSG}
    # ポータブルハッシュ: shasum (macOS) / sha256sum (Linux) / fallback
    if command -v shasum > /dev/null 2>&1; then
      MSG_HASH=$(printf '%s' "$LAST_MSG" | shasum -a 256 | cut -c1-16)
    elif command -v sha256sum > /dev/null 2>&1; then
      MSG_HASH=$(printf '%s' "$LAST_MSG" | sha256sum | cut -c1-16)
    else
      MSG_HASH="no-hash"
    fi
    # atomic write: mktemp + mv
    STATE_DIR="$(dirname "$STATE_FILE")"
    TMP_FILE=$(mktemp "${STATE_DIR}/session.json.XXXXXX" 2>/dev/null || echo "")
    if [ -n "$TMP_FILE" ]; then
      trap 'rm -f "$TMP_FILE"' EXIT
      jq --argjson len "$MSG_LENGTH" --arg hash "$MSG_HASH" \
        '.last_message_length = $len | .last_message_hash = $hash' \
        "$STATE_FILE" > "$TMP_FILE" 2>/dev/null && mv "$TMP_FILE" "$STATE_FILE" || rm -f "$TMP_FILE"
      trap - EXIT
    fi
  fi
fi

# 状態ファイルがなければ即座に ok を返す
if [ ! -f "$STATE_FILE" ]; then
  echo '{"ok":true}'
  exit 0
fi

# セッション状態を検査
SESSION_STATE=$(jq -r '.state // "unknown"' "$STATE_FILE" 2>/dev/null)

# 既に停止処理済みなら即座に ok
if [ "$SESSION_STATE" = "stopped" ]; then
  echo '{"ok":true}'
  exit 0
fi

# デフォルト: 停止を許可
# ユーザーが明示的に Stop を押した場合、基本的に停止を許可する
echo '{"ok":true}'
exit 0
