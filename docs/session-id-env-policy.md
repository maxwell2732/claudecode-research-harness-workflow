# Session ID Env Policy (Phase 62.2.4)

> **Status**: Active (2026-05-07)
> **背景**: Claude Code `2.1.132` で Bash subprocess に `CLAUDE_CODE_SESSION_ID` が
> env var として渡るようになった。Harness の hook handler / shell wrapper / CLI helper で
> session ID を取得する経路を整理し、混乱を防ぐ。

## ひとことで

session ID の取得経路は **4 つ** あり、用途ごとに使い分ける。
hook handler は **stdin JSON (`.session_id`)** が正解で env var に依存しない。
Bash 子プロセスから session ID を読みたい時だけ env var (`CLAUDE_CODE_SESSION_ID`) を使う。

## たとえると

「家の鍵」と「車の鍵」を間違えないのと同じ。
hook handler は CC が「鍵を直接渡す」(stdin) ので、そっちを使う。
Bash 子プロセス (rg / jq / curl で起動した subshell) は CC から直接呼ばれないので、
「鍵置き場」(env var) から取る必要がある。

## 4 つの取得経路

| # | 経路 | 取得先 | 用途 |
|---|------|--------|------|
| 1 | stdin JSON `.session_id` | hook input | **hook handler の主経路** |
| 2 | `CLAUDE_CODE_SESSION_ID` env var | OS env | Bash 子プロセス、CLI helper |
| 3 | `.claude/state/session.json` の `.session_id` | local state | session-monitor / session-broadcast 等の長寿命 watcher |
| 4 | regex extract from `CLAUDE_TRANSCRIPT_PATH` | env var (regex) | **使わない (legacy)** |

## 使い分け

### (1) hook handler 内 → stdin JSON

```bash
SESSION_ID="$(printf '%s' "${INPUT}" | jq -r '.session_id // ""')"
```

理由: hook handler は CC から JSON 入力を受け取る。stdin JSON が SSOT。

env var に頼ると、複数 session 並列実行時に親 session の env が誤って継承される
リスクがある (Bash subprocess は親 env を継承するため)。

### (2) Bash 子プロセス → `CLAUDE_CODE_SESSION_ID` env var (CC 2.1.132+)

```bash
# 例: scripts/codex-companion.sh から起動した jq subprocess 内で session ID 必要時
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"
if [ -z "${SESSION_ID}" ]; then
  echo "[warn] CLAUDE_CODE_SESSION_ID not set; running on CC 2.1.131 or older" >&2
  SESSION_ID="unknown"
fi
```

理由: Bash 子プロセスは CC から直接 stdin を受け取らないので、env が唯一の経路。
CC `2.1.131` 以下では env var が無いため、`unknown` fallback が必要。

### (3) Long-running watcher → `.claude/state/session.json`

```bash
SESSION_ID="$(jq -r '.session_id // "unknown"' "${PROJECT_ROOT}/.claude/state/session.json")"
```

理由: session-monitor / session-broadcast 等は session 開始後に動き続けるため、
state file が SSOT。env / stdin は読めない。

### (4) regex extract from `CLAUDE_TRANSCRIPT_PATH` → 使わない

過去の例: `echo "$CLAUDE_TRANSCRIPT_PATH" | sed 's|.*/\([a-f0-9-]*\)\.json|\1|'`

問題:
- transcript path 形式が CC version で変わる可能性がある
- regex が壊れた場合の fallback が複雑
- `CLAUDE_CODE_SESSION_ID` env var が直接利用可能 (CC 2.1.132+)

**現行 Harness では使われていない**。新規実装でも採用しない。

## 3 状態テスト命名規約 (`.claude/rules/active-watching-test-policy.md` 準拠)

session ID 取得を扱う test scripts は以下の状態を全部 cover する。

| 状態 | 名前 | 期待挙動 |
|------|------|---------|
| Healthy | `TestSessionIdEnv_Healthy` | env var あり → そのまま使用 |
| NotConfigured | `TestSessionIdEnv_NotConfigured` | env 無し → state file fallback、警告は出さない |
| Corrupted | `TestSessionIdEnv_Corrupted` | env / state 両方無し → `unknown` fallback、警告を出す |

## 関連 doc

- `.claude/rules/active-watching-test-policy.md` — 3 状態テスト規約
- `docs/long-running-harness.md` — long-running session の env 継承
- Claude Code 2.1.132 CHANGELOG: Added `CLAUDE_CODE_SESSION_ID` environment variable to Bash tool subprocess environment

## Acceptance 条件 (Phase 62.2.4 DoD)

- [x] 4 経路の使い分けが docs に明記
- [x] hook handler は stdin JSON 経路 (env に依存しない) であることが明記
- [x] CC 2.1.131 以下の fallback が示されている
- [x] 3 状態テスト規約 (`.claude/rules/active-watching-test-policy.md`) と整合
- [x] regex extract from `CLAUDE_TRANSCRIPT_PATH` は使わないことが明記
