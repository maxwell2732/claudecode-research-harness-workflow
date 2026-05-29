#!/bin/bash
# plan-registry.sh
# Named Plans.md registry helper.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/plan-registry.sh [--root PATH] list
  scripts/plan-registry.sh [--root PATH] path [PLAN]
  scripts/plan-registry.sh [--root PATH] switch PLAN
EOF
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root)
      if [ $# -lt 2 ] || [ -z "${2:-}" ] || [[ "${2:-}" == --* ]]; then
        echo "--root requires a path" >&2
        exit 2
      fi
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    list|path|switch)
      break
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

[ -n "$PROJECT_ROOT" ] || usage
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

# shellcheck source=scripts/config-utils.sh
source "${SCRIPT_DIR}/config-utils.sh"

command_name="${1:-}"
[ -n "$command_name" ] || usage
shift || true

manifest_path="${PROJECT_ROOT}/${PLAN_MANIFEST_FILE}"

list_plans() {
  if [ ! -f "$manifest_path" ]; then
    printf 'default\t%s\t%s\n' "$(get_legacy_plans_file_path)" "active"
    return 0
  fi

  local active_plan
  active_plan="$(get_selected_plan_name)"
  python3 - "$manifest_path" "$active_plan" "$PROJECT_ROOT" <<'PY'
import json
import sys
from pathlib import Path

manifest, active, root = sys.argv[1:4]
data = json.loads(Path(manifest).read_text(encoding="utf-8"))
plans = data.get("plans", {})
for name in sorted(plans):
    entry = plans[name]
    path = entry if isinstance(entry, str) else entry.get("path", "")
    marker = "active" if name == active else ""
    print(f"{name}\t{path}\t{marker}")
PY
}

resolve_plan_or_die() {
  local plan_name="$1"
  if ! validate_plan_name "$plan_name"; then
    echo "invalid plan name: $plan_name" >&2
    return 1
  fi
  if ! resolve_named_plan_file_path "$plan_name"; then
    echo "unknown or unsafe plan: $plan_name" >&2
    return 1
  fi
}

case "$command_name" in
  list)
    list_plans
    ;;
  path)
    plan_name="${1:-$(get_selected_plan_name)}"
    resolve_plan_or_die "$plan_name"
    ;;
  switch)
    plan_name="${1:-}"
    [ -n "$plan_name" ] || usage
    resolved_path="$(resolve_plan_or_die "$plan_name")" || exit 1
    mkdir -p "${PROJECT_ROOT}/$(dirname "$ACTIVE_PLAN_FILE")"
    python3 - "${PROJECT_ROOT}/${ACTIVE_PLAN_FILE}" "$plan_name" "$resolved_path" <<'PY'
import json
import sys
from pathlib import Path

path, plan_name, plan_path = sys.argv[1:4]
target = Path(path)
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(json.dumps({
    "schema_version": "active-plan.v1",
    "active_plan": plan_name,
    "path": plan_path,
}, indent=2) + "\n", encoding="utf-8")
PY
    printf 'active plan: %s\t%s\n' "$plan_name" "$resolved_path"
    ;;
  *)
    usage
    ;;
esac
