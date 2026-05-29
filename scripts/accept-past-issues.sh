#!/bin/bash
# scripts/accept-past-issues.sh
# Phase 65.2.2 - Acceptance Demo 用 「過去の問題パターン」取得 (read side)
#
# Usage:
#   accept-past-issues.sh --project <name> --task <description>
#                         [--issues-source <path>] [--out -|<path>]
#
# 役割:
#   harness-accept skill が `mcp__harness__harness_mem_search` で
#   patterns.md (P1-P33) と過去の `acceptance-context.v1` record を
#   semantic search した結果を入力に取り、上位 3 件に整形して
#   `past-issue.v1` schema で出力する。
#
# 入力 schema (--issues-source が指す JSON ファイル):
#   {
#     "items": [
#       {
#         "source": "patterns.md|acceptance-record",
#         "pattern_id": "P5" or "AR-2026-05-08",
#         "title": "string",
#         "summary": "string",
#         "relevance_score": 0.85,
#         "verified_in_current_task": true|false
#       },
#       ...
#     ]
#   }
#   --issues-source 省略時は items=[] 扱い (該当なしのケース)。
#
# Project enforcement (DoD b):
#   --project は必須。空文字列 / 未指定は exit 2。
#   cross-project search は本スクリプトでは**呼ばない** (Phase 65.3 で解放)。
#   skill 側で `mcp__harness__harness_mem_search` を `strict_project: true`
#   で呼ぶ前提。
#
# 出力 schema: past-issue.v1
#   {
#     "schema": "past-issue.v1",
#     "items": [
#       {
#         "source": "...", "pattern_id": "...", "title": "...",
#         "summary": "...", "relevance_score": 0.85,
#         "verified_in_current_task": true
#       }
#     ],
#     "project": "...", "task_description": "...",
#     "generated_at": "ISO8601"
#   }
#
# Exit code: 0=success, 2=usage error, 3=runtime error

set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 --project <name> --task <description>
          [--issues-source <path>] [--out -|<path>]

Required:
  --project <name>            project 名 (basename of toplevel)
  --task <description>        現タスクの説明 (semantic search query 相当)

Optional:
  --issues-source <path>      mem search 結果を保持する JSON ファイル
                              (省略時は items=[]、すなわち過去 issue なし)
  --out -|<path>              出力先 (- = stdout, default: stdout)

出力: past-issue.v1 schema 準拠の JSON
USAGE
  exit 2
}

PROJECT=""
TASK=""
ISSUES_SOURCE=""
OUT="-"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)        PROJECT="${2:-}";        shift 2 ;;
    --task)           TASK="${2:-}";           shift 2 ;;
    --issues-source)  ISSUES_SOURCE="${2:-}";  shift 2 ;;
    --out)            OUT="${2:-}";            shift 2 ;;
    -h|--help)        usage ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage ;;
  esac
done

# ---- DoD b: project enforcement ----
if [[ -z "$PROJECT" ]]; then
  echo "ERROR: --project is required (cross-project search is forbidden in Phase 65.2)" >&2
  usage
fi

if [[ -z "$TASK" ]]; then
  echo "ERROR: --task is required" >&2
  usage
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not found" >&2
  exit 3
fi

# ---- 入力 source の正規化 ----
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/accept-past-issues.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
NORM_SRC="$TMP_DIR/source.json"

if [[ -n "$ISSUES_SOURCE" ]]; then
  if [[ ! -f "$ISSUES_SOURCE" ]]; then
    echo "ERROR: --issues-source file not found: $ISSUES_SOURCE" >&2
    exit 3
  fi
  if ! jq -e '.' "$ISSUES_SOURCE" >/dev/null 2>&1; then
    echo "ERROR: --issues-source is not valid JSON: $ISSUES_SOURCE" >&2
    exit 3
  fi
  jq '{ items: (.items // []) }' "$ISSUES_SOURCE" > "$NORM_SRC"
else
  echo '{"items":[]}' > "$NORM_SRC"
fi

# ---- top 3 を relevance_score 降順で抽出 + 既定値補完 ----
# verified_in_current_task が欠けていれば false を補完。
# relevance_score が欠けていれば 0 を補完。

TOP_ITEMS_JSON="$(jq '
  [.items[] | {
    source:                   (.source // ""),
    pattern_id:               (.pattern_id // ""),
    title:                    (.title // ""),
    summary:                  (.summary // ""),
    relevance_score:          (.relevance_score // 0),
    verified_in_current_task: (if has("verified_in_current_task") then .verified_in_current_task else false end)
  }]
  | sort_by(-.relevance_score)
  | .[0:3]
' "$NORM_SRC")"

# ---- 出力 JSON 組み立て ----
GENERATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

OUT_JSON="$(jq -n \
  --arg proj "$PROJECT" \
  --arg task "$TASK" \
  --arg ts "$GENERATED_AT" \
  --argjson items "$TOP_ITEMS_JSON" \
  '{
    schema: "past-issue.v1",
    project: $proj,
    task_description: $task,
    items: $items,
    generated_at: $ts
  }')"

if [[ "$OUT" == "-" || -z "$OUT" ]]; then
  printf '%s\n' "$OUT_JSON"
else
  printf '%s\n' "$OUT_JSON" > "$OUT"
fi
