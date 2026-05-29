# harness-mem Managed Companion Contract

Claude-harness treats harness-mem as a managed companion, not as embedded code.

This contract keeps the boundary simple:

- Claude-harness owns orchestration: setup entrypoints, status display, hook wiring, compatibility checks, and safe user commands.
- harness-mem owns the runtime: daemon, local database, migrations, doctor logic, update logic, and deletion semantics.

## Standard Paths

Claude-harness assumes the harness-mem defaults below, but must not inspect the SQLite schema.

| Resource | Standard path |
|---|---|
| Runtime checkout | `~/.harness-mem/runtime/harness-mem` |
| Database | `~/.harness-mem/harness-mem.db` |
| Config | `~/.harness-mem/config.json` |
| Doctor artifact | `~/.harness-mem/runtime/doctor-last.json` |

Claude-harness may check whether these paths exist to decide whether harness-mem looks installed. It must not query, migrate, rewrite, or infer behavior from the database tables.

## Claude-harness CLI Surface

`harness mem` exposes the user-facing companion controls:

| Command | Behavior |
|---|---|
| `harness mem status [--json]` | Reads `harness-mem doctor --json --platform codex,claude --skip-version-check` when an installed CLI is available. Missing harness-mem is reported as `not_configured`, not as a broken Harness install. |
| `harness mem setup` | If doctor is not all-green or harness-mem is missing, runs non-interactive setup for `codex,claude` with auto-update enabled. |
| `harness mem update` | Delegates to `harness-mem update`. |
| `harness mem doctor` | Delegates to `harness-mem doctor --platform codex,claude` unless the caller passes a platform. |
| `harness mem off` | Delegates to `harness-mem recall off`. This disables contextual recall injection, not the database. |
| `harness mem purge --confirm-purge` | Delegates to `harness-mem uninstall --platform codex,claude --purge-db`. Without explicit confirmation it refuses to run. |
| `harness mem health` | Backward-compatible daemon health check for Session Monitor. |

`purge` is intentionally noisy and manual. Auto setup must never delete the database.

## Auto Setup

Plugin `Setup:init` may attempt companion setup once.

Default behavior:

```bash
npx -y --package @chachamaru127/harness-mem harness-mem setup \
  --platform codex,claude \
  --skip-quality \
  --auto-update enable
```

Rules:

- Default is on.
- Disable with `CLAUDE_CODE_HARNESS_MEM_AUTO_SETUP=0`.
- The attempt is marked in `.claude/state/harness-mem-companion-setup.json`.
- A failure must not fail Claude-harness setup.
- `SessionStart` must not run setup.
- Auto setup never runs `uninstall`, `purge`, or any database deletion command.

## harness-mem Doctor JSON

Claude-harness expects `harness-mem doctor --json` to return one JSON object with at least:

```json
{
  "status": "healthy",
  "all_green": true,
  "failed_count": 0,
  "checks": [],
  "fix_command": "harness-mem doctor --fix",
  "backend_mode": "local",
  "contract_version": "claude-harness-companion.v1",
  "harness_mem_version": "0.17.0"
}
```

Additional fields are allowed. Claude-harness treats malformed JSON as an unknown companion state and asks the user to run `harness mem doctor`.

## Compatibility Rules

- Claude-harness may call `setup`, `doctor`, `update`, `recall off`, and `uninstall --purge-db`.
- Claude-harness may forward `elicitation-event.v1` observations through `/v1/events/record` with `event_type: "elicitation_event"` when harness-mem is healthy.
- Claude-harness must not import harness-mem source files as libraries.
- Claude-harness must not directly read or mutate `~/.harness-mem/harness-mem.db`.
- Claude-harness must silently fall back to its local ledger when elicitation forwarding fails.
- harness-mem may change internal tables when it preserves this CLI and JSON contract.
- The contract version changes only when Claude-harness must alter behavior.
