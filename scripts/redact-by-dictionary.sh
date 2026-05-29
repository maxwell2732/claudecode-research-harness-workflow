#!/usr/bin/env bash
# redact-by-dictionary.sh
# Phase 65.3.2 - Layer 2a 辞書ベース固有名詞 redaction (D43 判断 3 + 4)
#
# Purpose:
#   テキストを受け取り、client-redaction.yaml の dict に従って
#   固有名詞 (clients / people / domains) を redact_with token に置換。
#   ヒット件数を stderr に記録、redacted text を stdout に出力。
#
# Usage:
#   redact-by-dictionary.sh --input <text> [--dict <yaml-path>]
#   echo "text" | redact-by-dictionary.sh --stdin [--dict <yaml-path>]
#
# Options:
#   --input <text>          redact 対象テキスト (literal)
#   --stdin                 stdin から redact 対象を読む
#   --dict <yaml-path>      dict ファイル (default: .claude/rules/client-redaction.yaml)
#   -h | --help             ヘルプ
#
# Exit code:
#   0 = success (ヒット 0 でも 1 でも、正常終了)
#   1 = dict file not found / dict schema invalid / runtime error
#   2 = usage error
#
# Output:
#   stdout: redacted text (ヒット 0 件なら原文そのまま)
#   stderr: ヒット時のみ "redacted: <count> tokens" の 1 行
#
# 二重置換ガード (D43 判断 4):
#   既に [REDACTED_*] [Entity] [Client_*] [Person_*] [Domain_*] が
#   含まれる箇所は再置換しない (sentinel pattern による境界検出)。
#
# Schema: client-redaction.v1 (PiiRule 互換)
#   {schema_version, clients[], people[], domains[]}
#   各 entry: {rule_id, name, aliases[]?, replace_with}

set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage:
  redact-by-dictionary.sh --input <text> [--dict <yaml-path>]
  echo "text" | redact-by-dictionary.sh --stdin [--dict <yaml-path>]

Required (one of):
  --input <text>          redact 対象テキスト
  --stdin                 stdin から読む

Optional:
  --dict <yaml-path>      dict ファイル (default: .claude/rules/client-redaction.yaml)
  -h | --help             ヘルプ

Exit code: 0=success / 1=runtime error / 2=usage error
USAGE
  exit 2
}

INPUT=""
USE_STDIN="false"
DICT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)  INPUT="${2:-}";  USE_STDIN="false"; shift 2 ;;
    --stdin)  USE_STDIN="true"; shift 1 ;;
    --dict)   DICT_PATH="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage ;;
  esac
done

if [[ "$USE_STDIN" == "true" && -n "$INPUT" ]]; then
  echo "ERROR: --input and --stdin are mutually exclusive" >&2
  exit 2
fi

if [[ "$USE_STDIN" == "false" && -z "$INPUT" ]]; then
  # 空文字列の --input は 0 ヒットで原文出力 (正常)
  # ただし両方未指定はエラー
  if [[ $# -eq 0 ]] && [[ -z "${INPUT+x}" || "$INPUT" == "__UNSET_SENTINEL__" ]]; then
    echo "ERROR: one of --input or --stdin is required" >&2
    usage
  fi
fi

# default dict path
if [[ -z "$DICT_PATH" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
  DICT_PATH="${REPO_ROOT}/.claude/rules/client-redaction.yaml"
fi

if [[ ! -f "$DICT_PATH" ]]; then
  echo "ERROR: dict file not found: $DICT_PATH" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required but not found" >&2
  exit 1
fi

# stdin から読む
if [[ "$USE_STDIN" == "true" ]]; then
  INPUT="$(cat)"
fi

export DICT_PATH_PY="$DICT_PATH"
export INPUT_TEXT_PY="$INPUT"

exec python3 - <<'PYEOF'
import os
import sys
import re

try:
    import yaml
except ImportError:
    print("ERROR: python3-yaml (PyYAML) is required but not installed", file=sys.stderr)
    sys.exit(1)

DICT_PATH = os.environ["DICT_PATH_PY"]
INPUT_TEXT = os.environ.get("INPUT_TEXT_PY", "")

EXPECTED_SCHEMA = "client-redaction.v1"

# Sentinel patterns (D43 判断 4: 二重置換ガード)
# 既存の redact mark をプレースホルダーに退避し、redact 後に復元する
SENTINEL_PATTERNS = [
    re.compile(r"\[REDACTED_[A-Za-z0-9_]+\]"),
    re.compile(r"\[Entity\]"),
    re.compile(r"\[Client_[A-Za-z0-9_]+\]"),
    re.compile(r"\[Person_[A-Za-z0-9_]+\]"),
    re.compile(r"\[Domain_[A-Za-z0-9_]+\]"),
]

# ---- yaml load + schema validation ----
try:
    with open(DICT_PATH, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f"ERROR: yaml parse failed: {e}", file=sys.stderr)
    sys.exit(1)

if data is None:
    print(f"ERROR: dict yaml is empty: {DICT_PATH}", file=sys.stderr)
    sys.exit(1)

schema_version = data.get("schema_version")
if schema_version != EXPECTED_SCHEMA:
    print(f"ERROR: schema_version must be '{EXPECTED_SCHEMA}', got: {schema_version!r}", file=sys.stderr)
    sys.exit(1)

# ---- entries 抽出 (clients + people + domains) ----
entries = []
seen_rule_ids = set()

for category in ("clients", "people", "domains"):
    items = data.get(category) or []
    if not isinstance(items, list):
        print(f"ERROR: '{category}' must be a list", file=sys.stderr)
        sys.exit(1)
    for i, item in enumerate(items):
        if not isinstance(item, dict):
            print(f"ERROR: {category}[{i}] must be an object", file=sys.stderr)
            sys.exit(1)

        rule_id = item.get("rule_id")
        name = item.get("name")
        replace_with = item.get("replace_with")
        aliases = item.get("aliases") or []

        if not isinstance(rule_id, str) or rule_id == "":
            print(f"ERROR: {category}[{i}].rule_id must be a non-empty string", file=sys.stderr)
            sys.exit(1)
        if rule_id in seen_rule_ids:
            print(f"ERROR: duplicate rule_id: {rule_id}", file=sys.stderr)
            sys.exit(1)
        seen_rule_ids.add(rule_id)

        if not isinstance(name, str) or name == "":
            print(f"ERROR: {category}[{i}].name must be a non-empty string", file=sys.stderr)
            sys.exit(1)

        if not isinstance(replace_with, str) or replace_with == "":
            print(f"ERROR: {category}[{i}].replace_with must be a non-empty string", file=sys.stderr)
            sys.exit(1)

        if not isinstance(aliases, list):
            print(f"ERROR: {category}[{i}].aliases must be a list if present", file=sys.stderr)
            sys.exit(1)
        for j, a in enumerate(aliases):
            if not isinstance(a, str) or a == "":
                print(f"ERROR: {category}[{i}].aliases[{j}] must be a non-empty string", file=sys.stderr)
                sys.exit(1)

        entries.append({
            "rule_id": rule_id,
            "name": name,
            "aliases": aliases,
            "replace_with": replace_with,
            "category": category,
        })

# ---- 二重置換ガード: sentinel を退避 ----
# 既存の sentinel mark を {{__SENTINEL_<idx>__}} に退避する
text = INPUT_TEXT
sentinel_storage = []  # 復元用 (idx, original)

def stash_sentinels(t):
    """t 内の sentinel mark を placeholder に退避し、退避リストを更新"""
    out = t
    for pat in SENTINEL_PATTERNS:
        def replace(m):
            idx = len(sentinel_storage)
            sentinel_storage.append(m.group(0))
            return f"__CCHX_SENTINEL_{idx}__"
        out = pat.sub(replace, out)
    return out

text = stash_sentinels(text)

# ---- redaction (longer aliases first to avoid partial overshadow) ----
# entry ごとに [name] + [aliases] を全部 collect → length 降順で sort →
# 順次 literal replace。これで「田中太郎」が「田中」より先に置換される。
hit_count = 0

# Build replacement list: (search_string, replace_with) — sort by length DESC
all_replacements = []
for e in entries:
    targets = [e["name"]] + e["aliases"]
    for t in targets:
        all_replacements.append((t, e["replace_with"]))

# 長い順 (alias で 田中 vs 田中太郎 が両方ある時、長いほうから replace)
all_replacements.sort(key=lambda x: len(x[0]), reverse=True)

for search_str, replace_with in all_replacements:
    if search_str == "":
        continue
    if search_str in text:
        # count occurrences then replace
        count = text.count(search_str)
        text = text.replace(search_str, replace_with)
        hit_count += count

# ---- sentinel 復元 ----
for idx, original in enumerate(sentinel_storage):
    text = text.replace(f"__CCHX_SENTINEL_{idx}__", original)

# ---- output ----
sys.stdout.write(text)
# 末尾改行は input 由来のものを尊重 (write は改行付与しない)

if hit_count > 0:
    print(f"redacted: {hit_count} tokens", file=sys.stderr)

sys.exit(0)
PYEOF
