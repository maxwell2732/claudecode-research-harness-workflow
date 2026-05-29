#!/bin/bash
# terminal-notify.sh
# CC 2.1.141+ hook JSON output `terminalSequence` フィールドを構築する共有ヘルパー
# HARNESS_TERMINAL_NOTIFY env で opt-in (詳細: .claude/rules/hooks-2.1.139-plus.md)
#
# Usage: source 後に build_terminal_sequence "<title>" "<body>" を呼ぶと
#        OSC sequence 文字列を stdout に出力する。env 未設定なら空文字列を返す。
#
# Env: HARNESS_TERMINAL_NOTIFY (optional)
#   unset / "0" : sequence を出力しない
#   "1" / "bell" : BEL (\x07)
#   "title"     : OSC 0 window title 更新
#   "osc9"      : OSC 9 macOS / iTerm 通知
#   "notify"    : OSC 777 KDE/GNOME desktop notification
#
# Security:
#   - title / body から制御文字を除去 (terminal corruption 防止)
#   - 非 ASCII の印字可能文字は通すが、ESC / BEL / ST 等を含めない

set -euo pipefail

# Strip 制御文字 (0x00-0x1F, 0x7F) を除去する
# Args:
#   $1: 入力文字列
# Stdout: 制御文字を除いた文字列
_terminal_notify_sanitize() {
  # printf を使うと \xXX を解釈してしまうので、tr で安全に除去
  printf '%s' "${1:-}" | tr -d '\000-\037\177' 2>/dev/null || true
}

# terminal sequence を構築
# Args:
#   $1: title (例: "Build complete")
#   $2: body (optional, OSC 777 でのみ使用)
# Stdout: 構築された sequence 文字列 (escaping 済み JSON-safe)
build_terminal_sequence() {
  local mode="${HARNESS_TERMINAL_NOTIFY:-}"
  local title body
  title="$(_terminal_notify_sanitize "${1:-}")"
  body="$(_terminal_notify_sanitize "${2:-}")"

  # opt-in 未設定なら空文字列
  case "${mode}" in
    ''|0) return 0 ;;
  esac

  # bell は title を使わないので空でも発火する。
  # それ以外の mode は title が空なら sequence を生成しない。
  if [ "${mode}" != "1" ] && [ "${mode}" != "bell" ] && [ -z "${title}" ]; then
    return 0
  fi

  # ESC = \x1b, BEL = \x07, ST = \x1b\\
  local ESC BEL
  ESC=$'\x1b'
  BEL=$'\x07'

  case "${mode}" in
    1|bell)
      printf '%s' "${BEL}"
      ;;
    title)
      printf '%s]0;%s%s' "${ESC}" "${title}" "${BEL}"
      ;;
    osc9)
      printf '%s]9;%s%s' "${ESC}" "${title}" "${BEL}"
      ;;
    notify)
      # OSC 777;notify;title;body
      if [ -n "${body}" ]; then
        printf '%s]777;notify;%s;%s%s' "${ESC}" "${title}" "${body}" "${BEL}"
      else
        printf '%s]777;notify;%s%s' "${ESC}" "${title}" "${BEL}"
      fi
      ;;
    *)
      # 不明な値は no-op (silent ignore; rule で値域を documented 済み)
      ;;
  esac
}

# 構築済み sequence を JSON-safe な文字列にエンコード
# jq があれば jq を使い、なければ \u escape を行う簡易実装
# Args:
#   $1: sequence (raw bytes)
# Stdout: JSON 文字列リテラル (quote 含まず) を出力
encode_terminal_sequence_json() {
  local seq="${1:-}"
  if [ -z "${seq}" ]; then
    return 0
  fi
  if command -v jq >/dev/null 2>&1; then
    # jq -Rs で raw 入力を JSON 文字列にエンコード (quotes 付き)
    # 後段で quote を除去せず、そのまま JSON value として使う前提で出力
    printf '%s' "${seq}" | jq -Rs . 2>/dev/null || printf '""'
  else
    # 簡易 fallback: ESC / BEL のみ escape
    local out
    out="$(printf '%s' "${seq}" \
      | sed -e 's/\\/\\\\/g' \
            -e 's/"/\\"/g' \
            -e $'s/\x1b/\\\\u001b/g' \
            -e $'s/\x07/\\\\u0007/g')"
    printf '"%s"' "${out}"
  fi
}
