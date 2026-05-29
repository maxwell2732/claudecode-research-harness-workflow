#!/bin/bash
# pretooluse-inbox-check.sh
# PreToolUse Hook: ツール実行前に未読メッセージをチェック
#
# Write|Edit 実行前に他セッションからのメッセージを確認し、
# 重要な変更通知を見逃さないようにする
#
# 入力: stdin から JSON
# 出力: JSON (hookSpecificOutput)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===== 設定 =====
SESSIONS_DIR=".claude/sessions"
BROADCAST_FILE="${SESSIONS_DIR}/broadcast.md"
SESSION_FILE=".claude/state/session.json"
CHECK_INTERVAL_FILE="${SESSIONS_DIR}/.last_inbox_check"
CHECK_INTERVAL=300  # 5分ごとにチェック（頻繁すぎる通知を防ぐ）

# ===== stdin から JSON 入力を読み取り =====
INPUT=""
if [ -t 0 ]; then
  : # stdin が TTY の場合は入力なし
else
  INPUT=$(cat 2>/dev/null || true)
fi

# ===== チェック間隔の確認 =====
current_time=$(date +%s)
last_check=0

if [ -f "$CHECK_INTERVAL_FILE" ]; then
  last_check=$(cat "$CHECK_INTERVAL_FILE" 2>/dev/null || echo "0")
fi

time_since_check=$((current_time - last_check))

# チェック間隔内の場合はスキップ（何も出力しない → 権限判定に影響しない）
if [ "$time_since_check" -lt "$CHECK_INTERVAL" ]; then
  exit 0
fi

# チェック時刻を更新
mkdir -p "$SESSIONS_DIR"
echo "$current_time" > "$CHECK_INTERVAL_FILE"

# ===== 未読メッセージをチェック =====
if [ ! -f "$BROADCAST_FILE" ]; then
  exit 0
fi

# inbox-check スクリプトを使用
UNREAD_COUNT=$(bash "$SCRIPT_DIR/session-inbox-check.sh" --count 2>/dev/null || echo "0")

if [ "$UNREAD_COUNT" -gt 0 ]; then
  # 未読メッセージの内容を取得（最大5件）
  # session-inbox-check.sh の出力から実際のメッセージ行を抽出
  INBOX_MESSAGES=$(bash "$SCRIPT_DIR/session-inbox-check.sh" 2>/dev/null | grep -E '^\[' | head -5 || echo "")

  if [ -n "$INBOX_MESSAGES" ]; then
    bash "$SCRIPT_DIR/session-inbox-check.sh" --mark >/dev/null 2>/dev/null || true

    # メッセージ内容をエスケープ処理
    ESCAPED_MESSAGES=$(echo "$INBOX_MESSAGES" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//')

    # メッセージ内容を直接表示（permissionDecision: "allow" で権限判定に影響しない）
    cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","additionalContext":"📨 他セッションからのメッセージ ${UNREAD_COUNT}件:\\n---\\n${ESCAPED_MESSAGES}\\n---"}}
EOF
  else
    # メッセージ抽出に失敗した場合はフォールバック
    cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","additionalContext":"📨 他セッションからのメッセージが ${UNREAD_COUNT}件 あります"}}
EOF
  fi
else
  # 未読なし → 何も出力しない（権限判定に影響しない）
  :
fi

exit 0
