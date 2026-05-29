#!/bin/bash
# review-ai-residuals.sh
# 差分または対象ファイルから AI 実装の残骸候補を静的検出する。
#
# Usage:
#   bash scripts/review-ai-residuals.sh --base-ref <git-ref>
#   bash scripts/review-ai-residuals.sh --base-ref <git-ref> --include-untracked
#   bash scripts/review-ai-residuals.sh path/to/file.ts path/to/config.sh
#
# Exit:
#   0: 検出有無にかかわらず正常終了（review 側で verdict を判定する）
#   2: 使い方エラー

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/review-ai-residuals.sh --base-ref <git-ref>
  bash scripts/review-ai-residuals.sh <file> [<file> ...]

Options:
  --base-ref <git-ref>  git diff で変更ファイルを自動収集する
  --include-untracked   git diff には出ない untracked files も走査する
  --help                このヘルプを表示する

Output:
  Stable JSON:
  {
    "tool": "review-ai-residuals",
    "scan_mode": "diff|files",
    "base_ref": "HEAD~1" | null,
    "include_untracked": false,
    "files_scanned": ["src/app.ts"],
    "untracked_files_scanned": [],
    "summary": {
      "verdict": "APPROVE|REQUEST_CHANGES",
      "major": 0,
      "minor": 0,
      "recommendation": 0,
      "total": 0
    },
    "observations": []
  }
EOF
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\t'/\\t}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

trim_match_text() {
  local value="$1"
  value="$(printf '%s' "$value" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  if [ "${#value}" -gt 180 ]; then
    printf '%s...' "${value:0:177}"
  else
    printf '%s' "$value"
  fi
}

redact_secret_line() {
  printf '%s' "$1" | sed -E \
    "s/((api[_-]?key|secret|token|password|passwd|client[_-]?secret)[^:=]{0,20}[:=][[:space:]]*['\"]).+(['\"])/\1<redacted>\3/I"
}

should_ignore_path() {
  case "$1" in
    *.md|*.mdx|*.txt|*.rst|*.adoc) return 0 ;;
    docs/*|*/docs/*) return 0 ;;
    examples/*|*/examples/*) return 0 ;;
    tests/fixtures/*|*/tests/fixtures/*) return 0 ;;
    */node_modules/*|node_modules/*) return 0 ;;
    .git/*|*/.git/*) return 0 ;;
  esac
  return 1
}

is_scannable_file() {
  case "$1" in
    *.sh|*.bash|*.zsh|*.js|*.jsx|*.mjs|*.cjs|*.ts|*.tsx|*.py|*.rb|*.php|*.go|*.rs|*.java|*.kt|*.kts|*.swift|*.json|*.yml|*.yaml|*.toml|*.ini|*.cfg|*.conf|*.env)
      return 0
      ;;
  esac
  return 1
}

append_json_string_array() {
  local file="$1"
  local first=1
  printf '['
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ "$first" -eq 0 ]; then
      printf ','
    fi
    printf '"%s"' "$(json_escape "$line")"
    first=0
  done < "$file"
  printf ']'
}

append_json_object_array() {
  local file="$1"
  local first=1
  printf '['
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ "$first" -eq 0 ]; then
      printf ','
    fi
    printf '%s' "$line"
    first=0
  done < "$file"
  printf ']'
}

SEARCH_TOOL=""
if command -v rg >/dev/null 2>&1; then
  SEARCH_TOOL="rg"
else
  echo '{"tool":"review-ai-residuals","scan_mode":"files","base_ref":null,"include_untracked":false,"files_scanned":[],"untracked_files_scanned":[],"summary":{"verdict":"APPROVE","major":0,"minor":0,"recommendation":0,"total":0},"observations":[],"warning":"rg_not_found"}'
  exit 0
fi

SCAN_MODE="files"
BASE_REF_INPUT=""
INCLUDE_UNTRACKED=0
POSITIONAL_FILES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --base-ref)
      if [ $# -lt 2 ]; then
        echo "error: --base-ref requires a value" >&2
        usage >&2
        exit 2
      fi
      SCAN_MODE="diff"
      BASE_REF_INPUT="$2"
      shift 2
      ;;
    --include-untracked)
      INCLUDE_UNTRACKED=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      POSITIONAL_FILES+=("$1")
      shift
      ;;
  esac
done

if [ "$SCAN_MODE" = "diff" ] && [ ${#POSITIONAL_FILES[@]} -gt 0 ]; then
  echo "error: --base-ref and explicit files cannot be combined" >&2
  usage >&2
  exit 2
fi

if [ "$SCAN_MODE" = "files" ] && [ ${#POSITIONAL_FILES[@]} -eq 0 ]; then
  if [ -n "${BASE_REF:-}" ]; then
    SCAN_MODE="diff"
    BASE_REF_INPUT="${BASE_REF}"
  else
    SCAN_MODE="diff"
    BASE_REF_INPUT="HEAD~1"
  fi
fi

TMP_FILES="$(mktemp)"
TMP_UNTRACKED_FILES="$(mktemp)"
TMP_OBS="$(mktemp)"
TMP_DIFF="$(mktemp)"
cleanup() {
  rm -f "$TMP_FILES" "$TMP_UNTRACKED_FILES" "$TMP_OBS" "$TMP_DIFF"
}
trap cleanup EXIT

collect_diff_files() {
  local base_ref="$1"
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 1
  fi
  git diff --name-only --diff-filter=ACMR "$base_ref" -- 2>/dev/null || return 1
}

collect_untracked_files() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 1
  fi
  git ls-files --others --exclude-standard 2>/dev/null || return 1
}

queue_file_if_scannable() {
  local path="$1"
  path="${path#./}"
  [ -f "$path" ] || return 0
  should_ignore_path "$path" && return 0
  is_scannable_file "$path" || return 0
  printf '%s\n' "$path" >> "$TMP_FILES"
}

queue_untracked_file_if_scannable() {
  local path="$1"
  path="${path#./}"
  [ -f "$path" ] || return 0
  should_ignore_path "$path" && return 0
  is_scannable_file "$path" || return 0
  printf '%s\n' "$path" >> "$TMP_FILES"
  printf '%s\n' "$path" >> "$TMP_UNTRACKED_FILES"
}

if [ "$SCAN_MODE" = "diff" ]; then
  if collect_diff_files "$BASE_REF_INPUT" >"$TMP_DIFF" 2>/dev/null; then
    while IFS= read -r path; do
      queue_file_if_scannable "$path"
    done < "$TMP_DIFF"
  fi
else
  for path in "${POSITIONAL_FILES[@]}"; do
    queue_file_if_scannable "$path"
  done
fi

if [ "$INCLUDE_UNTRACKED" -eq 1 ]; then
  if collect_untracked_files >"$TMP_DIFF" 2>/dev/null; then
    while IFS= read -r path; do
      queue_untracked_file_if_scannable "$path"
    done < "$TMP_DIFF"
  fi
fi

sort -u "$TMP_FILES" -o "$TMP_FILES"
sort -u "$TMP_UNTRACKED_FILES" -o "$TMP_UNTRACKED_FILES"

MAJOR_COUNT=0
MINOR_COUNT=0
RECOMMENDATION_COUNT=0

append_observation() {
  local severity="$1"
  local rule="$2"
  local location="$3"
  local issue="$4"
  local suggestion="$5"
  local match_text="$6"

  case "$severity" in
    major) MAJOR_COUNT=$((MAJOR_COUNT + 1)) ;;
    minor) MINOR_COUNT=$((MINOR_COUNT + 1)) ;;
    recommendation) RECOMMENDATION_COUNT=$((RECOMMENDATION_COUNT + 1)) ;;
  esac

  printf '{"severity":"%s","category":"AI Residuals","rule":"%s","location":"%s","issue":"%s","suggestion":"%s","match":"%s"}\n' \
    "$(json_escape "$severity")" \
    "$(json_escape "$rule")" \
    "$(json_escape "$location")" \
    "$(json_escape "$issue")" \
    "$(json_escape "$suggestion")" \
    "$(json_escape "$match_text")" \
    >> "$TMP_OBS"
}

scan_file() {
  local file="$1"
  while IFS=$'\t' read -r rule severity pattern issue suggestion; do
    [ -n "$rule" ] || continue
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      local line_num line_text location match_text
      line_num="${hit%%:*}"
      line_text="${hit#*:}"
      location="${file}:${line_num}"
      match_text="$(trim_match_text "$line_text")"
      if [ "$rule" = "hardcoded-secret" ]; then
        match_text="$(trim_match_text "$(redact_secret_line "$match_text")")"
      fi
      append_observation "$severity" "$rule" "$location" "$issue" "$suggestion" "$match_text"
    done < <("${SEARCH_TOOL}" --no-config -n -I --pcre2 "$pattern" -- "$file" 2>/dev/null || true)
  done <<'EOF'
test-skip	major	\b(it|describe|test)\.skip\s*\(	無効化されたテストが残っています。レビューをすり抜ける可能性があります。	skip を外すか、どうしても必要なら理由をコメントと issue に残してください。
hardcoded-test-pass	major	(expect\((true|1)\)\.to(Be|Equal)\((true|1)\)|assert\.(True|Equal)\((true|1)(,|\)))	常に成功する空の検証が残っています。テストを通すためだけの実装に見えます。	実際の入力・出力・副作用を検証するアサーションに置き換えてください。
localhost-reference	major	\b(localhost|127\.0\.0\.1|0\.0\.0\.0)\b	ローカル専用の接続先が残っています。本番や共有環境で誤設定になりやすい状態です。	環境変数または公開設定から URL / host を注入してください。
hardcoded-secret	major	(?i)\b(api[_-]?key|secret|token|password|passwd|client[_-]?secret)\b[^:=\n]{0,20}[:=][[:space:]]*['"][^'"]{8,}['"]	秘密情報らしき値がハードコードされています。漏えいと環境固定の両面で危険です。	環境変数、秘密情報ストア、または安全な設定注入に置き換えてください。
hardcoded-env-url	major	https?://(dev|staging|internal|sandbox)[.-][A-Za-z0-9._/-]+	環境依存 URL がコードに固定されています。出荷先の誤接続につながります。	環境ごとの設定に切り出してください。
mock-data	minor	\bmockData\b	mock 用の値名が残っています。仮データの持ち込みかどうか確認が必要です。	実データに置き換えるか、必要ならテスト専用であることを明確にしてください。
dummy-value	minor	\bdummy[A-Za-z0-9_]*\b	dummy という仮値が残っています。	実値に置き換えるか、意図が分かる名前へ変更してください。
fake-data	minor	\bfake(Data)?\b	fake データ由来の名前が残っています。	本番コードなら実装へ置き換え、テストコードなら用途を明確にしてください。
todo-fixme	minor	\b(TODO|FIXME)\b	未完了の TODO / FIXME が残っています。	出荷前に解消するか、追跡先をコメントに残してください。
provisional-comment	recommendation	(?i)(temporary implementation|stub implementation|placeholder implementation|replace later|hardcoded for now|wire real service)	仮実装コメントが残っています。今すぐ事故とは限りませんが、意図を明確にした方が安全です。	期限・追跡先・恒久対応の方針をコメントや issue に残してください。
EOF
}

while IFS= read -r file; do
  [ -n "$file" ] || continue
  scan_file "$file"
done < "$TMP_FILES"

TOTAL_COUNT=$((MAJOR_COUNT + MINOR_COUNT + RECOMMENDATION_COUNT))
VERDICT="APPROVE"
if [ "$MAJOR_COUNT" -gt 0 ]; then
  VERDICT="REQUEST_CHANGES"
fi

if [ -n "$BASE_REF_INPUT" ] && [ "$SCAN_MODE" = "diff" ]; then
  BASE_REF_JSON="\"$(json_escape "$BASE_REF_INPUT")\""
else
  BASE_REF_JSON="null"
fi

printf '{'
printf '"tool":"review-ai-residuals",'
printf '"scan_mode":"%s",' "$(json_escape "$SCAN_MODE")"
printf '"base_ref":%s,' "$BASE_REF_JSON"
printf '"include_untracked":%s,' "$([ "$INCLUDE_UNTRACKED" -eq 1 ] && printf true || printf false)"
printf '"files_scanned":%s,' "$(append_json_string_array "$TMP_FILES")"
printf '"untracked_files_scanned":%s,' "$(append_json_string_array "$TMP_UNTRACKED_FILES")"
printf '"summary":{"verdict":"%s","major":%s,"minor":%s,"recommendation":%s,"total":%s},' \
  "$VERDICT" \
  "$MAJOR_COUNT" \
  "$MINOR_COUNT" \
  "$RECOMMENDATION_COUNT" \
  "$TOTAL_COUNT"
printf '"observations":%s' "$(append_json_object_array "$TMP_OBS")"
printf '}\n'
