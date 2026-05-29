# Skill Orchestration Design Contract

## Purpose

This document defines how Claude Code Harness treats skills as
machine-readable workflow parts, not only as long human instructions.

The goal is compatibility across four surfaces:

- Claude Code plugin skills in `skills/`
- Codex-native skills in `skills-codex/` and `codex/.codex/skills/`
- OpenCode mirrors in `opencode/skills/`
- local development mirrors in `.agents/skills/`

Existing slash command names and skill directory names stay stable. Harness
does not rename all skills into `ref-*`, `run-*`, `wrap-*`, `assign-*`, or
`delegate-*`. Those words are design shapes, not migration commands.

## Official Spec vs Harness Metadata

### Official skill frontmatter

Claude Code and Codex skill loaders understand a small set of operational
fields. Examples include:

- `name`
- `description`
- `allowed-tools`
- `argument-hint`
- `user-invocable`
- `disable-model-invocation`
- `context`
- `effort`

These fields control discovery, invocation, available tools, and runtime
behavior. If a field is not documented by the host runtime, Harness must not
pretend that the runtime enforces it.

### Harness design metadata

Harness adds optional metadata so CI, manifest generation, and reviewers can
inventory the skill system consistently:

- `kind`
- `purpose`
- `trigger`
- `shape`
- `role`
- `base`
- `pair`
- `owner`
- `since`
- `deprecated_in`
- `replaces`

These fields are Harness contract labels. They are not a replacement for the
official runtime fields above.

Missing metadata is allowed for non-core skills during rollout. Core workflow
skills must carry it once the CI gate is enabled.

## Skill Types

### Dictionary skills

Dictionary skills mainly give names, terms, policies, or rubrics. They are
used when the model needs a shared vocabulary.

Harness examples:

- `principles`
- `workflow-guide`
- `harness-review/references/security-profile.md`

Typical metadata:

```yaml
kind: reference
shape: dict
role: evaluator
```

### Workflow skills

Workflow skills perform a sequence of steps. They usually have entry checks,
execution rules, validation, and closeout.

Harness examples:

- `harness-plan`
- `harness-work`
- `harness-review`
- `harness-loop`
- `harness-release`

Typical metadata:

```yaml
kind: workflow
shape: workflow
role: executor
```

## Purpose / Trigger / Shape / Role

Harness uses four short labels to make skill routing inspectable.

| Field | Meaning | Example |
|---|---|---|
| `purpose` | What problem the skill exists to solve | `Execute Plans.md tasks end to end` |
| `trigger` | User wording or workflow event that should load it | `implement, execute, breezing` |
| `shape` | How the skill behaves structurally | `workflow`, `wrap`, `delegate`, `dict` |
| `role` | What responsibility it has in a team | `generator`, `executor`, `evaluator`, `orchestrator` |

The labels are intentionally small. They are for inventory and gates, not for
expressing every nuance of the text.

## Shape Values

| Shape | Use it when | Harness example |
|---|---|---|
| `dict` | The skill is mostly vocabulary, policy, rubric, or reference | `principles` |
| `workflow` | The skill owns a normal end-to-end procedure | `harness-plan` |
| `wrap` | The skill is a thin alias or adapter around another skill | `breezing` wraps `harness-work` |
| `delegate` | The skill mainly assigns work to another agent or runtime | `harness-loop` delegates to `harness-work` cycles |
| `evaluate` | The skill judges output and should avoid writes | `harness-review` |

`shape: wrap` must also set `base`. This lets CI catch wrappers that do not
declare what they wrap.

## Role Values

| Role | Responsibility | Guardrail |
|---|---|---|
| `generator` | Creates plans, tasks, or source material | Must preserve user intent and source of truth |
| `executor` | Changes files or runs implementation work | Must validate and avoid test gaming |
| `evaluator` | Reviews or judges output | Must be read-only unless an exception is documented |
| `orchestrator` | Coordinates workers, loops, or wrappers | Must not hide worker/reviewer boundaries |
| `synchronizer` | Reconciles state, plans, and git evidence | Must distinguish observed state from inference |

`role: evaluator` is special. The default contract is read-only: no `Write`,
`Edit`, or equivalent mutating tool. If a future evaluator truly needs writes,
it must document the exception and the CI gate must know about it.

## Base and Pair

`base` points from a wrapper or delegate skill to the skill it depends on.

Examples:

- `breezing` has `shape: wrap` and `base: harness-work`.
- `harness-release-internal` has `shape: wrap` and `base: harness-release`.
- `harness-loop` may use `shape: delegate` and `base: harness-work`.

`pair` points to the counterpart skill that naturally checks or complements
this skill.

Examples:

- `harness-work` pairs with `harness-review`.
- `harness-review` pairs with `harness-work`.
- `harness-plan` pairs with `harness-sync`.

`base` and `pair` are names, not file paths. Manifest generation resolves them
against known skill names.

## Generator / Evaluator Separation

Harness keeps creation and judgment separate.

- Generator/executor skills can create plans, implement code, or run changes.
- Evaluator skills inspect evidence and return verdicts.
- Orchestrators can coordinate both, but must keep the boundary visible.

Concrete example:

1. `harness-work` implements a Plans.md task.
2. `harness-review` independently reviews the output.
3. `breezing` coordinates worker and reviewer roles, but does not redefine the
   review contract.

This prevents a single skill from silently writing code and approving its own
work without an explicit review boundary.

## Surface Responsibilities

### `skills/`

`skills/` is the shared Claude Code plugin source of truth for normal shipped
skills. It should use official Claude Code frontmatter plus Harness design
metadata.

### `skills-codex/`

`skills-codex/` is the Codex-native override source of truth. Use it only when
the Codex tool model differs from Claude Code.

Examples:

- Codex uses native `spawn_agent`, `send_input`, `wait_agent`, and
  `close_agent`.
- Claude Code skill text may describe `Task` / `Agent` / `SendMessage`
  equivalents.

The design metadata should still describe the same conceptual skill unless the
Codex skill intentionally does something different.

### `codex/.codex/skills/`

This is the packaged Codex mirror. It is generated or checked from
`skills-codex/` when an override exists, otherwise from `skills/`.

Do not hand-edit this surface as the long-term source of truth.

### `opencode/skills/`

This is the OpenCode package mirror. It follows `skills/` unless a future
OpenCode-specific override is introduced.

### `.agents/skills/`

`.agents/skills/` is a local-only development mirror. It helps this repository
test itself while building itself, but it is not the public distribution source
of truth.

It can be synchronized for local work, but PR review and release checks should
distinguish it from shipped plugin and Codex package surfaces.

## Compatibility Policy

Harness keeps existing invocation names stable:

- `/harness-plan`
- `/harness-work`
- `/harness-review`
- `/harness-loop`
- `/breezing`
- `/harness-sync`
- `/release`

Design shapes are metadata, not user-facing rename instructions. A wrapper like
`breezing` can be labeled `shape: wrap` without becoming `/wrap-harness-work`.

## Manifest Contract

`scripts/generate-skill-manifest.sh` must include the Harness design metadata
fields for every skill. Non-core skills may emit `null` for fields that are not
yet specified.

Core workflow skills are expected to carry:

- `kind`
- `purpose`
- `trigger`
- `shape`
- `role`
- `owner`
- `since`

Wrappers must also carry `base`.

## CI Gate Contract

The CI gate should verify:

- core skill metadata is present
- `base` references an existing skill name
- `pair` references an existing skill name
- `shape: wrap` always declares `base`
- `role: evaluator` does not allow mutating tools unless explicitly exempted

The gate checks the contract. It does not replace human review of whether the
skill text is actually helpful.
