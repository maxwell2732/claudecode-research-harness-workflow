# Bootstrap / Skill Trigger Acceptance

Phase 73 treats installation as incomplete until the first workflow trigger is
observable. Superpowers inspired this gate with explicit and implicit skill
trigger tests, but Harness keeps the claim boundary stricter: static packaging
evidence is not runtime support evidence.

## Required Harness Workflows

These workflows must exist on every claimed or internal-compatible surface:

| Workflow | Claude Code trigger | Codex CLI trigger | OpenCode trigger | Intent fixture |
|---|---|---|---|---|
| `harness-plan` | `/harness-plan` | `$harness-plan` | `harness-plan` skill | Create a scoped plan with acceptance criteria. |
| `harness-work` | `/harness-work` | `$harness-work` | `harness-work` skill | Execute the next `Plans.md` task with TDD and verification. |
| `harness-review` | `/harness-review` | `$harness-review` | `harness-review` skill | Review changes before merge. |
| `harness-release` | `/harness-release` | `$harness-release` | `harness-release` skill | Prepare release or PR closeout evidence. |
| `harness-setup` | `/harness-setup` | `$harness-setup` | `harness-setup` skill | Check install/setup health. |
| `breezing` | `/harness-work breezing all` | `$breezing all` | `breezing` skill | Run team execution for ready tasks. |

## Acceptance Rules

- Claude Code explicit and implicit trigger acceptance checks the shipped
  `skills/<name>/SKILL.md` entries.
- Codex acceptance checks `codex/.codex/skills/<name>/SKILL.md` and the
  companion route. Harness review/task delegation must use
  `scripts/codex-companion.sh task --write` and
  `scripts/codex-companion.sh review --base`; raw `codex exec` is not the
  Harness companion acceptance path.
- OpenCode acceptance checks `opencode/skills/<name>/SKILL.md` and the
  `opencode/plugins/harness-bootstrap.mjs` bootstrap transform. Native runtime
  smoke is required before public support wording can be raised.
- `not_observed != absent`: if a host runtime is unavailable, record the reason
  and keep the host at its current support tier.
- Release preflight must run the skill-trigger acceptance gate for claimed
  adapter surfaces. Claimed hosts without smoke evidence are release blockers;
  candidate and unsupported hosts stay as evidence docs only.

## Current Runtime Boundary

OpenCode native runtime smoke is not observed in this environment because the
local `opencode` command is a Superset wrapper whose real binary was not found.
The bootstrap plugin and static tests are therefore an `internal-compatible`
gate, not a public support claim.
