#!/usr/bin/env bash
# scripts/cross-project-audit-log.sh
# Phase 65.3.6 - Cross-project search 監査ログ append
#
# Purpose:
#   Cross-project search が走った時に .claude/state/audit/cross-project-search.jsonl
#   に 1 行追加する (append-only JSON Lines)。プライバシー保護のため、実際の
#   クエリ文字列は記録せず sha256 hash のみ。
#
# Usage:
#   cross-project-audit-log.sh \
#     --group <name> \
#     --members <csv> \
#     --query-hash <sha256-hex> \
#     --dict-count <int> \
#     --ner-count <int> \
#     --passed-final-scan <true|false> \
#     [--out <jsonl-path>]
#
# Schema: cross-project-audit.v1
#   {
#     schema_version: "cross-project-audit.v1",
#     timestamp: <ISO8601 UTC>,
#     group_name: <string>,
#     member_projects: [<string>, ...],
#     query_hash: <sha256 hex 64 chars>,
#     redaction_count: {dict: <int>, ner: <int>},
#     output_passed_final_scan: <bool>
#   }
#
# Default --out: $REPO_ROOT/.claude/state/audit/cross-project-search.jsonl
#   (ディレクトリは存在しない場合自動作成)
#
# Exit code: 0=success, 2=usage error, 3=runtime error

set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage:
  cross-project-audit-log.sh \
    --group <name> \
    --members <csv> \
    --query-hash <sha256-hex> \
    --dict-count <int> \
    --ner-count <int> \
    --passed-final-scan <true|false> \
    [--out <jsonl-path>]

Required:
  --group <name>             cross-project group 名
  --members <csv>            comma-separated member project 名のリスト (例: "p1,p2,p3")
  --query-hash <hex>         クエリ文字列の sha256 hash (生クエリは記録しない)
  --dict-count <int>         dict-redaction でヒットした件数
  --ner-count <int>          NER-redaction でヒットした件数
  --passed-final-scan <bool> Layer 3 final scan を passed=true / failed=false

Optional:
  --out <jsonl-path>         出力先 (default: .claude/state/audit/cross-project-search.jsonl)

Exit code: 0=success / 2=usage error / 3=runtime error
USAGE
  exit 2
}

GROUP=""
MEMBERS_CSV=""
QUERY_HASH=""
DICT_COUNT=""
NER_COUNT=""
PASSED_FINAL_SCAN=""
OUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --group)              GROUP="${2:-}";              shift 2 ;;
    --members)            MEMBERS_CSV="${2:-}";        shift 2 ;;
    --query-hash)         QUERY_HASH="${2:-}";         shift 2 ;;
    --dict-count)         DICT_COUNT="${2:-}";         shift 2 ;;
    --ner-count)          NER_COUNT="${2:-}";          shift 2 ;;
    --passed-final-scan)  PASSED_FINAL_SCAN="${2:-}";  shift 2 ;;
    --out)                OUT_PATH="${2:-}";           shift 2 ;;
    -h|--help)            usage ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage ;;
  esac
done

# 必須引数チェック
for var_name in GROUP MEMBERS_CSV QUERY_HASH DICT_COUNT NER_COUNT PASSED_FINAL_SCAN; do
  if [[ -z "${!var_name}" ]]; then
    echo "ERROR: --${var_name,,} は必須です (got empty)" >&2
    usage
  fi
done

# 検証
if ! [[ "$DICT_COUNT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --dict-count は非負整数 (got: $DICT_COUNT)" >&2
  exit 2
fi
if ! [[ "$NER_COUNT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --ner-count は非負整数 (got: $NER_COUNT)" >&2
  exit 2
fi
case "$PASSED_FINAL_SCAN" in
  true|false) ;;
  *) echo "ERROR: --passed-final-scan must be 'true' or 'false' (got: $PASSED_FINAL_SCAN)" >&2; exit 2 ;;
esac
# query_hash は 64 chars hex を期待
if ! [[ "$QUERY_HASH" =~ ^[0-9a-fA-F]{64}$ ]]; then
  echo "ERROR: --query-hash must be sha256 hex (64 chars, got length=${#QUERY_HASH})" >&2
  exit 2
fi

# default out path
if [[ -z "$OUT_PATH" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
  OUT_PATH="${REPO_ROOT}/.claude/state/audit/cross-project-search.jsonl"
fi

# 親ディレクトリを作成
OUT_DIR="$(dirname "$OUT_PATH")"
mkdir -p "$OUT_DIR"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required" >&2
  exit 3
fi

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# CSV → JSON array (空文字は [] にする)
if [[ -z "$MEMBERS_CSV" ]]; then
  MEMBERS_JSON='[]'
else
  MEMBERS_JSON="$(printf '%s' "$MEMBERS_CSV" | awk -F',' '{
    printf "[";
    for (i=1; i<=NF; i++) {
      gsub(/^[ \t]+|[ \t]+$/, "", $i);
      if (i>1) printf ",";
      gsub(/"/, "\\\"", $i);
      printf "\"%s\"", $i;
    }
    printf "]";
  }')"
fi

# JSON line を組み立て (compact、改行なし)
LINE="$(jq -n -c \
  --arg ts "$TIMESTAMP" \
  --arg group "$GROUP" \
  --argjson members "$MEMBERS_JSON" \
  --arg hash "$QUERY_HASH" \
  --argjson dict "$DICT_COUNT" \
  --argjson ner "$NER_COUNT" \
  --argjson passed "$PASSED_FINAL_SCAN" \
  '{
    schema_version: "cross-project-audit.v1",
    timestamp: $ts,
    group_name: $group,
    member_projects: $members,
    query_hash: $hash,
    redaction_count: {dict: $dict, ner: $ner},
    output_passed_final_scan: $passed
  }')"

# append 1 行
printf '%s\n' "$LINE" >> "$OUT_PATH"

# stderr に audit summary
echo "audit logged: group=$GROUP, members=$(jq -r 'length' <<< "$MEMBERS_JSON") projects, dict=$DICT_COUNT, ner=$NER_COUNT, passed=$PASSED_FINAL_SCAN -> $OUT_PATH" >&2

exit 0
