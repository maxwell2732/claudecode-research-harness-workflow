# create subcommand — Plan Creation Flow

Interview for ideas and requirements, then generate an actionable Plans.md.

## Step 0: Check conversation context

If requirements can be extracted from the preceding conversation, confirm:

> Choose how to create the plan:
> 1. From the previous conversation — create a plan based on brainstorm content
> 2. From scratch — start from an interview

For "From the previous conversation": extract requirements, ideas, and decisions and confirm with user.
After confirmation, skip to Step 3 (technical research).

## Step 1: Ask what to build

If no user input, ask:

> What do you want to build?
>
> Examples: reservation management system / blog site / task management app / API server
>
> A rough idea is fine!

## Step 2: Increase resolution (max 3 questions)

> Tell me a little more:
>
> 1. Who will use it? (Just you? A team? Public?)
> 2. Are there any services you'd like to reference?
> 3. How far do you want to take it? (MVP? Full features?)

## Step 3: Planning quality check

Details: `references/planning-quality.md`

Do not convert user-provided information directly into Plans.md.
If the input includes external products, competitors, specification proposals, improvement ideas, or comparison materials, verify with the latest information, existing specifications, memory, and TeamAgent / sub-agent multi-perspective review, and include only elements worth incorporating as task contracts.
For non-trivial, non-lightweight planning, treat it as requiring TeamAgent or sub-agents.

Minimum checks:

- Latest information: Prioritize WebSearch / official docs / primary sources; verify important points against multiple sources
- Existing specifications: Check Plans.md, README, docs, CLAUDE.md, related skills, tests
- Memory: If harness-mem / harness-recall / `.claude/agent-memory/` / `.claude/state/` are available, check project-scoped to avoid reinventing the wheel
- Discussion: Assess adoption value and risks from Product / Architecture / Security / QA / Skeptic perspectives
- Quality foundation: For plans with source code changes, check `formatter_baseline`; if lint / formatter are not configured, add a setup task first
- Implementation plan validation: Verify product fit, security fit, works in practice; incorporate test / smoke / CI / review / release gates into DoD
- Scoring: Rate Product Fit, Evidence Strength, User Value, Implementation Feasibility, Regression Safety, Strategic Leverage, Security Safety, Works In Practice on a 5-point scale

Do not directly read the harness-mem DB. If search or documented memory surfaces are unavailable, explicitly state "memory unverified".
If the Task tool is unavailable, explicitly state "sub-agent not used" and evaluate the same perspectives separately on your own.
Output one of `not_required_lightweight` / `native` / `subagent` / `manual-pass` / `unavailable` for `team_validation_mode`.
For non-trivial planning, use one of `native` / `subagent` / `manual-pass`; do not leave it as `unavailable` when Required.
Product / Architecture / Security / QA / Skeptic are perspective names, not agent_type names.
The Security gate does not require reading `.env` or secrets.

For small typo, format, README/CHANGELOG, or marker-only updates, this step can be lightweight.

## Step 4: Technical research (WebSearch)

Claude Code researches and proposes without asking the user.

```
WebSearch:
- "{{project type}} tech stack 2025"
- "{{similar service}} architecture"
```

## Step 4.4: spec.md / Plans.md dual-source check

Plans.md is a task contract that fixes "what needs to be done."
Root `spec.md` is a product contract that fixes "what is correct."
Do not mix these two. `/harness-plan create` is not a Plans.md generation command but a surface that returns co-required planning output of spec.md product contract and Plans.md task contract.
Precedence remains `spec.md > sub-spec > Plans.md`.

The output of `/harness-plan create` must always be this pair:

1. `Spec delta` or `Spec skip reason`
2. `Plans.md` task generation

Read root `spec.md` every time. If implementation decisions are likely to drift, update root `spec.md` before creating Plans.md.
Do not have the user write the spec from scratch. Harness generates `Spec delta` / `Spec skip reason`; the consumer only approves or revises.
The agent drafts the minimum delta from existing spec, repo evidence, memory, tests, and input requirements, and only presents choices when a decision is contested.

### Conditions for creating/updating the specification source

- User-visible behavior increases or changes
- Deciding on API, data model, permissions, billing, external integrations, or tenant boundaries
- There are multiple implementation options and the choice changes product behavior
- Implementation drift due to ambiguous specs is visible in past or current conversations
- Plans.md has tasks but the project's correct conditions are not documented

### Conditions for skipping

- Typo / format / lint only
- Dependency bump only
- README / CHANGELOG only
- docs-only / mechanical task
- Narrow refactor without behavior changes
- Correct answer is clear from existing spec and tests

Do not omit `Spec skip reason` even when skipping.
Leave skip reason in task context / sprint contract even for docs-only / mechanical tasks.

### Storage location

First priority is root `spec.md`.
Only update an existing project-level spec as a fallback when the consumer repo has no root `spec.md`.
If neither root `spec.md` nor an existing project spec exists, create:

```text
docs/spec/00-project-spec.md
```

The first spec can be short. At minimum, include Purpose, Users And Workflows, Core Rules, Data And Contracts, Non-Goals, Open Decisions, and Links.

Details: `docs/plans/spec-ssot.md`

## Step 4.6: Lint / formatter baseline check

For plans with source code changes, check the lint / formatter baseline before creating implementation tasks.
This is not "cleaning up work" but a gate to first establish a foundation where quality can be confirmed as Yes/No after implementation.

What to check:

- JavaScript / TypeScript: `lint` / `format` scripts in `package.json`, ESLint / Prettier / Biome / Oxlint / dprint config or dependencies
- Python: Ruff / Black / isort / mypy config in `pyproject.toml`
- Go: `gofmt` / `go test` / `go vet` / CI equivalent commands
- Rust: `cargo fmt` / `cargo clippy` / `cargo test`
- Existing CI: quality commands in `.github/workflows`, `scripts/ci/*`, `Makefile`, etc.

Include `formatter_baseline` in the output:

```text
formatter_baseline: configured | missing | not_applicable | unknown
formatter_baseline_evidence: [file / command seen]
formatter_baseline_action: none | add_setup_task | skip_with_reason | spike
```

If not configured and the plan includes source code changes, add a setup task before the implementation tasks in Plans.md.
The setup task's DoD is "config / script / validation commands are in place, and broad-scope batch reformatting is explicitly out of scope."
Do not install packages during planning. The implementation is done by harness-work as a setup task.

Conditions for skipping:

- docs-only / markdown-only / changelog-only
- Existing lint / formatter / CI commands sufficiently cover the language touched in this change
- Cannot introduce due to consumer repo constraints. However, leave `formatter_baseline_action: spike` or skip reason.

## Step 5: Feature list extraction

Extract a concrete feature list from the requirements.

Example: for a reservation management system
- User registration/login
- Reservation calendar display
- Create/edit/cancel reservations
- Admin dashboard
- Email notifications
- Payment functionality

## Step 5.5: Optional brief generation

Only add a brief when needed. A brief is a short supplementary document that fixes implementation prerequisites without replacing Plans.md.

- For tasks with UI: `design brief`
- For tasks with API: `contract brief`
- When UI and API are mixed: separate the briefs

### design brief

For UI tasks, include at minimum:

- What to achieve
- Who will use it
- Important screen states
- Constraints on appearance and interactions
- Completion conditions

### contract brief

For API tasks, include at minimum:

- What to receive / return
- Input validation conditions
- Behavior on failure
- External dependencies
- Completion conditions

## Step 6: Priority matrix creation (2-axis evaluation)

Evaluate each feature on 2 axes: **Impact × Risk (uncertainty)**:

- **Impact**: User value × Number of target users (high/low)
- **Risk**: Technical unknowns × External dependencies (high/low)

| Impact\Risk | Low risk | High risk |
|-------------|---------|---------|
| **High Impact** | ★ **Required** — top priority (value is certain) | ▲ **Required + [needs-spike]** — early validation needed |
| **Low Impact** | ○ **Recommended** — address with spare capacity | ✕ **Optional** — defer or reduce scope |

### `[needs-spike]` marker

Automatically assign `[needs-spike]` marker to High Impact × High Risk tasks.
For tasks with `[needs-spike]`, automatically generate a **spike (technical validation) task** and place it first:

```markdown
| N.X-spike | [spike] Technical validation for {{task name}} | Create validation result report | - | cc:TODO |
| N.X       | {{task name}} [needs-spike] | {{DoD}} | N.X-spike | cc:TODO |
```

The completion condition for a spike task is "leave a validation result report (feasible / infeasible / requires design change)."

## Step 6.5: TDD skip decision (enabled by default)

TDD is enabled by default. Only assign the `[skip:tdd]` marker to skip tasks that meet one of the following:

| Skip condition | Reason |
|-------------|------|
| Documentation/comments only | Does not affect executable code |
| Configuration files only (JSON, YAML, .env) | No logic to test |
| Single-line or less simple fix (typo) | Test cost outweighs benefit |
| Style/format changes only | Does not affect behavior |
| Dependency updates only | No implementation logic changes |
| README/CHANGELOG updates | Documentation only |
| Refactoring (no behavior changes) | Already covered by existing tests |

Tasks not matching the above have TDD applied automatically (test-first recommended).

## Step 6.7: Plans.md v3 format specification

Plans.md v3 includes the following format extensions:

### Phase header Purpose line (optional)

A one-line Purpose (objective) can be described in each Phase header. Omit if no input:

```markdown
### Phase N.X: [Phase name] [Px]

Purpose: [One-line description of the problem this phase solves]
```

- **Default**: Do not prompt for input (omit if blank)
- **Effect when included**: Displayed during Phase 0 scope confirmation in breezing
- **Generation rule**: Only auto-include when user explicitly states the phase objective

### Artifact notation (Status column)

Attach commit hash to Status when a task is completed:

```markdown
| Task | Content | DoD | Depends | Status |
|------|------|-----|---------|--------|
| 1.1  | ... | ... | - | cc:done [a1b2c3d] |
| 1.2  | ... | ... | 1.1 | cc:TODO |
```

- **Format**: `cc:done [7-char hash]`
- **When assigned**: Auto-assigned in `harness-work` Solo Step 7
- **Backward compatibility**: hash-less `cc:done` also remains valid

### Affected files list

Files related to v3 format:

| File | Impact |
|---------|------|
| `skills/harness-plan/references/create.md` | Add Purpose line to Step 6 template |
| `skills/harness-plan/references/sync.md` | Recognize `cc:done [hash]` format in diff detection |
| `skills/harness-work/SKILL.md` | Assign hash in Solo Step 7, re-ticket on failure |
| `skills/harness-sync/SKILL.md` | Save snapshot with --snapshot |
| `skills/breezing/SKILL.md` | Display progress in Progress Feed |

## Step 7: Generate Plans.md

First output `Spec delta` or `Spec skip reason`, then auto-generate quality markers + DoD + Depends to generate Plans.md.

### Spec result output

Harness generates `Spec delta` / `Spec skip reason`; the consumer only approves or revises.

```markdown
Spec delta:
- path: spec.md
- change: [product rule to add/change]
- why: [reason it is necessary as a prerequisite for this task contract]

Plans.md:
| Task | Content | DoD | Depends | Status |
|------|------|-----|---------|--------|
```

```markdown
Spec skip reason:
- path checked: spec.md
- reason: [docs-only / mechanical task / correct answer is fixed by existing spec and tests]
- preserve in: task context or sprint contract

Plans.md:
| Task | Content | DoD | Depends | Status |
|------|------|-----|---------|--------|
```

### Quality marker assignment logic
```
Analyze task content
    ↓
├── "auth" "login" "API" → [feature:security]
├── "component" "UI" "screen" → [feature:a11y]
├── "fix" "bug" → [bugfix:reproduce-first]
├── "docs" "comment" "README" "CHANGELOG" → [skip:tdd]
├── "config" "json" "yaml" "env" → [skip:tdd]
├── "style" "format" "lint" → [skip:tdd]
├── "refactor" (no behavior change) → [skip:tdd]
├── "payment" "billing" → [feature:security]
└── other → no marker (TDD is enabled by default)
```

### DoD auto-inference logic

Infer and auto-fill DoD using keyword-based inference from the task "content":

| Task content keyword | DoD inference |
|---------------------|---------|
| "create" "new" "add" | File exists with expected structure |
| "test" | Tests pass (`npm test` / `pytest`, etc.) |
| "fix" "bug" | Problem no longer reproduces |
| "UI" "screen" "component" | Visual confirmation (screenshot or browser) |
| "API" "endpoint" | Response confirmed with curl/httpie |
| "config" | Configuration value is applied |
| "documentation" "docs" | File exists, no broken links |
| "migration" "DB" | Migration can be executed |
| "refactoring" | All existing tests pass + lint errors 0 |

Inference results are default values only. User-specified acceptance conditions take priority.

### Depends auto-inference logic

Infer dependencies between tasks within a phase using these rules:

1. **DB/schema tasks** → depended on by other implementation tasks (preceding task)
2. **UI tasks** → depend on API/logic tasks (following task)
3. **Test/verification tasks** → depend on implementation tasks (last)
4. **Configuration/environment tasks** → depended on by other tasks (preceding task)
5. **Tasks with no clear dependency** → `-` (can run in parallel)

Use `-` if inference is uncertain and ask user for confirmation.

**Generation template**:

```markdown
# [Project name] Plans.md

Created: YYYY-MM-DD

---

## Phase 1: [Phase name]

Purpose: [Phase objective (optional)]

| Task | Content | DoD | Depends | Status |
|------|------|-----|---------|--------|
| 1.1  | [Task description] [feature:security] | [Verifiable completion condition] | - | cc:TODO |
| 1.2  | [Task description] | [Verifiable completion condition] | 1.1 | cc:TODO |
```

**Purpose line**:
- Auto-include only when user explicitly states the phase objective
- Omit the entire Purpose line (not just blank) if no input
- Keep to a single line (no multi-line)

**DoD (Definition of Done) notation**:
- Write in one verifiable line (e.g., "tests pass", "migration executable", "lint errors 0")
- "Looks good" or "works properly" are prohibited. Must be determinable Yes/No.

**Depends notation**:
- No dependency: `-`
- Single dependency: task number (e.g., `1.1`)
- Multiple dependencies: comma-separated (e.g., `1.1, 1.2`)
- Phase dependency: phase number (e.g., `Phase 1`)

### Team mode output

Only when user explicitly specifies team mode, also guide issue bridge dry-run alongside Plans.md.

- Only one tracking issue
- List sub-issue payloads per task
- Keep Plans.md as the source of truth
- Guide in a usable form for dry-run of `scripts/plans-issue-bridge.sh --team-mode`

## Step 8: Always provide session launch command and first input

Immediately after outputting Plans.md, to prevent the user from hesitating on the next step,
always provide the **new session launch command** and
**the first input to enter right after launch** as a set.

### Output rules

1. Write at least 1 concrete launch command + first input
2. Narrow down to "top candidate + 1 alternative" if possible
3. Add a one-line explanation of why that combination is recommended
4. For long-running tasks, present `bash scripts/claude-longrun.sh` first

### Recommended mapping

| Situation | Launch command | First input |
|------|--------------|------------|
| Starting from the first task | `claude` | Single task execution like `/harness-work 1.1` |
| Advancing multiple tasks together | `claude` | `/breezing all` |
| Wanting to run all in sequence | `claude` | `/harness-work all` |
| Long-running, re-entry required | `bash scripts/claude-longrun.sh` | `/harness-loop all` |

### Output example

```text
Next step:
- New session launch command: claude
- First input after launch: /breezing all
- Suited for: The Plans.md from this session has multiple tasks and a team run is most natural
```

```text
Next step:
- New session launch command: bash scripts/claude-longrun.sh
- First input after launch: /harness-loop all
- Suited for: Long-running tasks where waits exceeding 5 minutes or resumptions are likely
```

## Step 9: Next action guidance

> Plans.md complete!
>
> Next steps:
> - Start implementation with `harness-work`
> - Or say "Start from Phase 1"
> - Add features with `harness-plan add [feature name]`
> - Defer features with `harness-plan update [task] blocked`

## CI mode (--ci)

No interview. Use existing Plans.md as-is and only perform task decomposition.

1. Load Plans.md
2. List cc:TODO tasks in priority order
3. Mark parallel-executable tasks with `[P]`
4. Propose the next task to execute
