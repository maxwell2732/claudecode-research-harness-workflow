#!/bin/bash
# config-change.sh
# ConfigChange フックハンドラ（CC 2.1.49+）
#
# 設定ファイル変更時に発火する。breezing アクティブ時のみタイムラインに記録する。
# Stop をブロックしない（常に {"ok":true} を返す）。
#
# Input:  stdin (JSON: { file_path, change_type, ... })
# Output: {"ok": true}

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

TIMELINE_FILE="${PROJECT_ROOT}/.claude/state/breezing-timeline.jsonl"
BREEZING_STATE_FILE="${PROJECT_ROOT}/.claude/state/breezing.json"

# jq がなければ即座に ok を返す
if ! command -v jq &> /dev/null; then
  echo '{"ok":true}'
  exit 0
fi

# breezing がアクティブかどうか確認
BREEZING_ACTIVE=false
if [ -f "$BREEZING_STATE_FILE" ]; then
  BREEZING_STATUS=$(jq -r '.status // "inactive"' "$BREEZING_STATE_FILE" 2>/dev/null || echo "inactive")
  if [ "$BREEZING_STATUS" = "active" ] || [ "$BREEZING_STATUS" = "running" ]; then
    BREEZING_ACTIVE=true
  fi
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
if [ ! -t 0 ]; then
  if [ -n "$_TIMEOUT" ]; then
    PAYLOAD=$($_TIMEOUT 5 head -c 65536 2>/dev/null || true)
  else
    # timeout 未搭載: dd でバイト数上限を保証（POSIX 標準）
    PAYLOAD=$(dd bs=65536 count=1 2>/dev/null || true)
  fi
fi

# breezing アクティブ時のみタイムラインに記録
if [ "$BREEZING_ACTIVE" = true ] && [ -n "$PAYLOAD" ]; then
  STATE_DIR="${PROJECT_ROOT}/.claude/state"
  mkdir -p "$STATE_DIR" 2>/dev/null || true

  # file_path をリポジトリ相対パスに正規化（ユーザー名等を隠蔽）
  RAW_PATH=$(echo "$PAYLOAD" | jq -r '.file_path // "unknown"' 2>/dev/null || echo "unknown")
  if [ "$RAW_PATH" != "unknown" ] && [ -n "$PROJECT_ROOT" ]; then
    FILE_PATH="${RAW_PATH#"$PROJECT_ROOT"/}"
  else
    FILE_PATH="$RAW_PATH"
  fi
  CHANGE_TYPE=$(echo "$PAYLOAD" | jq -r '.change_type // "modified"' 2>/dev/null || echo "modified")
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")

  EVENT=$(jq -n \
    --arg ts "$TIMESTAMP" \
    --arg fp "$FILE_PATH" \
    --arg ct "$CHANGE_TYPE" \
    '{type: "config_change", timestamp: $ts, file_path: $fp, change_type: $ct}' 2>/dev/null || true)

  if [ -n "$EVENT" ]; then
    echo "$EVENT" >> "$TIMELINE_FILE" 2>/dev/null || true
  fi
fi

echo '{"ok":true}'
exit 0
