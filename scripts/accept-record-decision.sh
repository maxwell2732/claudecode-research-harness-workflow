#!/bin/bash
# scripts/accept-record-decision.sh
# Phase 65.2.3 - Acceptance Demo 判断記録 (memory write side)
#
# Usage:
#   accept-record-decision.sh --action <accept|override|reject> \
#       --user-request <text> --project <name> \
#       --recommendation <ship|wait|reject> \
#       [--override-reason <text>] \
#       [--verified-criteria-source <path>] \
#       [--post-launch-concerns <csv>] \
#       [--out -|<path>]
#
# 役割:
#   ユーザーの ship/wait/reject 判断 (Acceptance Demo の recommendation を
#   採用 / override / reject) を記録する `acceptance-decision.v1` schema
#   準拠の payload JSON を出力する。実際の `mcp__harness__harness_mem_ingest`
#   呼び出しは skill (LLM context) 側で行う。
#
# Plan Brief 側との join:
#   `data.user_request_hash` は同じ user request 文字列の sha256 hex で、
#   Phase 65.1.4 の `personal-preference.v1` と完全一致する → mem_graph
#   や mem_search で「プラン → 受け入れ」の完全 trace が取得可能
#
# Action 種別:
#   - accept    : recommendation をそのまま採用 (ship/wait/reject どれでも)
#                 → recommendation_taken = true
#   - override  : recommendation と異なる判断を採用
#                 → recommendation_taken = false, override_reason 必須
#   - reject    : recommendation に関係なく「reject」を最終判断とした
#                 → recommendation_taken = (recommendation == "reject")
#
# Schema: acceptance-decision.v1
#   data: {
#     user_request_hash             : sha256 hex (Plan Brief 側 personal-preference.v1 と join)
#     recommendation_shown          : "ship"|"wait"|"reject"  (Acceptance Demo HTML が示した値)
#     recommendation_taken          : bool                     (採用したかどうか)
#     override_reason               : string                   (override 時のみ非空)
#     verified_criteria_at_decision : [{name, passed, evidence}]
#     post_launch_concerns          : string[]
#     timestamp                     : ISO8601 UTC
#     project                       : string
#     action                        : "accept" | "override" | "reject"
#   }
#
# Tags (固定):
#   ["personal-preference", "acceptance-decision"]
#
# Exit code: 0=success, 2=usage error, 3=runtime error

set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 --action <accept|override|reject> \
          --user-request <text> --project <name> \
          --recommendation <ship|wait|reject> \
          [--override-reason <text>] \
          [--verified-criteria-source <path>] \
          [--post-launch-concerns <csv>] \
          [--out -|<path>]

Required:
  --action <accept|override|reject>      ユーザー判断のアクション種別
  --user-request <text>                  Plan Brief を起動した request 原文
  --project <name>                       project 名
  --recommendation <ship|wait|reject>    Acceptance Demo HTML が示した recommendation

Optional:
  --override-reason <text>               override / reject 時の理由 (default: "")
                                          action=override のときは required
  --verified-criteria-source <path>      Acceptance Demo の verified_criteria JSON
                                          (default: 空配列)
                                          形式: {"items": [{"name", "passed", "evidence"}]}
  --post-launch-concerns <csv>           ローンチ後懸念事項 (default: "")
  --out -|<path>                         出力先 (- = stdout, default: stdout)

出力: acceptance-decision.v1 schema 準拠の harness_mem_ingest 用 JSON
USAGE
  exit 2
}

ACTION=""
USER_REQUEST=""
PROJECT=""
RECOMMENDATION=""
OVERRIDE_REASON=""
VERIFIED_CRITERIA_SOURCE=""
POST_LAUNCH_CONCERNS_CSV=""
OUT="-"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action)                    ACTION="${2:-}";                    shift 2 ;;
    --user-request)              USER_REQUEST="${2:-}";              shift 2 ;;
    --project)                   PROJECT="${2:-}";                   shift 2 ;;
    --recommendation)            RECOMMENDATION="${2:-}";            shift 2 ;;
    --override-reason)           OVERRIDE_REASON="${2:-}";           shift 2 ;;
    --verified-criteria-source)  VERIFIED_CRITERIA_SOURCE="${2:-}";  shift 2 ;;
    --post-launch-concerns)      POST_LAUNCH_CONCERNS_CSV="${2:-}";  shift 2 ;;
    --out)                       OUT="${2:-}";                       shift 2 ;;
    -h|--help)                   usage ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage ;;
  esac
done

# ---- 必須引数 ----

if [[ -z "$ACTION" || -z "$USER_REQUEST" || -z "$PROJECT" || -z "$RECOMMENDATION" ]]; then
  echo "ERROR: --action, --user-request, --project, --recommendation are required" >&2
  usage
fi

case "$ACTION" in
  accept|override|reject) ;;
  *)
    echo "ERROR: --action must be one of: accept|override|reject (got: $ACTION)" >&2
    exit 2
    ;;
esac

case "$RECOMMENDATION" in
  ship|wait|reject) ;;
  *)
    echo "ERROR: --recommendation must be one of: ship|wait|reject (got: $RECOMMENDATION)" >&2
    exit 2
    ;;
esac

# action=override で override_reason 必須
if [[ "$ACTION" == "override" && -z "$OVERRIDE_REASON" ]]; then
  echo "ERROR: --override-reason is required when --action override" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not found" >&2
  exit 3
fi

# ---- recommendation_taken 判定 ----
#   accept    → true
#   override  → false
#   reject    → (recommendation == "reject")  ← rec が reject ならユーザーも reject = 採用
case "$ACTION" in
  accept)
    RECOMMENDATION_TAKEN="true"
    ;;
  override)
    RECOMMENDATION_TAKEN="false"
    ;;
  reject)
    if [[ "$RECOMMENDATION" == "reject" ]]; then
      RECOMMENDATION_TAKEN="true"
    else
      RECOMMENDATION_TAKEN="false"
    fi
    ;;
esac

# ---- sha256 hex (Phase 65.1.4 と完全一致するロジック) ----

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

# ---- verified_criteria_at_decision の正規化 ----

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/accept-record-decision.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
NORM_CRITERIA="$TMP_DIR/criteria.json"

if [[ -n "$VERIFIED_CRITERIA_SOURCE" ]]; then
  if [[ ! -f "$VERIFIED_CRITERIA_SOURCE" ]]; then
    echo "ERROR: --verified-criteria-source file not found: $VERIFIED_CRITERIA_SOURCE" >&2
    exit 3
  fi
  if ! jq -e '.' "$VERIFIED_CRITERIA_SOURCE" >/dev/null 2>&1; then
    echo "ERROR: --verified-criteria-source is not valid JSON" >&2
    exit 3
  fi
  jq '[.items[]? | {
    name:     (.name // ""),
    passed:   (.passed // false),
    evidence: (.evidence // "")
  }]' "$VERIFIED_CRITERIA_SOURCE" > "$NORM_CRITERIA"
else
  echo '[]' > "$NORM_CRITERIA"
fi

# ---- post_launch_concerns を array に変換 ----

if [[ -z "$POST_LAUNCH_CONCERNS_CSV" ]]; then
  POST_LAUNCH_CONCERNS_JSON='[]'
else
  POST_LAUNCH_CONCERNS_JSON="$(printf '%s' "$POST_LAUNCH_CONCERNS_CSV" | awk -F',' '{
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
  --arg rec "$RECOMMENDATION" \
  --argjson taken "$RECOMMENDATION_TAKEN" \
  --arg override "$OVERRIDE_REASON" \
  --slurpfile criteria "$NORM_CRITERIA" \
  --argjson concerns "$POST_LAUNCH_CONCERNS_JSON" \
  --arg ts "$TIMESTAMP" \
  --arg proj "$PROJECT" \
  --arg action "$ACTION" \
  '{
    schema: "acceptance-decision.v1",
    observation_type: "decision",
    tags: ["personal-preference", "acceptance-decision"],
    project: $proj,
    data: {
      user_request_hash: $hash,
      recommendation_shown: $rec,
      recommendation_taken: $taken,
      override_reason: $override,
      verified_criteria_at_decision: ($criteria | first),
      post_launch_concerns: $concerns,
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
