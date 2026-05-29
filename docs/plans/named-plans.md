# Named Plans Registry

Named plans let one repo keep multiple Plans files without making every harness
surface guess which file is authoritative.

## Files

- `Plans.md` remains the default plan.
- `plans/manifest.json` registers additional named plans.
- `.claude/state/active-plan.json` stores the currently selected plan for local
  harness commands.

Example manifest:

```json
{
  "schema_version": "plans-manifest.v1",
  "plans": {
    "default": "Plans.md",
    "roadmap": {
      "path": "plans/roadmap.md"
    }
  }
}
```

## Commands

```bash
scripts/plan-registry.sh list
scripts/plan-registry.sh path roadmap
scripts/plan-registry.sh switch roadmap
scripts/codex-loop.sh start all --plan roadmap
scripts/plans-issue-bridge.sh --plan roadmap --format markdown
node scripts/generate-sprint-contract.js --plan roadmap 9.1.1
```

`--plan NAME` is intentionally explicit for long-running or export flows. The
active plan is convenient for local work, but CI and release automation should
pass the plan name directly when more than one plan exists.

## Safety Rules

- Plan names may contain only letters, numbers, `_`, `.`, and `-`.
- Manifest paths must be relative to the project root.
- Absolute paths, `..` traversal, and symlink escapes outside the repo are
  rejected before any plan is read.
- `--plan` cannot be combined with an explicit `--plans PATH` argument in the
  issue bridge.

## Operational Rule

One harness run should use one named plan from start to finish. Do not switch the
active plan while `codex-loop` or a worker run is in progress; start another run
with a separate `--plan` value instead.
