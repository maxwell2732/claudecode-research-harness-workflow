#!/usr/bin/env bash
# Research Agent Harness — pre-tool-use hook
# Blocks Write and Edit operations targeting data/raw/.
# Called by Claude Code before every Edit or Write tool invocation.
#
# Input (via stdin): JSON with tool_name and tool_input fields.
# Exit 0 = allow; Exit 1 = block (Claude Code will show the error message).

set -euo pipefail

input="$(cat)"

tool_name="$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)"
file_path="$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)"

# Normalise path: strip leading ./ and collapse //
file_path="${file_path#./}"

if [[ "$tool_name" == "Edit" || "$tool_name" == "Write" || "$tool_name" == "MultiEdit" ]]; then
  if [[ "$file_path" == data/raw/* || "$file_path" == */data/raw/* ]]; then
    echo "BLOCKED: data/raw/ is read-only. Raw data must never be modified." >&2
    echo "Research Agent Harness Integrity Rule 1: all transformations go to data/processed/ or data/intermediate/." >&2
    exit 1
  fi
fi

exit 0
