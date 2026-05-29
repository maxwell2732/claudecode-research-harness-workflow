#!/bin/bash
# posttooluse-clear-pending.sh
# PostToolUse/Skill 時に pending-skills を解消
#
# Usage: PostToolUse hook から自動実行（Skill マッチャー）
# Input: stdin JSON (Claude Code hooks)
# Output: JSON (continue)

set +e

STATE_DIR=".claude/state"
PENDING_DIR="${STATE_DIR}/pending-skills"

# pending ディレクトリが無ければスキップ
[ ! -d "$PENDING_DIR" ] && { echo '{"continue":true}'; exit 0; }

# pending ファイルがあれば全て解消
# （Skill呼び出し = 品質ゲート実行済みとみなす）
PENDING_FILES=$(ls "$PENDING_DIR"/*.pending 2>/dev/null || true)

if [ -n "$PENDING_FILES" ]; then
  for f in $PENDING_FILES; do
    rm -f "$f" 2>/dev/null || true
  done
fi

echo '{"continue":true}'
exit 0
