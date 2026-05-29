#!/bin/bash
# pretooluse-browser-guide.sh
# MCP ブラウザツール使用時に agent-browser を提案するフック
#
# 対象ツール:
#   - mcp__chrome-devtools__*
#   - mcp__playwright__* / mcp__plugin_playwright__*
#
# 動作:
#   - agent-browser がインストール済みの場合、使用を推奨
#   - ブロックはしない（情報提供のみ）
#
# Input: stdin JSON from Claude Code hooks (matcher で絞り込み済み)
# Output: JSON with hookSpecificOutput format

set -euo pipefail

# stdin から JSON を読み取り
INPUT=""
if [ ! -t 0 ]; then
  INPUT="$(cat 2>/dev/null)"
fi

# 入力がない場合は何もしない
[ -z "$INPUT" ] && exit 0

# agent-browser がインストールされているか確認
if command -v agent-browser &> /dev/null; then
  # 推奨メッセージを出力（hookSpecificOutput 形式）
  # matcher で既に MCP ブラウザツールに絞り込まれているので、追加のツール名チェックは不要
  if command -v jq >/dev/null 2>&1; then
    CONTEXT="💡 **agent-browser を先に試すことを推奨します**

agent-browser は AI エージェント向けに最適化されたブラウザ自動化ツールです。

\`\`\`bash
# 基本的な使い方
agent-browser open <url>
agent-browser snapshot -i -c  # AI 向けスナップショット
agent-browser click @e1        # 要素参照でクリック
\`\`\`

現在の MCP ツールも使用可能ですが、agent-browser の方がシンプルで高速です。

詳細: \`docs/OPTIONAL_PLUGINS.md\`"

    jq -nc --arg ctx "$CONTEXT" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: $ctx
      }
    }'
  else
    # jq がない場合は Python を試行
    if command -v python3 >/dev/null 2>&1; then
      python3 - <<'PY'
import json
context = """💡 **agent-browser を先に試すことを推奨します**

agent-browser は AI エージェント向けに最適化されたブラウザ自動化ツールです。

```bash
# 基本的な使い方
agent-browser open <url>
agent-browser snapshot -i -c  # AI 向けスナップショット
agent-browser click @e1        # 要素参照でクリック
```

現在の MCP ツールも使用可能ですが、agent-browser の方がシンプルで高速です。

詳細: `docs/OPTIONAL_PLUGINS.md`"""
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": context
    }
}))
PY
    fi
  fi
fi

# agent-browser 未インストールまたは出力完了後は正常終了
exit 0
