#!/bin/bash
# scripts/plan-brief-record-decision.sh
# Phase 65.1.4 - Plan Brief decision recording (memory write side)
#
# Usage:
#   plan-brief-record-decision.sh --action <approve|revise|question> \
#       --user-request <text> --project <name> \
#       [--chosen-option <text>] [--rejected-options <csv>] \
#       [--reasoning <text>] [--out -|<path>]
#
# 役割:
#   Plan Brief への user 判断 (承認 / 修正依頼 / 質問) を記録する
#   `personal-preference.v1` schema 準拠の payload JSON を出力する。
#   実際の `mcp__harness__harness_mem_ingest` 呼び出しは skill (LLM context)
#   側で行う — このスクリプトは payload を組み立てるだけ。
#
# Schema: personal-preference.v1
#   data: {
#     user_request_hash : sha256 hex (request 原文を hash 化、生 text は記録しない)
#     chosen_option     : string  (approve 時に選ばれた option 名、他は "")
#     rejected_options  : string[]
#     reasoning         : string  (revise 時の理由 / question 時の質問本文)
#     timestamp         : ISO8601 (UTC, Z 終端)
#     project           : string
#     action            : "approve" | "revise" | "question"
#   }
#
# Tags (固定 — DoD b):
#   ["personal-preference", "plan-brief-approval"]
#
# Output: stdout (--out 指定時はそのファイル) に ingest 用 JSON
# Exit code: 0=success, 2=usage error, 3=runtime error

set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 --action <approve|revise|question> \
          --user-request <text> --project <name> \
          [--chosen-option <text>] [--rejected-options <csv>] \
          [--reasoning <text>] [--out -|<path>]

Required:
  --action <approve|revise|question>  user 判断のアクション種別
  --user-request <text>               Plan Brief を起動した request 原文
  --project <name>                    project 名 (basename of toplevel)

Optional:
  --chosen-option <text>              approve 時に選んだ option 名 (default: "")
  --rejected-options <csv>            却下した option を comma で区切る (default: "")
  --reasoning <text>                  revise の理由 / question の本文 (default: "")
  --out -|<path>                      出力先 (- = stdout, default: stdout)

出力: personal-preference.v1 schema 準拠の harness_mem_ingest 用 JSON
USAGE
  exit 2
}

ACTION=""
USER_REQUEST=""
PROJECT=""
CHOSEN_OPTION=""
REJECTED_OPTIONS_CSV=""
REASONING=""
OUT="-"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action)            ACTION="${2:-}";              shift 2 ;;
    --user-request)      USER_REQUEST="${2:-}";        shift 2 ;;
    --project)           PROJECT="${2:-}";             shift 2 ;;
    --chosen-option)     CHOSEN_OPTION="${2:-}";       shift 2 ;;
    --rejected-options)  REJECTED_OPTIONS_CSV="${2:-}";shift 2 ;;
    --reasoning)         REASONING="${2:-}";           shift 2 ;;
    --out)               OUT="${2:-}";                 shift 2 ;;
    -h|--help)           usage ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage ;;
  esac
done

# ---- 必須引数 ----

if [[ -z "$ACTION" || -z "$USER_REQUEST" || -z "$PROJECT" ]]; then
  echo "ERROR: --action, --user-request, --project are required" >&2
  usage
fi

case "$ACTION" in
  approve|revise|question) ;;
  *)
    echo "ERROR: --action must be one of: approve|revise|question (got: $ACTION)" >&2
    exit 2
    ;;
esac

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not found" >&2
  exit 3
fi

# ---- sha256 hex ----
# stdin 経由で request を hash 化。`shasum -a 256` (macOS) と `sha256sum` (Linux) の両対応。

sha256_of_text() {
  local text="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$text" | sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$text" | shasum -a 256 | awk '{print $1}'
  else
    echo "ERROR: neither sha256sum nor shasum found" >&2
    exit 3
  fi
}

USER_REQUEST_HASH="$(sha256_of_text "$USER_REQUEST")"

# ---- rejected_options を array に変換 ----
# csv は単純 split (引用符なし)。要素中に , を入れる必要があれば SKILL.md 側で URL-encode して渡すこと。

if [[ -z "$REJECTED_OPTIONS_CSV" ]]; then
  REJECTED_OPTIONS_JSON='[]'
else
  REJECTED_OPTIONS_JSON="$(printf '%s' "$REJECTED_OPTIONS_CSV" | awk -F',' '{
    printf "[";
    for (i = 1; i <= NF; i++) {
      gsub(/^[ \t]+|[ \t]+$/, "", $i);
      if (i > 1) printf ",";
      gsub(/"/, "\\\"", $i);
      printf "\"%s\"", $i;
    }
    printf "]";
  }')"
fi

# ---- timestamp ----

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ---- payload 組み立て ----

PAYLOAD="$(jq -n \
  --arg hash "$USER_REQUEST_HASH" \
  --arg chosen "$CHOSEN_OPTION" \
  --argjson rejected "$REJECTED_OPTIONS_JSON" \
  --arg reasoning "$REASONING" \
  --arg ts "$TIMESTAMP" \
  --arg proj "$PROJECT" \
  --arg action "$ACTION" \
  '{
    schema: "personal-preference.v1",
    observation_type: "decision",
    tags: ["personal-preference", "plan-brief-approval"],
    project: $proj,
    data: {
      user_request_hash: $hash,
      chosen_option: $chosen,
      rejected_options: $rejected,
      reasoning: $reasoning,
      timestamp: $ts,
      project: $proj,
      action: $action
    }
  }')"

if [[ "$OUT" == "-" || -z "$OUT" ]]; then
  printf '%s\n' "$PAYLOAD"
else
  printf '%s\n' "$PAYLOAD" > "$OUT"
fi
