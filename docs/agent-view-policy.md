# Agent View (`claude agents`) Policy

CC `2.1.139`+ introduced `claude agents` (agent view, Research Preview) as a single entrypoint,
`2.1.141` added the `--cwd <path>` flag, and `2.1.142` added `--add-dir` / `--settings` / `--mcp-config` /
`--plugin-dir` / `--permission-mode` / `--model` / `--effort` / `--dangerously-skip-permissions`
flags.

Harness treats this as an **independent entrypoint for the Lead (operator) to monitor multiple Worker / Reviewer / Scaffolder sessions**, and keeps it separate from Harness internal teammate spawn workflows.

## Scope

| Target | Usage |
|--------|-------|
| Lead (operator, human) | Use `claude agents` to check the status of multiple projects in one view |
| Harness teammate spawn (Worker / Reviewer / Scaffolder) | Use Agent tool / breezing skill, not `claude agents` |
| Codex teammate | `bash scripts/codex-companion.sh task` (do not use raw `codex exec` or `claude agents`) |

## Operational Assumptions (2.1.139-2.1.142)

- `claude agents --json` can output a live session list as JSON (2.1.145). Limited to **diagnostic / scripting** use cases such as tmux-resurrect, status bars, and session pickers. Do not use as a substitute for Harness teammate spawn.
- Agent view shows **running / blocked on you / done** per session.
- `claude agents --cwd <path>` can scope the session list by directory (2.1.141).
- When launching `claude agents`, `--add-dir`, `--settings`, `--mcp-config`, `--plugin-dir`,
  `--permission-mode`, `--model`, `--effort`, `--dangerously-skip-permissions` can configure
  dispatched background sessions (2.1.142).
- A teammate launched in a background session retains its permission mode (2.1.141). It does not revert to default.

## Harness Safety Policy

### A. Permitted Uses

| Use case | Recommendation |
|----------|----------------|
| Working on the current project while checking the status of another project | `claude agents --cwd <other-project>` |
| Background dispatching a safe long-running task (test / lint) in another project | `claude agents --cwd <path> --permission-mode default --effort low` |
| Read-only investigation tasks (when you want to check results immediately) | Parallel launch via `claude agents` |

### B. Flag Usage Conditions

| Flag | Usage condition | Prohibited condition |
|------|----------------|---------------------|
| `--cwd <path>` | When viewing the state of another project | --- |
| `--add-dir` | When expanding search scope | Paths containing secrets within the same dir (`.env*`, `secrets/**`, `.ssh/**`) are opt-in prohibited even after denyRead |
| `--settings <path>` | During development to try project-specific settings | Continuously overriding `.claude-plugin/settings.json` per agent is prohibited (SSOT collapse) |
| `--mcp-config <path>` | When trialing a temporary MCP server | Persistent project MCP must be unified in `.mcp.json` |
| `--plugin-dir <path>` | For local testing of unpublished plugins | --- |
| `--permission-mode <mode>` | Specify `default` / `acceptEdits` / `plan` explicitly | Using `bypassPermissions` on protected branches (`main`/`master`) is prohibited |
| `--model <model-id>` | Temporary model switching | Downgrading to a smaller model for release / hotfix sessions is prohibited |
| `--effort <level>` | Setting intensity based on task scale | Guard rails (R01-R13) must not be relaxed via effort |
| `--dangerously-skip-permissions` | Only within trusted ephemeral sandboxes | Prohibited for (a) sessions on protected branches, (b) sessions reading credentials, (c) production deployment sessions |

### C. Separation from Teammate Spawn

- `claude agents` is a **UI for the operator (human Lead) to view multiple sessions**.
  Harness internal teammate spawn (Worker / Reviewer / Scaffolder) is launched via **Agent tool / breezing skill**.
- Worker / Reviewer must not spawn other sessions from `claude agents`. Lead-only (see permission and responsibility boundaries in `.claude/rules/opus-4-7-prompt-audit.md`).
- Breezing skill uses `claude --teammate-mode in-process` / `tmux`. It does not depend on `claude agents`.

### D. Background Permission Mode Retention (2.1.141)

- A teammate backgrounded via `/bg` / `←←` or `claude agents` retains the permission mode it was launched with.
- **No need to re-inject permission mode** on the Harness side. The breezing teammate launch contract can be used as-is.
- Confirmation: if a teammate was launched in `plan` mode, it remains in `plan` mode after being backgrounded (guaranteed by CC itself).

### E. Recommended Agent View Launch Order

1. Operator opens an interactive session with `claude`.
2. Use `claude agents` as needed to check the state of other sessions.
3. When dispatching a separate task, explicitly use `claude agents --cwd <path> --permission-mode <mode> --effort <level>`.
4. When the Lead starts breezing, launch via `/breezing` skill rather than through `claude agents`.

## Violation Examples

| Violation | Impact | Recommended action |
|-----------|--------|-------------------|
| Worker subagent calls `claude agents` to spawn another session | Permission boundary collapse (only Lead can spawn) | Remove `claude agents` call from Worker procedure |
| `claude agents ... --dangerously-skip-permissions` on protected branch (`main`) | Guard rail (R12 ask) bypass | Use `--permission-mode default` or `acceptEdits` |
| Overwriting `.claude-plugin/settings.json` with `--settings` per agent | Settings SSOT collapse | Centralize changes in project-level `.claude/settings.local.json` |
| Using `--dangerously-skip-permissions` in a session handling credentials (e.g., `harness-mem`) | Risk of secrets leakage | Remove the flag |

## CI / Gate

- `tests/validate-plugin.sh` does not verify the existence of `claude agents` flags (as they are CC core features).
- Instead, permission boundaries in `.claude/rules/opus-4-7-prompt-audit.md` and deny rules in `.claude-plugin/settings.json` function as layered defense.
- To audit `claude agents` usage operationally, record env `CLAUDE_CODE_SESSION_ID` via webhook (`scripts/hook-handlers/webhook-notify.sh`).

## Related

- `docs/team-composition.md` — SSOT for teammate spawn and parallelism
- `agents/worker.md` — Worker contract
- `.claude/rules/opus-4-7-prompt-audit.md` — Agent contract audit rules (Lead-only spawn explicitly stated)
- `docs/upstream-update-snapshot-2026-05-15.md` — Phase 69 snapshot
- `docs/upstream-update-snapshot-2026-05-27.md` — Phase 80 snapshot
- `.claude/rules/hooks-2.1.139-plus.md` — Hook-related 2.1.133+ rules
- `.claude/rules/hooks-2.1.152-plus.md` — MessageDisplay / reloadSkills / sessionTitle (2.1.152+)

## Review Conditions

- When CC `claude agents` graduates to GA (exits Research Preview) → Review the entire policy
- When `--dangerously-skip-permissions` flag is deprecated / renamed → Update the relevant cell
- When Harness teammate spawn can be integrated with the `claude agents` API → Reconsider Section C (separation from teammate spawn)
