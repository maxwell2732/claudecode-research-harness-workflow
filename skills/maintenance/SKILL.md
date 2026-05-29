---
name: maintenance
description: "File cleanup and archiving. Tidies up bloated Plans.md, session-log.md, old logs, and state files. Trigger: /maintenance, cleanup, archive, organize, split session-log. Do NOT load for: implementation, review, release, new feature development."
description-en: "File cleanup and archiving. Tidies up bloated Plans.md, session-log.md, old logs, and state files. Trigger: /maintenance, cleanup, archive, organize, split session-log. Do NOT load for: implementation, review, release, new feature development."
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
argument-hint: "[plans|session-log|logs|state|all] [--dry-run]"
user-invocable: true
effort: low
---

# Maintenance

A single-purpose skill for tidying up messy files. Invoke when auto-cleanup-hook issues a warning,
or as routine housekeeping.

> **Prerequisite**: Before destructive operations (archiving, line deletion), confirm that important
> information in Plans.md / session-log.md has been promoted to SSOT (decisions.md / patterns.md).
> If not yet synced, run `/memory sync` first.

## Quick Reference

| Subcommand | Target | Typical Trigger |
|-----------|--------|----------------|
| `maintenance plans` | Archive completed tasks in Plans.md | "Organize Plans.md", "Move old tasks" |
| `maintenance session-log` | Monthly split of session-log.md | "Split session-log", "Log is too long" |
| `maintenance logs` | Delete old files in `.claude/logs/` | "Clean up logs", "Delete logs older than 30 days" |
| `maintenance state` | Trim `agent-trace.jsonl` / `harness-usage.json` | "Trace is bloated", "Compress state" |
| `maintenance all` | Run all 4 in sequence | "Organize everything", "Full cleanup" |

Add `--dry-run` to only list what would be done without executing. Free-form instructions (e.g.
"delete old archives too", "keep only this session-log") are parsed in Step 1 and applied
to processing parameters in Step 2 and beyond.

## Execution Steps

1. **Parse user instructions**: Extract subcommand + free-form details (exclusions, destination, day threshold)
2. **SSOT sync check**: If `.claude/state/.ssot-synced-this-session` is absent,
   prompt to run `/memory sync` (required only when touching Plans.md)
3. **Open reference file**: Read `${CLAUDE_SKILL_DIR}/references/cleanup.md` and execute the relevant section
4. **Report Before/After**: Display line counts and deletion counts when done

## Subcommand Details

For execution steps, thresholds, and archive destinations per target, see [cleanup.md](./references/cleanup.md).

## Integration with auto-cleanup-hook

The PostToolUse hook (`scripts/auto-cleanup-hook.sh` / Go version `auto_cleanup_hook.go`) detects
line count overruns in Plans.md, session-log.md, and CLAUDE.md and returns
`Recommend archiving old tasks with /maintenance` as feedback.
When you see this warning, run the relevant subcommand.

## Notes

- **Do not move in-progress tasks**: `cc:WIP`, `pm:requested`, `cursor:requested` are excluded from archiving
- **Archive destination directory is fixed**: `.claude/memory/archive/` — confirm with user before moving elsewhere
- **Backup**: Before editing files over 200 lines, take a local backup with `cp <file> <file>.bak.$(date +%s)`
- **CLAUDE.md is warning-only**: Do not auto-edit. Only propose a split

## Related Skills

- `memory` — SSOT promotion before organizing Plans.md (updates decisions.md / patterns.md)
- `harness-setup` — Periodic maintenance after setup can also be invoked via `harness-setup`
- `session-init` — Controls maintenance recommendation notifications at session start
