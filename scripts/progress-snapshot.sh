#!/usr/bin/env bash
# scripts/progress-snapshot.sh
# Phase 65.4.1 - Plans.md → progress-snapshot.v1 JSON
#
# Purpose:
#   Plans.md の task table から cc:todo / cc:wip / cc:done の件数と
#   一覧を抽出し、harness-progress skill 用の snapshot JSON を生成する。
#
# Usage:
#   progress-snapshot.sh --plans <path> --project <name> [--state-file <path>]
#
# Schema: progress-snapshot.v1 (skills/harness-progress/schemas/)
#
# Plans.md format 想定:
#   | <number> | <title> | <DoD> | <Depends> | <Status> |
#   Status は cc:todo / cc:wip / cc:done [hash]（旧 cc:TODO / cc:WIP / cc:完了 も読取可）
#   pm:* は本 snapshot の対象外
#
# Optional: --state-file
#   .claude/state/session-cost.json から elapsed_minutes / cost_so_far_usd
#   等を読む (なければ全部 0)

set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage: progress-snapshot.sh --plans <path> --project <name> [--state-file <path>]

Required:
  --plans <path>       Plans.md ファイルパス
  --project <name>     project 名 (basename of repo)

Optional:
  --state-file <path>  session state JSON
                       期待 fields: elapsed_minutes / estimated_total_minutes /
                                   cost_so_far_usd / cost_estimate_usd
                       なければ全て 0 で fallback

Exit: 0=success / 1=runtime error / 2=usage error
USAGE
  exit 2
}

PLANS_PATH=""
PROJECT=""
STATE_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plans)      PLANS_PATH="${2:-}"; shift 2 ;;
    --project)    PROJECT="${2:-}"; shift 2 ;;
    --state-file) STATE_FILE="${2:-}"; shift 2 ;;
    -h|--help)    usage ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage ;;
  esac
done

if [[ -z "$PLANS_PATH" || -z "$PROJECT" ]]; then
  echo "ERROR: --plans and --project are required" >&2
  usage
fi

if [[ ! -f "$PLANS_PATH" ]]; then
  echo "ERROR: Plans.md not found: $PLANS_PATH" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required" >&2
  exit 1
fi

# state defaults
ELAPSED_MIN=0
ESTIMATE_MIN=0
COST_SO_FAR=0
COST_ESTIMATE=0

if [[ -n "$STATE_FILE" && -f "$STATE_FILE" ]]; then
  ELAPSED_MIN="$(jq -r '.elapsed_minutes // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
  ESTIMATE_MIN="$(jq -r '.estimated_total_minutes // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
  COST_SO_FAR="$(jq -r '.cost_so_far_usd // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
  COST_ESTIMATE="$(jq -r '.cost_estimate_usd // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
fi

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

export PLANS_PATH_PY="$PLANS_PATH"
export PROJECT_PY="$PROJECT"
export TIMESTAMP_PY="$TIMESTAMP"
export ELAPSED_MIN_PY="$ELAPSED_MIN"
export ESTIMATE_MIN_PY="$ESTIMATE_MIN"
export COST_SO_FAR_PY="$COST_SO_FAR"
export COST_ESTIMATE_PY="$COST_ESTIMATE"

exec python3 - <<'PYEOF'
import os
import re
import json
import sys

PLANS_PATH = os.environ["PLANS_PATH_PY"]
PROJECT = os.environ["PROJECT_PY"]
TIMESTAMP = os.environ["TIMESTAMP_PY"]
ELAPSED_MIN = int(os.environ["ELAPSED_MIN_PY"] or 0)
ESTIMATE_MIN = int(os.environ["ESTIMATE_MIN_PY"] or 0)

def to_float(s):
    try:
        return float(s)
    except (TypeError, ValueError):
        return 0.0

COST_SO_FAR = to_float(os.environ["COST_SO_FAR_PY"])
COST_ESTIMATE = to_float(os.environ["COST_ESTIMATE_PY"])

# Plans.md の task 行を parse:
#   "| 65.4.1 | <title> | <DoD> | <Depends> | cc:todo |"
#   "| 65.4.1 | <title> | <DoD> | <Depends> | cc:done [a1b2c3d] |"
# title は最初の `。` までを 1 行サマリとして使う

ROW_RE = re.compile(
    r"^\|\s*(\d+(?:\.\d+)*)\s*\|\s*(.+?)\s*\|\s*.+?\s*\|\s*.+?\s*\|\s*(cc:\S+(?:\s*\[[a-f0-9]+\])?)\s*\|\s*$"
)

todo = []
wip = []
done = []

with open(PLANS_PATH, "r", encoding="utf-8") as f:
    for line in f:
        m = ROW_RE.match(line)
        if not m:
            continue
        number, title, status = m.group(1), m.group(2), m.group(3)
        # title 短縮: 最初の "。" で切る、なければ 80 文字まで
        short_title = title.split("。")[0]
        if len(short_title) > 80:
            short_title = short_title[:77] + "..."

        if status in ("cc:todo", "cc:TODO"):
            todo.append({"number": number, "title": short_title})
        elif status in ("cc:wip", "cc:WIP"):
            wip.append({"number": number, "title": short_title})
        elif status.startswith("cc:done") or status.startswith("cc:完了"):
            commit_match = re.search(r"\[([a-f0-9]+)\]", status)
            commit = commit_match.group(1)[:7] if commit_match else ""
            done.append({"number": number, "title": short_title, "commit": commit})

total = len(todo) + len(wip) + len(done)
if total == 0:
    progress_pct = 0
else:
    progress_pct = round(len(done) * 100 / total)

current_task = wip[0]["title"] if wip else ""

# Derived helpers (render-html.sh の section 展開用)
done_recent = done[-5:][::-1]  # 最新 5 件、新しい順

snapshot = {
    "schema": "progress-snapshot.v1",
    "project": PROJECT,
    "current_task": current_task,
    "progress_pct": progress_pct,
    "todo_tasks": todo,
    "wip_tasks": wip,
    "done_tasks": done,
    "elapsed_minutes": ELAPSED_MIN,
    "estimated_total_minutes": ESTIMATE_MIN,
    "cost_so_far_usd": COST_SO_FAR,
    "cost_estimate_usd": COST_ESTIMATE,
    "alerts": [],
    "generated_at": TIMESTAMP,
    "_done_recent_items": done_recent,
    "_todo_count": len(todo),
    "_wip_count": len(wip),
    "_done_count": len(done),
}

print(json.dumps(snapshot, ensure_ascii=False, indent=2))
PYEOF
