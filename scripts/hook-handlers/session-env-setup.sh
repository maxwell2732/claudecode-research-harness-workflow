#!/bin/bash
# session-env-setup.sh
# SessionStart フックハンドラ: CLAUDE_ENV_FILE を活用してハーネス環境変数を設定
#
# セッション開始時に以下の環境変数を CLAUDE_ENV_FILE に書き出す:
#   HARNESS_VERSION          - ハーネスのバージョン (VERSION ファイルから取得)
#   HARNESS_EFFORT_DEFAULT   - デフォルト effort レベル (medium)
#   HARNESS_AGENT_TYPE       - エージェントタイプ (BREEZING_ROLE または "solo")
#   HARNESS_BREEZING_SESSION_ID - Breezing セッション ID (存在する場合)
#   HARNESS_IS_REMOTE           - クラウドセッション検出 (CLAUDE_CODE_REMOTE から取得)
#
# Usage: bash session-env-setup.sh
# Hook event: SessionStart

set -euo pipefail

# === 設定 ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# CLAUDE_ENV_FILE が設定されていない場合は何もしない
if [ -z "${CLAUDE_ENV_FILE:-}" ]; then
  exit 0
fi

# VERSION ファイルからバージョンを取得
HARNESS_VERSION="unknown"
if [ -f "${PLUGIN_ROOT}/VERSION" ]; then
  HARNESS_VERSION="$(cat "${PLUGIN_ROOT}/VERSION" | tr -d '[:space:]')"
fi

# エージェントタイプを決定
HARNESS_AGENT_TYPE="${BREEZING_ROLE:-solo}"

# Breezing セッション ID (存在する場合)
HARNESS_BREEZING_SESSION_ID="${BREEZING_SESSION_ID:-}"

# クラウドセッション検出
HARNESS_IS_REMOTE="${CLAUDE_CODE_REMOTE:-false}"

# CLAUDE_ENV_FILE に書き出す (既存のハーネス変数を上書き)
{
  echo "HARNESS_VERSION=${HARNESS_VERSION}"
  echo "HARNESS_EFFORT_DEFAULT=medium"
  echo "HARNESS_AGENT_TYPE=${HARNESS_AGENT_TYPE}"
  echo "HARNESS_IS_REMOTE=${HARNESS_IS_REMOTE}"
  if [ -n "${HARNESS_BREEZING_SESSION_ID}" ]; then
    echo "HARNESS_BREEZING_SESSION_ID=${HARNESS_BREEZING_SESSION_ID}"
  fi
} >> "${CLAUDE_ENV_FILE}"

exit 0
