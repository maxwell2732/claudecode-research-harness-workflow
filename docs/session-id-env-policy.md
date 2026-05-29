# Session ID Env Policy (Phase 62.2.4)

> **Status**: Active (2026-05-07)
> **Background**: Since Claude Code `2.1.132`, `CLAUDE_CODE_SESSION_ID` is passed as an env var to Bash subprocesses. This document clarifies the paths for obtaining the session ID in Harness hook handlers, shell wrappers, and CLI helpers to prevent confusion.

## In a nutshell

There are **4** ways to obtain the session ID; use each for the right purpose.
Hook handlers should use **stdin JSON (`.session_id`)** — do not rely on the env var.
Use the env var (`CLAUDE_CODE_SESSION_ID`) only when a Bash child process needs to read the session ID.

## Analogy

Like not mixing up a house key and a car key.
Hook handlers receive the key directly from CC (stdin), so use that.
Bash child processes (subshells launched by rg / jq / curl) are not called directly by CC,
so they need to get the key from the key rack (env var).

## 4 paths

| # | Path | Source | Use case |
|---|------|--------|----------|
| 1 | stdin JSON `.session_id` | Hook input | **Primary path for hook handlers** |
| 2 | `CLAUDE_CODE_SESSION_ID` env var | OS env | Bash child processes, CLI helpers |
| 3 | `.claude/state/session.json` `.session_id` | Local state | Long-lived watchers such as session-monitor / session-broadcast |
| 4 | Regex extract from `CLAUDE_TRANSCRIPT_PATH` | Env var (regex) | **Do not use (legacy)** |

## Usage guide

### (1) Inside hook handler → stdin JSON

```bash
SESSION_ID="$(printf '%s' "${INPUT}" | jq -r '.session_id // ""')"
```

Reason: Hook handlers receive JSON input from CC. stdin JSON is the SSOT.
Relying on the env var risks inheriting the parent session's env in concurrent multi-session execution (Bash subprocesses inherit parent env).

### (2) Bash child process → `CLAUDE_CODE_SESSION_ID` env var (CC 2.1.132+)

```bash
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"
if [ -z "${SESSION_ID}" ]; then
  echo "[warn] CLAUDE_CODE_SESSION_ID not set; running on CC 2.1.131 or older" >&2
  SESSION_ID="unknown"
fi
```

Reason: Bash child processes do not receive stdin directly from CC, so the env var is the only path.
The env var is absent on CC `2.1.131` and older, so an `unknown` fallback is required.

### (3) Long-running watcher → `.claude/state/session.json`

```bash
SESSION_ID="$(jq -r '.session_id // "unknown"' "${PROJECT_ROOT}/.claude/state/session.json")"
```

Reason: session-monitor / session-broadcast continue running after session start, so the state file is the SSOT. env / stdin are not readable.

### (4) Regex extract from `CLAUDE_TRANSCRIPT_PATH` → do not use

Past example: `echo "$CLAUDE_TRANSCRIPT_PATH" | sed 's|.*/\([a-f0-9-]*\)\.json|\1|'`

Problems:
- Transcript path format may change across CC versions
- Complex fallback when regex breaks
- `CLAUDE_CODE_SESSION_ID` env var is directly available (CC 2.1.132+)

**Not used in current Harness.** Do not adopt in new implementations.

## 3-state test naming convention (per `.claude/rules/active-watching-test-policy.md`)

Test scripts handling session ID retrieval must cover all of the following states:

| State | Name | Expected behavior |
|-------|------|-------------------|
| Healthy | `TestSessionIdEnv_Healthy` | env var present → use as-is |
| NotConfigured | `TestSessionIdEnv_NotConfigured` | No env → fall back to state file; no warning |
| Corrupted | `TestSessionIdEnv_Corrupted` | Both env and state missing → `unknown` fallback; emit warning |

## Related docs

- `.claude/rules/active-watching-test-policy.md` — 3-state test convention
- `docs/long-running-harness.md` — env inheritance in long-running sessions
- Claude Code 2.1.132 CHANGELOG: Added `CLAUDE_CODE_SESSION_ID` environment variable to Bash tool subprocess environment

## Acceptance criteria (Phase 62.2.4 DoD)

- [x] 4 paths and their use cases documented
- [x] Hook handlers use stdin JSON path (no env dependency) — documented
- [x] Fallback for CC 2.1.131 and older is shown
- [x] Aligned with 3-state test convention (`.claude/rules/active-watching-test-policy.md`)
- [x] Regex extract from `CLAUDE_TRANSCRIPT_PATH` documented as not to be used
