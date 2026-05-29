---
name: harness-plan
description: "HAR: Research-backed, team-validated task planning, Plans.md management, progress sync. Trigger: create a plan, add tasks, update Plans.md, mark complete, check progress. Do NOT load for: implementation, review, release."
description-en: "HAR: Research-backed, team-validated task planning, Plans.md management, progress sync. Trigger: create a plan, add tasks, update Plans.md, mark complete, check progress. Do NOT load for: implementation, review, release."
kind: workflow
purpose: "Maintain co-required planning output for the spec.md product contract and Plans.md task contract"
trigger: "create a plan, add tasks, update Plans.md, check progress"
shape: workflow
role: generator
pair: harness-sync
owner: harness-core
since: "2026-05-05"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "WebSearch", "Task"]
argument-hint: "[create|add|update|sync|sync --no-retro|--ci]"
user-invocable: true
effort: medium
---

# Harness Plan

The integrated planning skill of Harness.
Consolidates the following 3 legacy skills:

- `planning` (plan-with-agent) — converting ideas → Plans.md
- `plans-management` — task state management and marker updates
- `sync-status` — Plans.md and implementation sync verification

## Quick Reference

| User input | Subcommand | Action |
|------------|------------|------|
| "Create a plan" / `/harness-plan create` | `create` | Spec delta / skip reason → generate Plans.md tasks |
| "Add a task" / `/harness-plan add` | `add` | Add new task to Plans.md |
| "Mark as complete" / `/harness-plan update` | `update` | Change task marker to cc:done |
| "Where are we?" / `/harness-plan sync` | `sync` | Cross-reference and sync implementation with Plans.md |
| `/harness-sync` | `sync` | Progress check (equivalent to independent sync surface) |
| `/harness-plan create` | `create` | Create plans with spec.md / Plans.md dual-source |
| `/harness-plan list` | `list` | List named Plans from `plans/manifest.json` |
| `/harness-plan switch <name>` | `switch` | Save active plan to `.claude/state/active-plan.json` |

## Literal companion commands (CC 2.1.108+)

- `/recap`: Run sync after getting a fresh summary when you return after a break
- `/undo`: Alias for `/rewind`. Use when you want to immediately revert the last plan update

## Subcommand Details

### Standard planning quality contract

See [references/planning-quality.md](${CLAUDE_SKILL_DIR}/references/planning-quality.md)

`harness-plan` is a planning surface that produces co-required planning output of spec.md product contract and Plans.md task contract.
Precedence remains `spec.md > sub-spec > Plans.md`.
Plans.md is a task ledger; root `spec.md` is a product contract; the hierarchy must not be broken.
Do not convert provided information directly into Plans.md.
For plan creation and significant task additions, verify the latest information, existing specifications, memory, and TeamAgent / sub-agent multi-perspective discussions,
and only convert elements worth incorporating into this product into task contracts.
`/harness-plan create` returns `Spec delta` or `Spec skip reason` paired with `Plans.md` task generation.
Output must always include `Spec delta` or `Spec skip reason`.
Harness generates `Spec delta` / `Spec skip reason`; the consumer only approves or revises.

**Non-trivial planning gate**:

Planning that is not single-instance or lightweight is treated as requiring TeamAgent or sub-agents.
Non-trivial here refers to requests affecting multiple tasks / multiple files / multiple sessions / product behavior / API / data model / permissions / billing / external integrations / distribution surfaces / security.
If the Task tool is available, run independent perspectives for Product / Architecture / Security / QA / Skeptic.
If unavailable, explicitly state "sub-agent not used" and evaluate the same perspectives separately.

Non-trivial planning output must always include the following verifications.

- `team_validation_mode`: `not_required_lightweight` / `native` / `subagent` / `manual-pass` / `unavailable`
- Consistency of `spec.md` / sub-spec / `Plans.md`
- Wheel-reinvention prevention check via harness-mem / harness-recall / repo memory
- Not deviating from the product purpose
- No issues with security, permissions, secrets, or supply chain
- Whether lint / formatter baseline exists; if a plan with source code changes has none configured, place a setup task before implementation tasks
- Whether the plan actually works — i.e., whether test / smoke / CI / review / release gates are included in task DoD

Use `team_validation_mode: not_required_lightweight` for lightweight tasks.
For non-trivial planning, use one of `native` / `subagent` / `manual-pass`.
Must not leave it as `unavailable` and make it Required.
Product / Architecture / Security / QA / Skeptic are verification perspectives, not agent_type names.
Request them as perspectives from available TeamAgent / Task sub-agents; do not require arbitrary agent spawning.
The Security gate does not require actual reading of secrets.
If reading `.env` or secrets becomes necessary, stop at a Risk Gate and verify using allowed existing guards / evidence.

**When to apply**:

- Creating a new plan with `create`
- Adding tasks with `add` that affect product behavior / API / permissions / billing / external integrations / distribution surfaces
- User has provided external products, competitors, specification proposals, improvement ideas, or comparison materials
- There is a risk of conflict with existing specifications or past decisions

**When to treat lightly**:

- `update` with only marker updates
- `sync` with only status reconciliation
- typo, format, README/CHANGELOG only
- Narrow changes where the correct answer is fixed by existing spec and tests

**Quality flow**:
1. Decompose input, clearly state evaluation targets, scoring axes, and uncertain facts
2. Get latest information. Prioritize WebSearch / official docs / primary sources for external facts; cross-check important points against multiple sources
3. Check existing specifications, root `spec.md`, Plans.md, README, docs, CLAUDE.md, related skills
4. Check available memory surfaces project-scoped: harness-mem / harness-recall / `.claude/agent-memory/` / `.claude/state/`, etc.
5. For non-trivial planning, use TeamAgent / Task sub-agents for independent review from different perspectives such as Product / Architecture / Security / QA / Skeptic
6. For plans with source code changes, check lint / formatter baseline; if not configured, add setup task first
7. Output neutral scoring review and classify as Required / Recommended / Optional / Reject
8. Report proposal content, reason, and what changes in `$easy` format
9. Incorporate only adopted proposals into root `spec.md` / Plans.md / test tasks

### create — Plan creation

See [references/create.md](${CLAUDE_SKILL_DIR}/references/create.md)

Interview for ideas and requirements, then generate an actionable Plans.md.

**Flow**:
1. Check conversation context (extract from preceding discussion or new interview)
2. Ask what to build (max 3 questions)
3. **Planning quality check** (latest information, existing specs, memory, TeamAgent / sub-agent multi-perspective review, scoring)
4. Technical research (WebSearch)
5. Feature list extraction
6. **spec.md / Plans.md dual-source check** (Spec delta or Spec skip reason + Plans.md tasks)
7. Priority matrix (Required / Recommended / Optional / Reject)
8. TDD adoption decision (test design)
9. Generate Plans.md (with `cc:TODO` markers)
10. Next action guidance

### spec.md / Plans.md dual-source check (default)

Plans.md is treated as the task contract for "what needs to be done"; root `spec.md` is treated as the product contract for "what is correct."
Co-required planning output means making both outputs required; precedence remains `spec.md > sub-spec > Plans.md`.
When implementation is likely to drift, update root `spec.md` before generating Plans.md.
`create` and product-impacting `add` always read root `spec.md`.

Priority for storage location:

1. Root `spec.md`
2. Only when consumer repo has no root `spec.md`: existing project spec / architecture / product compass
3. Only when consumer repo has no root `spec.md`: `docs/spec/00-project-spec.md`
4. For repos with existing conventions, follow the spec path per those conventions

Conditions requiring creation/update:

- Tasks that decide user-visible behavior, API, data model, permissions, billing, or external integrations
- Tasks where multiple implementation policies exist and the choice changes product behavior
- Tasks where "spec ambiguity caused implementation drift" is evident in past or current conversations
- Tasks where the work content is in Plans.md but the project's correct conditions are not in a stable document

Conditions not requiring it:

- typo, format, dependency bump, README/CHANGELOG only
- Narrow refactor without behavior changes
- Fixes where the correct answer is sufficiently fixed by existing spec and tests

Output contract:

- `Spec delta`: When updating the product contract, write the target spec path and what changes
- `Spec skip reason`: When not updating the product contract, write the reason
- Harness generates `Spec delta` / `Spec skip reason`; the consumer only approves or revises
- Leave `Spec skip reason` in task context / sprint contract even for docs-only / mechanical tasks
- Do not assert absent for missing search results, unavailable memory, or unread files. `not_observed != absent`
- Do not have the user write the spec from scratch. The agent creates the minimum delta from existing spec and input, only presenting decision branches when ambiguous

Reference:

- `docs/plans/spec-ssot.md`

### Session launch guidance after create (required)

After `create` completes, do not end with just an explanation; always provide the **new session launch command** and
**the first instruction prompt to enter right after launch** as a set.

Priority order:

1. Only 1 incomplete task, or natural to start with just the first one
   - Launch command: `claude`
   - First input: `/harness-work <task number>`
2. Multiple tasks with loose dependencies, natural to advance together
   - Launch command: `claude`
   - First input: `/breezing all`
   - Alternative: `/harness-work all`
3. Long-running execution or re-entry required
   - Launch command: `ENABLE_PROMPT_CACHING_1H=1 claude`
   - First input: `/harness-loop all`
   - Alternative: `/breezing all`

Include at least these 3 lines:

- `New session launch command:`
- `First input after launch:`
- `Suited for:`

Example:

```text
New session launch command: claude
First input after launch: /breezing all
Suited for: Phase 1 has multiple tasks and advancing them together is most natural
```

When recommending long-running mode, also include the Claude Code session launch command:

```text
New session launch command: ENABLE_PROMPT_CACHING_1H=1 claude
First input after launch: /harness-loop all
Suited for: Long-running tasks where waits exceeding 5 minutes or resumptions across sessions are likely
```

Note:

- `scripts/claude-longrun.sh` is a development helper script for this repository and is not distributed to consumer environments after plugin install
- Therefore, for consumer-facing guidance, always prioritize the single-line command `ENABLE_PROMPT_CACHING_1H=1 claude`
- When in a local checkout and you want to use an equivalent wrapper only during repository development, `bash scripts/claude-longrun.sh` may be used

**CI mode** (`--ci`):
No interview. Use existing Plans.md as-is and only perform task decomposition.

### add — Add task

Add a new task to Plans.md.
For product-impacting additions, output `Spec delta` or `Spec skip reason` following the "spec.md / Plans.md dual-source check" above.

```
/harness-plan add task name: detailed description [--phase phase number]
```

Tasks are added with the `cc:TODO` marker.

### update — Marker update

Change task status markers.

```
/harness-plan update [task name|task number] [WIP|done|blocked]
```

Marker mapping:

| Command | Marker |
|---------|---------|
| `WIP` | `cc:WIP` |
| `done` / `complete` | `cc:done` |
| `blocked` | `blocked` |
| `TODO` | `cc:TODO` |

### sync — Progress sync

Cross-reference implementation status with Plans.md, detect differences, and update.

See [references/sync.md](${CLAUDE_SKILL_DIR}/references/sync.md)

**Flow**:
1. Get current state of Plans.md
2. Detect Plans.md format (v1: 3 columns / v2: 5 columns)
3. Get implementation status from git status / git log
4. Check agent trace (`.claude/state/agent-trace.jsonl`)
5. Detect differences between Plans.md and implementation
6. Propose auto-fix for outdated markers
7. Present next actions

**Retrospective** (default ON):
Automatically run a retrospective if there is at least 1 `cc:done` task.
Analyze estimate accuracy, block cause patterns, and scope fluctuation; record learnings.
Can be explicitly skipped with `sync --no-retro`.

### team mode / issue bridge

Keep Plans.md as the source of truth; use GitHub Issue integration only in opt-in team mode.

- Do not use bridge in solo development
- Team mode creates one tracking issue and generates sub-issue payloads per task in dry-run
- `scripts/plans-issue-bridge.sh` never actually updates GitHub; always returns dry-run payloads
- This bridge does not modify Plans.md

Reference:

- `docs/plans/team-mode.md`

### named Plans

When using multiple Plans.md, use `plans/manifest.json` as the source of truth and select by name.

```bash
scripts/plan-registry.sh list
scripts/plan-registry.sh switch roadmap
scripts/plans-issue-bridge.sh --plan roadmap --format markdown
node scripts/generate-sprint-contract.js --plan roadmap 9.1.1
```

Operating rules:

- Only use one named plan per run
- Pass `--plan <name>` explicitly for long-running / CI / issue bridge rather than relying on the active pointer
- Manifest path is project root relative only. Absolute paths, `..`, and out-of-repo symlinks are rejected

Reference:

- `docs/plans/named-plans.md`

## Plans.md Format Convention

### Format

```markdown
# [Project name] Plans.md

Created: YYYY-MM-DD

---

## Phase N: Phase name

| Task | Content | DoD | Depends | Status |
|------|------|-----|---------|--------|
| N.1  | Description | Tests pass | - | cc:TODO |
| N.2  | Description | lint errors 0 | N.1 | cc:WIP |
| N.3  | Description | Migration executable | N.1, N.2 | cc:done |
```

**DoD (Definition of Done)**: Write the verifiable completion condition in one line. "Looks good" or "works properly" are prohibited. Must be determinable Yes/No.

**Depends**: Task dependencies. `-` (no dependency), task number (`N.1`), comma-separated (`N.1, N.2`), phase dependency (`Phase N`).

### TDD tags

Tasks in Plans.md can have TDD judgment tags in their content or DoD.

| Tag | Meaning | `tdd_required` inference |
|------|------|--------------------|
| `[tdd:required]` | This task must write failing tests first | `true` |
| `[tdd:skip:<reason>]` | This task skips TDD with a reason | `false`, `skip_tdd_reason=<reason>` |

Do not leave `<reason>` empty.
Examples: `[tdd:skip:docs-only]`, `[tdd:skip:no-test-framework-detected]`.

When no tag is present, infer `tdd_required` in this order:

1. Plans.md tag: `[tdd:required]` / `[tdd:skip:<reason>]`
2. Files: required if task includes source implementations under `src/`, `app/`, `cmd/`, `lib/`, `pkg/`, `internal/`, `go/`, etc.
3. Scaffolder inference: not required with skip reason if docs-only or no test framework detected

### optional briefs / manifest

`harness-plan create` only attaches a brief when needed.

- project spec SSOT is a document that fixes the correct conditions for the entire project, created only when needed
- `design brief` for tasks with UI
- `contract brief` for tasks with API
- A brief is a short supplementary document that fixes "what to build"; it does not replace Plans.md or spec SSOT
- The list of skill frontmatter can be generated as machine-readable JSON with `scripts/generate-skill-manifest.sh`

References:

- `docs/plans/briefs-manifest.md`
- `docs/plans/spec-ssot.md`

### Marker list

| Marker | Meaning |
|---------|------|
| `pm:requested` | Requested by PM |
| `cc:TODO` | Not started |
| `cc:WIP` | In progress |
| `cc:done` | Worker work complete |
| `pm:confirmed` | PM review complete |
| `blocked` | Blocked (always include reason) |

## Related Skills

- `harness-sync` — Sync implementation with Plans.md
- `harness-work` — Implement planned tasks
- `harness-review` — Review implementations
- `harness-setup` — Project initialization
