#!/usr/bin/env bash
# scripts/progress-past-judgments.sh
# Phase 65.4.4 - Progress Tracker 「過去の判断パターン」 read side
#
# Purpose:
#   alert kind と現プロジェクト名で過去の judgment 履歴を集計し、
#   「過去 N 件中 M 件で同様の提案を断っています」を JSON 出力する。
#
# Usage:
#   progress-past-judgments.sh \
#     --alert-kind <kind> \
#     --project <name> \
#     --records-file <jsonl-path>      # mock 用 / skill 経由の MCP search 結果
#     [--cross-project-group <name>]   # default OFF (Phase 65.3.5 と同じ flag mechanism)
#
# Input record format (JSONL of alert-judgment.v1):
#   {"data": {
#      "alert_kind": "scope-creep"|"time-overrun"|...,
#      "decision":   "follow_suggestion"|"reject_suggestion"|"ignore",
#      "timestamp":  ISO8601,
#      "reasoning":  string,
#      "project":    string
#   }}
#
# Output schema:
#   {
#     alert_kind:         <string>,
#     project:            <string>,
#     cross_project_used: <bool>,
#     total_count:        <int>,
#     rejected_count:     <int>,    # decision == "reject_suggestion"
#     rejection_rate_pct: <int>,    # 0-100
#     top_3_judgments:    [{decision, reasoning, timestamp}, ...]
#   }
#
# Default behavior (cross-project default OFF):
#   --cross-project-group なし → records-file の records を project filter してから集計
#   --cross-project-group あり → project filter 無効化 (records 全件集計)
#
# Exit code: 0=success / 1=runtime error / 2=usage error

set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage: progress-past-judgments.sh \
  --alert-kind <kind> \
  --project <name> \
  --records-file <jsonl-path> \
  [--cross-project-group <name>]

Required:
  --alert-kind <kind>        scope-creep|time-overrun|repeated-failure|cost-warning|high-risk-file
  --project <name>           現プロジェクト名
  --records-file <path>      mock 入力 (JSONL of alert-judgment.v1)
                              本来は skill 経由で MCP search 結果を渡す

Optional:
  --cross-project-group <name>  default OFF (現プロジェクトのみ)
                                 指定時は project filter を解除し全 records 集計

Exit: 0=success / 1=runtime error / 2=usage error
USAGE
  exit 2
}

ALERT_KIND=""
PROJECT=""
RECORDS_FILE=""
CROSS_GROUP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --alert-kind)            ALERT_KIND="${2:-}"; shift 2 ;;
    --project)               PROJECT="${2:-}"; shift 2 ;;
    --records-file)          RECORDS_FILE="${2:-}"; shift 2 ;;
    --cross-project-group)   CROSS_GROUP="${2:-}"; shift 2 ;;
    -h|--help)               usage ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage ;;
  esac
done

if [[ -z "$ALERT_KIND" || -z "$PROJECT" || -z "$RECORDS_FILE" ]]; then
  echo "ERROR: --alert-kind, --project, --records-file are required" >&2
  usage
fi

# alert-kind 列挙値検証
case "$ALERT_KIND" in
  scope-creep|time-overrun|repeated-failure|cost-warning|high-risk-file) ;;
  *)
    echo "ERROR: --alert-kind must be one of: scope-creep|time-overrun|repeated-failure|cost-warning|high-risk-file (got: $ALERT_KIND)" >&2
    exit 2
    ;;
esac

if [[ ! -f "$RECORDS_FILE" ]]; then
  echo "ERROR: records-file not found: $RECORDS_FILE" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required" >&2
  exit 1
fi

CROSS_USED="false"
if [[ -n "$CROSS_GROUP" ]]; then
  CROSS_USED="true"
fi

# JSONL を 1 行ずつ jq で filter
# - alert_kind が一致
# - cross-project OFF なら project が一致
# - decision が follow_suggestion / reject_suggestion / ignore のいずれか

if [[ "$CROSS_USED" == "true" ]]; then
  # cross-project ON: project filter 解除
  FILTERED="$(jq -c --arg ak "$ALERT_KIND" '
    select(.data.alert_kind == $ak)
  ' "$RECORDS_FILE" 2>/dev/null || true)"
else
  # default: project 一致のみ
  FILTERED="$(jq -c --arg ak "$ALERT_KIND" --arg proj "$PROJECT" '
    select(.data.alert_kind == $ak and .data.project == $proj)
  ' "$RECORDS_FILE" 2>/dev/null || true)"
fi

# 集計
TOTAL=0
REJECTED=0
TOP_3="[]"

if [[ -n "$FILTERED" ]]; then
  # 件数 (grep -c は 0 件時に exit 1 で "0" を出力する。
  # `|| echo 0` を付けると "0\n0" になるため、`|| true` で exit code を抑える)
  TOTAL=$(printf '%s\n' "$FILTERED" | grep -c '^{' || true)
  REJECTED=$(printf '%s\n' "$FILTERED" | jq -c 'select(.data.decision == "reject_suggestion")' 2>/dev/null | grep -c '^{' || true)
  # 数値以外になるケースを抑える
  [[ "$TOTAL" =~ ^[0-9]+$ ]] || TOTAL=0
  [[ "$REJECTED" =~ ^[0-9]+$ ]] || REJECTED=0

  # top 3 (timestamp 降順 = 新しい順)
  TOP_3=$(printf '%s\n' "$FILTERED" | jq -s -c '
    sort_by(.data.timestamp) | reverse | .[0:3] | map({
      decision:  .data.decision,
      reasoning: (.data.reasoning // ""),
      timestamp: .data.timestamp
    })
  ' 2>/dev/null || echo '[]')
fi

# rejection rate %
RATE=0
if [[ "$TOTAL" -gt 0 ]]; then
  RATE=$(( REJECTED * 100 / TOTAL ))
fi

jq -n \
  --arg ak "$ALERT_KIND" \
  --arg proj "$PROJECT" \
  --argjson cross "$CROSS_USED" \
  --argjson total "$TOTAL" \
  --argjson rejected "$REJECTED" \
  --argjson rate "$RATE" \
  --argjson top3 "$TOP_3" \
  '{
    alert_kind:         $ak,
    project:            $proj,
    cross_project_used: $cross,
    total_count:        $total,
    rejected_count:     $rejected,
    rejection_rate_pct: $rate,
    top_3_judgments:    $top3
  }'

exit 0
