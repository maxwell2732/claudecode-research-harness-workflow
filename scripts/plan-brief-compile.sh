#!/bin/bash
# scripts/plan-brief-compile.sh
# Phase 65.1.3 - Plan Brief context compilation logic
#
# Usage:
#   plan-brief-compile.sh --query <text> --project <name> [--mem-results <path>]
#                         [--understanding <text>] [--out -|<path>]
#
# 役割:
#   ユーザー request と harness-mem search 結果から plan-brief-context.v1
#   schema 準拠の JSON を組み立てる。confidence は以下の 3 成分の合計:
#     (1) 過去類似案件の cc:完了率   … 40 点満点
#     (2) DoD / request の数値要件含有率 … 30 点満点
#     (3) 関連 D/P 件数の有意性        … 30 点満点
#   各成分の根拠を confidence_evidence (string[]) に literal な数値で残す。
#
# Mem search 結果の入力 schema (--mem-results が指す JSON ファイル):
#   {
#     "decisions":     [{"id": "D22", "title": "...", "relevance": "..."}, ...],
#     "patterns":      [{"id": "P5",  "title": "...", "relevance": "..."}, ...],
#     "plans_archive": [{"phase": "Phase 41", "archive_path": "...",
#                         "outcome": "cc:完了|cc:WIP|cc:TODO|skipped",
#                         "relevance": "..."}, ...]
#   }
# --mem-results が省略された場合は全て空配列扱い (confidence は DoD / D-P 成分のみ)。
#
# 出力: stdout (--out が指定されたらそのファイル) に plan-brief-context.v1 JSON
# Exit code: 0=success, 2=usage error, 3=invalid input

set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 --query <text> --project <name> [--mem-results <path>]
          [--understanding <text>] [--out -|<path>]

引数:
  --query <text>              ユーザー request の本文 (required)
  --project <name>            project 名 (required, basename of toplevel)
  --mem-results <path>        harness-mem search 結果の JSON ファイル (optional)
  --understanding <text>      Claude の理解 (optional, default: "(まだ未着手)")
  --out -|<path>              出力先 (- = stdout, default: stdout)

出力: plan-brief-context.v1 schema 準拠の JSON
USAGE
  exit 2
}

QUERY=""
PROJECT=""
MEM_RESULTS=""
UNDERSTANDING="(まだ未着手)"
OUT="-"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --query)         QUERY="${2:-}";         shift 2 ;;
    --project)       PROJECT="${2:-}";       shift 2 ;;
    --mem-results)   MEM_RESULTS="${2:-}";   shift 2 ;;
    --understanding) UNDERSTANDING="${2:-}"; shift 2 ;;
    --out)           OUT="${2:-}";           shift 2 ;;
    -h|--help)       usage ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage ;;
  esac
done

if [[ -z "$QUERY" || -z "$PROJECT" ]]; then
  echo "ERROR: --query and --project are required" >&2
  usage
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not found" >&2
  exit 3
fi

# ---- mem results を normalize する (省略時は空配列) ----

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/plan-brief-compile.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
NORM_MEM="$TMP_DIR/mem.json"

if [[ -n "$MEM_RESULTS" ]]; then
  if [[ ! -f "$MEM_RESULTS" ]]; then
    echo "ERROR: --mem-results file not found: $MEM_RESULTS" >&2
    exit 3
  fi
  if ! jq -e '.' "$MEM_RESULTS" >/dev/null 2>&1; then
    echo "ERROR: --mem-results is not valid JSON: $MEM_RESULTS" >&2
    exit 3
  fi
  jq '{
    decisions:     (.decisions     // []),
    patterns:      (.patterns      // []),
    plans_archive: (.plans_archive // [])
  }' "$MEM_RESULTS" > "$NORM_MEM"
else
  echo '{"decisions":[],"patterns":[],"plans_archive":[]}' > "$NORM_MEM"
fi

# ---- 成分 (1): 過去類似案件の cc:完了率 (40 点満点) ----

PAST_TOTAL="$(jq '.plans_archive | length' "$NORM_MEM")"
PAST_DONE="$(jq '[.plans_archive[] | select(.outcome == "cc:完了")] | length' "$NORM_MEM")"

if [[ "$PAST_TOTAL" -eq 0 ]]; then
  SCORE_PAST=0
  EVIDENCE_PAST="過去類似案件: 0 件 (シグナル不足)"
else
  # 40 * (PAST_DONE / PAST_TOTAL) を四捨五入
  SCORE_PAST=$(awk -v d="$PAST_DONE" -v t="$PAST_TOTAL" 'BEGIN { printf "%.0f", 40.0 * d / t }')
  RATE=$(awk -v d="$PAST_DONE" -v t="$PAST_TOTAL" 'BEGIN { printf "%.0f", 100.0 * d / t }')
  EVIDENCE_PAST="過去類似案件 ${PAST_TOTAL} 件中 ${PAST_DONE} 件 (${RATE}%) が cc:完了"
fi

# ---- 成分 (2): DoD / request の数値要件含有率 (30 点満点) ----

# request を「。」「\n」で文に分割し、各文に数字を含むかを判定。
# `tr` は LC_ALL=C の環境で UTF-8 句点をバイト列として壊すため、
# 必須依存の jq で Unicode-safe に集計する。

SENTENCE_STATS_JSON="$(jq -n --arg q "$QUERY" '
  ($q
   | gsub("。|\\n"; "\n")
   | split("\n")
   | map(gsub("^[[:space:]]+|[[:space:]]+$"; ""))
   | map(select(length > 0))) as $sentences
  | {
      total: ($sentences | length),
      with_num: ($sentences | map(select(test("[0-9]"))) | length)
    }
')"
NUM_SENTENCES_TOTAL="$(printf '%s\n' "$SENTENCE_STATS_JSON" | jq -r '.total')"
NUM_SENTENCES_WITH_NUM="$(printf '%s\n' "$SENTENCE_STATS_JSON" | jq -r '.with_num')"

if [[ "$NUM_SENTENCES_TOTAL" -eq 0 ]]; then
  SCORE_DOD=0
  EVIDENCE_DOD="request が空 (DoD シグナルなし)"
else
  SCORE_DOD=$(awk -v n="$NUM_SENTENCES_WITH_NUM" -v t="$NUM_SENTENCES_TOTAL" 'BEGIN { printf "%.0f", 30.0 * n / t }')
  RATE_DOD=$(awk -v n="$NUM_SENTENCES_WITH_NUM" -v t="$NUM_SENTENCES_TOTAL" 'BEGIN { printf "%.0f", 100.0 * n / t }')
  EVIDENCE_DOD="request の ${NUM_SENTENCES_TOTAL} 文中 ${NUM_SENTENCES_WITH_NUM} 文 (${RATE_DOD}%) に数値要件あり"
fi

# ---- 成分 (3): 関連 D/P 件数の有意性 (30 点満点) ----

DECISIONS_COUNT="$(jq '.decisions | length' "$NORM_MEM")"
PATTERNS_COUNT="$(jq '.patterns | length' "$NORM_MEM")"
DP_TOTAL=$((DECISIONS_COUNT + PATTERNS_COUNT))

if   [[ "$DP_TOTAL" -ge 6 ]]; then SCORE_DP=30
elif [[ "$DP_TOTAL" -ge 3 ]]; then SCORE_DP=20
elif [[ "$DP_TOTAL" -ge 1 ]]; then SCORE_DP=10
else                               SCORE_DP=0
fi
EVIDENCE_DP="関連 D ${DECISIONS_COUNT} 件 + P ${PATTERNS_COUNT} 件 = ${DP_TOTAL} 件 (寄与 ${SCORE_DP} pt)"

# ---- confidence 合計 (0-100 にクランプ) ----

CONFIDENCE=$((SCORE_PAST + SCORE_DOD + SCORE_DP))
[[ "$CONFIDENCE" -gt 100 ]] && CONFIDENCE=100
[[ "$CONFIDENCE" -lt 0 ]]   && CONFIDENCE=0

# ---- 出力 JSON 組み立て ----

GENERATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 各セクションを normalized 配列で取得
RELATED_DECISIONS_JSON="$(jq '[.decisions[] | {id: (.id // ""), title: (.title // ""), relevance: (.relevance // "")}]' "$NORM_MEM")"
SIMILAR_PAST_PLANS_JSON="$(jq '[.plans_archive[] | {archive_path: (.archive_path // ""), phase: (.phase // ""), outcome: (.outcome // "unknown"), relevance: (.relevance // "")}]' "$NORM_MEM")"

# confidence_evidence_items は template 描画用の derived field
EVIDENCE_ITEMS_JSON="$(jq -nc \
  --arg p "$EVIDENCE_PAST" \
  --arg d "$EVIDENCE_DOD" \
  --arg r "$EVIDENCE_DP" \
  '[{text: $p}, {text: $d}, {text: $r}]')"

CONTEXT_JSON="$(jq -n \
  --arg req "$QUERY" \
  --arg proj "$PROJECT" \
  --arg ts "$GENERATED_AT" \
  --arg understanding "$UNDERSTANDING" \
  --arg ev_past "$EVIDENCE_PAST" \
  --arg ev_dod "$EVIDENCE_DOD" \
  --arg ev_dp "$EVIDENCE_DP" \
  --argjson conf "$CONFIDENCE" \
  --argjson rd "$RELATED_DECISIONS_JSON" \
  --argjson sp "$SIMILAR_PAST_PLANS_JSON" \
  --argjson ev_items "$EVIDENCE_ITEMS_JSON" \
  '{
    schema: "plan-brief-context.v1",
    user_request: $req,
    my_understanding: $understanding,
    options: [],
    risks: [],
    acceptance_criteria: [],
    confidence: $conf,
    confidence_evidence: [$ev_past, $ev_dod, $ev_dp],
    related_decisions: $rd,
    similar_past_plans: $sp,
    project: $proj,
    generated_at: $ts,
    confidence_evidence_items: $ev_items
  }')"

if [[ "$OUT" == "-" || -z "$OUT" ]]; then
  printf '%s\n' "$CONTEXT_JSON"
else
  printf '%s\n' "$CONTEXT_JSON" > "$OUT"
fi
