#!/usr/bin/env bash
# scripts/progress-detect-drift.sh
# Phase 65.4.3 - Progress Tracker drift detection (5 alert kinds)
#
# Purpose:
#   Plans.md と session state を検査し、5 種類の drift alert を生成する。
#   生成 alert は progress-alert.v1 schema 準拠の JSON 配列で出力。
#
# Schema: progress-alert.v1
#   {
#     kind: "scope-creep"|"time-overrun"|"repeated-failure"|"cost-warning"|"high-risk-file",
#     severity: "info"|"warn"|"critical",
#     message: string,
#     suggested_action: string,
#     triggered_at: ISO8601
#   }
#
# Usage:
#   progress-detect-drift.sh \
#     [--scope-creep-files <csv>]   # Plans.md にない file 編集 (CSV)
#     [--elapsed-min <int>]          # 経過分数
#     [--estimate-min <int>]         # 推定総分数
#     [--repeated-failure-count <int>]  # test 連続失敗数
#     [--cost-so-far <float>]        # コスト so far
#     [--cost-limit <float>]         # コスト上限
#     [--high-risk-files <csv>]      # harness.toml deny path matching file (CSV)
#
# 各 input が空 / default の場合、その alert kind は出力されない (no-op)。
# stdout に [{...}, ...] の JSON 配列を出力 (空配列もあり)。
#
# 検出条件 (Plans.md DoD 準拠):
#   - scope-creep:    Plans.md に出てこない file が編集された
#   - time-overrun:   elapsed > estimate × 1.5
#   - repeated-failure: test fail count >= 3
#   - cost-warning:   cost_so_far / cost_limit >= 0.80 かつ cost_limit > 0
#   - high-risk-file: harness.toml deny path に match した file が編集された
#
# severity マップ:
#   - scope-creep:      warn
#   - time-overrun:     warn (1.5x), critical (2.0x 以上)
#   - repeated-failure: critical
#   - cost-warning:     warn (80-100%), critical (100%+)
#   - high-risk-file:   critical

set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage: progress-detect-drift.sh [options]

All optional (each input absent → corresponding alert not emitted):
  --scope-creep-files <csv>      Plans.md にない file 編集の CSV
  --elapsed-min <int>            経過分数 (default 0)
  --estimate-min <int>           推定総分数 (default 0)
  --repeated-failure-count <int> test 連続失敗数 (default 0)
  --cost-so-far <float>          コスト so far (default 0)
  --cost-limit <float>           コスト上限 (default 0)
  --high-risk-files <csv>        harness.toml deny path matching の CSV

Output: JSON array of progress-alert.v1 objects (空配列もあり)
Exit:   0 = success / 2 = usage error
USAGE
  exit 2
}

SCOPE_CREEP=""
ELAPSED_MIN=0
ESTIMATE_MIN=0
FAILURE_COUNT=0
COST_SO_FAR=0
COST_LIMIT=0
HIGH_RISK=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope-creep-files)        SCOPE_CREEP="${2:-}"; shift 2 ;;
    --elapsed-min)              ELAPSED_MIN="${2:-0}"; shift 2 ;;
    --estimate-min)             ESTIMATE_MIN="${2:-0}"; shift 2 ;;
    --repeated-failure-count)   FAILURE_COUNT="${2:-0}"; shift 2 ;;
    --cost-so-far)              COST_SO_FAR="${2:-0}"; shift 2 ;;
    --cost-limit)               COST_LIMIT="${2:-0}"; shift 2 ;;
    --high-risk-files)          HIGH_RISK="${2:-}"; shift 2 ;;
    -h|--help)                  usage ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage ;;
  esac
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required" >&2
  exit 2
fi

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

export TIMESTAMP_PY="$TIMESTAMP"
export SCOPE_CREEP_PY="$SCOPE_CREEP"
export ELAPSED_MIN_PY="$ELAPSED_MIN"
export ESTIMATE_MIN_PY="$ESTIMATE_MIN"
export FAILURE_COUNT_PY="$FAILURE_COUNT"
export COST_SO_FAR_PY="$COST_SO_FAR"
export COST_LIMIT_PY="$COST_LIMIT"
export HIGH_RISK_PY="$HIGH_RISK"

exec python3 - <<'PYEOF'
import os
import json
import sys

TIMESTAMP = os.environ["TIMESTAMP_PY"]

def to_int(s):
    try:
        return int(s)
    except (TypeError, ValueError):
        return 0

def to_float(s):
    try:
        return float(s)
    except (TypeError, ValueError):
        return 0.0

def parse_csv(s):
    if not s:
        return []
    return [x.strip() for x in s.split(",") if x.strip()]

scope_creep_files = parse_csv(os.environ.get("SCOPE_CREEP_PY", ""))
elapsed_min = to_int(os.environ.get("ELAPSED_MIN_PY", "0"))
estimate_min = to_int(os.environ.get("ESTIMATE_MIN_PY", "0"))
failure_count = to_int(os.environ.get("FAILURE_COUNT_PY", "0"))
cost_so_far = to_float(os.environ.get("COST_SO_FAR_PY", "0"))
cost_limit = to_float(os.environ.get("COST_LIMIT_PY", "0"))
high_risk_files = parse_csv(os.environ.get("HIGH_RISK_PY", ""))

alerts = []

# 1. scope-creep
if scope_creep_files:
    alerts.append({
        "kind": "scope-creep",
        "severity": "warn",
        "message": f"Plans.md にない {len(scope_creep_files)} ファイルが編集されました: {', '.join(scope_creep_files[:3])}",
        "suggested_action": "編集が意図したスコープ内か確認するか、Plans.md にタスクを追加してください",
        "triggered_at": TIMESTAMP,
    })

# 2. time-overrun
if estimate_min > 0 and elapsed_min > 0:
    ratio = elapsed_min / estimate_min
    if ratio >= 2.0:
        alerts.append({
            "kind": "time-overrun",
            "severity": "critical",
            "message": f"経過 {elapsed_min} 分が推定 {estimate_min} 分の {ratio:.1f} 倍を超えています",
            "suggested_action": "残作業をスコープ縮小するか、別セッションへ分割を検討してください",
            "triggered_at": TIMESTAMP,
        })
    elif ratio >= 1.5:
        alerts.append({
            "kind": "time-overrun",
            "severity": "warn",
            "message": f"経過 {elapsed_min} 分が推定 {estimate_min} 分の {ratio:.1f} 倍を超えました",
            "suggested_action": "残タスクの所要時間を再見積もりしてください",
            "triggered_at": TIMESTAMP,
        })

# 3. repeated-failure
if failure_count >= 3:
    alerts.append({
        "kind": "repeated-failure",
        "severity": "critical",
        "message": f"テストが {failure_count} 回連続で失敗しています",
        "suggested_action": "原因調査を一時停止して、ユーザーへエスカレーションしてください",
        "triggered_at": TIMESTAMP,
    })

# 4. cost-warning
if cost_limit > 0:
    pct = cost_so_far / cost_limit
    if pct >= 1.0:
        alerts.append({
            "kind": "cost-warning",
            "severity": "critical",
            "message": f"コスト ${cost_so_far:.2f} が上限 ${cost_limit:.2f} を超過しました ({pct*100:.0f}%)",
            "suggested_action": "セッションを停止し、残タスクを別予算で再開してください",
            "triggered_at": TIMESTAMP,
        })
    elif pct >= 0.80:
        alerts.append({
            "kind": "cost-warning",
            "severity": "warn",
            "message": f"コスト ${cost_so_far:.2f} が上限 ${cost_limit:.2f} の {pct*100:.0f}% に到達しました",
            "suggested_action": "残タスクの優先度を見直し、必須項目に絞り込んでください",
            "triggered_at": TIMESTAMP,
        })

# 5. high-risk-file
if high_risk_files:
    alerts.append({
        "kind": "high-risk-file",
        "severity": "critical",
        "message": f"harness.toml deny path に該当するファイル {len(high_risk_files)} 件への編集試行: {', '.join(high_risk_files[:3])}",
        "suggested_action": "編集を取り消すか、ユーザーに deny path 設定変更の是非を確認してください",
        "triggered_at": TIMESTAMP,
    })

print(json.dumps(alerts, ensure_ascii=False, indent=2))
sys.exit(0)
PYEOF
