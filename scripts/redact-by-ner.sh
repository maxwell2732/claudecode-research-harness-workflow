#!/usr/bin/env bash
# redact-by-ner.sh
# Phase 65.3.3 - Layer 2b NER (Named Entity Recognition) redaction
#
# Purpose:
#   テキストを受け取り、Japanese tokenizer (fugashi + UniDic-lite)
#   で形態素解析後、pos2="固有名詞" tag を持つトークンを [Entity] に置換。
#   隣接する固有名詞は 1 つの [Entity] にマージする (e.g., 田中 + 太郎 → [Entity])。
#
# Usage:
#   redact-by-ner.sh --input <text>
#   echo "text" | redact-by-ner.sh --stdin
#
# Options:
#   --input <text>         redact 対象テキスト
#   --stdin                stdin から読む
#   -h | --help            ヘルプ
#
# Environment:
#   CCH_NER_DISABLE_TOKENIZER=1   tokenizer を強制 disable (test 用 fail-open)
#
# Exit code:
#   0 = success (NER 成功 / fail-open 経由を含む)
#   2 = usage error
#
# Output:
#   stdout: redacted text (固有名詞 0 件なら原文そのまま)
#   stderr: ヒット時 "redacted: <count> entities"
#           tokenizer 不在時 "WARNING: tokenizer unavailable, fail-open"
#
# Fail-open 仕様 (Plans.md DoD d):
#   tokenizer (fugashi) 不在 / import 失敗 → exit 0、原文そのまま、
#   stderr に warning 1 行。redact しないが処理は止めない。
#
# 二重置換ガード (D43 判断 4):
#   既存の sentinel mark ([REDACTED_*] / [Entity] / [Client_*] /
#   [Person_*] / [Domain_*]) は退避 → NER → 復元の 3 段で
#   再 redact しない。

set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage:
  redact-by-ner.sh --input <text>
  echo "text" | redact-by-ner.sh --stdin

Required (one of):
  --input <text>          redact 対象テキスト
  --stdin                 stdin から読む

Options:
  -h | --help             ヘルプ

Environment:
  CCH_NER_DISABLE_TOKENIZER=1   tokenizer を強制 disable (test 用)

Exit code: 0=success / 2=usage error
USAGE
  exit 2
}

INPUT=""
USE_STDIN="false"
INPUT_PROVIDED="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)  INPUT="${2:-}"; INPUT_PROVIDED="true"; shift 2 ;;
    --stdin)  USE_STDIN="true"; shift 1 ;;
    -h|--help) usage ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage ;;
  esac
done

if [[ "$USE_STDIN" == "true" && "$INPUT_PROVIDED" == "true" ]]; then
  echo "ERROR: --input and --stdin are mutually exclusive" >&2
  exit 2
fi

if [[ "$USE_STDIN" == "false" && "$INPUT_PROVIDED" == "false" ]]; then
  echo "ERROR: one of --input or --stdin is required" >&2
  usage
fi

if ! command -v python3 >/dev/null 2>&1; then
  # python3 不在も fail-open
  if [[ "$USE_STDIN" == "true" ]]; then
    cat
  else
    printf '%s' "$INPUT"
  fi
  echo "WARNING: python3 unavailable, fail-open (NER skipped)" >&2
  exit 0
fi

# stdin から読む
if [[ "$USE_STDIN" == "true" ]]; then
  INPUT="$(cat)"
fi

export INPUT_TEXT_PY="$INPUT"
export CCH_NER_DISABLE_TOKENIZER_PY="${CCH_NER_DISABLE_TOKENIZER:-}"

exec python3 - <<'PYEOF'
import os
import sys
import re

INPUT_TEXT = os.environ.get("INPUT_TEXT_PY", "")
DISABLE_TOKENIZER = os.environ.get("CCH_NER_DISABLE_TOKENIZER_PY", "") == "1"

# Sentinel patterns (D43 判断 4: 二重置換ガード)
SENTINEL_PATTERNS = [
    re.compile(r"\[REDACTED_[A-Za-z0-9_]+\]"),
    re.compile(r"\[Entity\]"),
    re.compile(r"\[Client_[A-Za-z0-9_]+\]"),
    re.compile(r"\[Person_[A-Za-z0-9_]+\]"),
    re.compile(r"\[Domain_[A-Za-z0-9_]+\]"),
]

def fail_open(reason):
    """tokenizer 不在 / import 失敗時は原文そのまま + stderr 警告"""
    sys.stdout.write(INPUT_TEXT)
    print(f"WARNING: tokenizer unavailable, fail-open ({reason})", file=sys.stderr)
    sys.exit(0)

if DISABLE_TOKENIZER:
    fail_open("CCH_NER_DISABLE_TOKENIZER=1")

try:
    from fugashi import Tagger
except ImportError as e:
    fail_open(f"fugashi import failed: {e}")

try:
    tagger = Tagger()
except Exception as e:
    # dict 不在 etc.
    fail_open(f"tokenizer init failed: {e}")

# ---- 二重置換ガード: sentinel を退避 ----
text = INPUT_TEXT
sentinel_storage = []

def stash_sentinels(t):
    out = t
    for pat in SENTINEL_PATTERNS:
        def replace(m):
            idx = len(sentinel_storage)
            sentinel_storage.append(m.group(0))
            return f" CCH_SENT_{idx} "
        out = pat.sub(replace, out)
    return out

text = stash_sentinels(text)

# ---- NER: 形態素解析 → 固有名詞抽出 → 隣接マージ ----
# fugashi で text を解析 → token list を得る
# 連続する 固有名詞 token は 1 つの [Entity] にまとめる
# それ以外の token (および sentinel placeholder) はそのまま保持

try:
    tokens = list(tagger(text))
except Exception as e:
    # tokenize 失敗 (rare) も fail-open
    sys.stdout.write(INPUT_TEXT)
    print(f"WARNING: tokenization failed, fail-open ({e})", file=sys.stderr)
    sys.exit(0)

# 出力組み立て: token を順に処理し、固有名詞 run を 1 つの [Entity] に
output_parts = []
hit_count = 0
in_proper_noun_run = False

for tok in tokens:
    surface = tok.surface
    feature = tok.feature
    pos2 = getattr(feature, "pos2", "") if feature is not None else ""
    is_proper_noun = (pos2 == "固有名詞")
    white_space = getattr(tok, "white_space", "") or ""

    if is_proper_noun:
        if not in_proper_noun_run:
            output_parts.append(white_space + "[Entity]")
            hit_count += 1
            in_proper_noun_run = True
        # else: 同じ run の続き → 何も append しない (既に 1 つ [Entity] あり)
    else:
        output_parts.append(white_space + surface)
        in_proper_noun_run = False

result = "".join(output_parts)

# ---- sentinel 復元 ----
for idx, original in enumerate(sentinel_storage):
    placeholder_core = f"CCH_SENT_{idx}"
    result = result.replace(f" {placeholder_core} ", original)
    result = result.replace(placeholder_core, original)

# ---- output ----
sys.stdout.write(result)

if hit_count > 0:
    print(f"redacted: {hit_count} entities", file=sys.stderr)

sys.exit(0)
PYEOF
