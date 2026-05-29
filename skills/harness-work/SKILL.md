---
name: harness-work
description: "HAR: Execute Plans.md tasks from single task to full parallel team run. Trigger: implement, execute, do everything, breezing, team run, parallel. Do NOT load for: planning, review, release, setup."
description-en: "HAR: Execute Plans.md tasks from single task to full parallel team run. Trigger: implement, execute, do everything, breezing, team run, parallel. Do NOT load for: planning, review, release, setup."
description-ja: "HAR:Plans.md タスクを1件から全並列チーム実行まで担当。実装して、実行して、全部やって、breezing、チーム実行、parallel で起動。プランニング・レビュー・リリース・セットアップには使わない。"
kind: workflow
purpose: "Execute Plans.md tasks end to end"
trigger: "implement, execute, do everything, breezing, team run, parallel"
shape: workflow
role: executor
pair: harness-review
owner: harness-core
since: "2026-05-05"
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash", "Task", "Monitor"]
argument-hint: "[all] [task-number|range] [--codex] [--parallel N] [--no-commit] [--resume id] [--breezing] [--auto-mode] [--tdd-bypass]"
user-invocable: true
effort: high
---

# Harness Work

Integrated Harness execution skill.
Consolidates the following legacy skills:

- `work` — Plans.md task implementation (auto scope detection)
- `impl` — Feature implementation (task-based)
- `breezing` — Full team auto-execution
- `parallel-workflows` — Parallel workflow optimization
- `ci` — CI failure recovery

## Quick Reference

| User input | Mode | Action |
|------------|------|--------|
| `/harness-work` | **auto** | Auto-determined by task count (see below) |
| `/harness-work all` | **auto** | Execute all incomplete tasks in auto mode |
| `/harness-work 3` | solo | Execute only task 3 immediately |
| `/harness-work --parallel 5` | parallel | Execute with 5 workers in parallel (forced) |
| `/harness-work --codex` | codex | Delegate to Codex CLI (explicit only) |
| Cursor host (adapter candidate) | cursor | Task/subagent routing via `.cursor/AGENTS.md`; not auto-selected |
| `/harness-work --breezing` | breezing | Force team execution |
| `/harness-work 3 --plan roadmap` | solo | Execute task 3 from named plan `roadmap` |

## Execution Mode Auto Selection (when no explicit flag)

When no explicit mode flag (`--parallel`, `--breezing`, `--codex`) is given,
the optimal mode is auto-selected based on the number of target tasks:

| Target tasks | Auto-selected mode | Reason |
|-------------|-------------------|--------|
| **1** | Solo | Minimal overhead; direct implementation is fastest |
| **2-3** | Parallel (Task tool) | Threshold where Worker isolation benefit starts to appear |
| **4+** | Breezing | Lead coordination + parallel Workers + independent Reviewer separation is effective |

### Rules

1. **Explicit flags always override auto mode**
   - `--parallel N` → Parallel mode (regardless of task count)
   - `--breezing` → Breezing mode (regardless of task count)
   - `--codex` → Codex mode (regardless of task count)
2. **`--codex` activates only when explicit**. Not auto-selected because Codex CLI may not be installed.
3. `--codex` can be combined with other modes: `--codex --breezing` → Codex + Breezing

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `all` | Target all incomplete tasks | — |
| `N` or `N-M` | Task number/range | — |
| `--parallel N` | Number of parallel workers | auto |
| `--sequential` | Force sequential execution | — |
| `--codex` | Delegate implementation to Codex CLI (explicit only; not auto-selected) | false |
| `--plan NAME` | Use named plan from `plans/manifest.json` | active/default |
| `--no-commit` | Suppress auto-commit | false |
| `--resume <id\|latest>` | Resume previous session; use `/recap` together if a long time has passed | — |
| `--breezing` | Team execution with Lead/Worker/Reviewer | false |
| `--no-tdd` | Skip TDD phase | false |
| `--tdd-bypass` | Bypass TDD enforcement in emergencies. Leave `HARNESS_TDD_BYPASS_REASON` or explicit reason in audit | false |
| `--no-simplify` | Skip Auto-Refinement | false |
| `--auto-mode` | Explicitly marks Harness-side Auto Mode rollout; different from `--enable-auto-mode` that became unnecessary in CC 2.1.111 | false |

## Progressive Disclosure

Check only the entry point, auto-selection, and stop conditions in this body first.
Read details only when needed.

| Details | Reference |
|---------|-----------|
| Concrete procedures for Solo / Parallel / Codex / Breezing | `references/execution-modes.md` |
| Codex review, Reviewer fallback, AI Residuals, fix loop | `references/review-loop.md` |
| Solo / Breezing completion report generation | `references/completion-report.md` |
| Test/CI failure re-ticketing | `references/failure-reticketing.md` |
| Spec source of truth check criteria | `docs/plans/spec-ssot.md` |

### Critical stop conditions

- Stop when `Plans.md` is in old format and DoD / Depends / Status cannot be read.
- When spec affects implementation decisions but project spec SSOT is not found, create/update spec before implementing.
- Do not proceed to implementation when sprint-contract is required but not ready.
- Do not mark complete when critical/major review findings remain.
- Do not resolve by weakening tests, skipping, or relaxing expected values to match implementation.
- Call helper scripts from `${HARNESS_PLUGIN_ROOT}/scripts/`, not from the host project's `scripts/`.
- When multiple Plans.md exist, do not switch plans within one run. Use `--plan NAME` and start a new run if needed.

> **Token Optimization (v2.1.69+)**: For lightweight tasks without git operations,
> enable `includeGitInstructions: false` in plugin settings to reduce prompt tokens.

> **Prompt Cache (CC 2.1.108+)**: For longer implementations or work using `--resume` frequently,
> prioritize `ENABLE_PROMPT_CACHING_1H=1`.

## Scope Dialog (no arguments)

```
/harness-work
How far should I go?
1) Next task: next incomplete task in Plans.md → Execute in Solo
2) All (recommended): complete all remaining tasks → Auto mode selection by task count
3) Specify number: enter task number (e.g., 3, 5-7) → Auto mode selection by count
```

When arguments are provided, execute immediately (skip dialog):
- `/harness-work all` → all tasks, auto mode selection
- `/harness-work 3-6` → 4 tasks, Breezing auto-selected

## Effort Level Control (v2.1.68+, v2.1.72, v2.1.111)

In Claude Code v2.1.68, Opus 4.6 defaults to **medium effort** (`◐`).
In v2.1.72, `max` level was deprecated, simplified to 3 levels `low(○)/medium(◐)/high(●)`.
Reset to default with `/effort auto`.
Enable high effort (`●`) for complex tasks with the `ultrathink` keyword.
`xhigh` was added in CC 2.1.111 for Opus 4.7.
You may stack `/effort xhigh` as a literal if needed.

### Multi-factor scoring

At task start, sum the following scores and inject ultrathink when **threshold ≥ 3**:

| Factor | Condition | Score |
|--------|-----------|-------|
| File count | 4+ files to change | +1 |
| Directory | Includes core/, guardrails/, security/ | +1 |
| Keywords | Contains architecture, security, design, migration | +1 |
| Failure history | Same task failure record in agent memory | +2 |
| Explicit specification | ultrathink specified in PM template | +3 (auto-adopt) |

### Injection method

When score ≥ 3, prepend `ultrathink` to the Worker spawn prompt.
The same logic applies in breezing mode (managed centrally by harness-work).

## Execution modes

### Harness helper script root

Harness bundled helper scripts must always be called from the plugin bundle root, not from the target project's `scripts/`:

```bash
HARNESS_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [ -z "$HARNESS_PLUGIN_ROOT" ] && [ -n "${CLAUDE_SKILL_DIR:-}" ]; then
  HARNESS_PLUGIN_ROOT="$(cd "${CLAUDE_SKILL_DIR}/../.." && pwd)"
fi
```

All subsequent `node "${HARNESS_PLUGIN_ROOT}/scripts/..."` / `bash "${HARNESS_PLUGIN_ROOT}/scripts/..."` assume this resolved root.

### Solo mode (auto-selected for 1 task)

1. Load Plans.md and identify the target task
   - **When Plans.md does not exist**: Auto-call `harness-plan create --ci` → generate Plans.md and continue
   - When header lacks DoD / Depends columns: `Plans.md is in old format. Please regenerate with harness-plan create.` → **Stop**
   - **When there are undocumented tasks in conversation**: Extract requirements from the previous conversation context and auto-append to Plans.md as `cc:TODO`
     - Extraction logic: Detect action verbs from user statements ("add ~", "fix ~", "implement ~")
     - Append in v2 format (Task / Content / DoD / Depends / Status)
     - After appending, show "Appended the following to Plans.md" to user (5-second timeout prompt, default: continue)
1.5. **Task background check** (30 seconds):
   - Infer and display the **purpose** (the problem this task solves) in 1 line from the task "Content" and "DoD"
   - Infer and display **impact scope** (files/modules affected by changes) with `git grep` / `Glob`
   - When confident in inference: proceed to implementation without delay
   - When not confident: ask user one question only ("Is this understanding correct?")
1.6. **Spec source of truth preflight**:
   - Search for existing project spec SSOT (e.g., `docs/spec/00-project-spec.md`, `docs/ARCHITECTURE.md`, `docs/HANDOFF.md`, `docs/oem/PROJECT_COMPASS.md`, `docs/specs/`)
   - When task changes product behavior / API / data model / permission / billing / integration / tenant boundary, create `docs/spec/00-project-spec.md` if none exists
   - When spec is outdated or conflicts with task, update spec before implementing
   - Skip with recorded reason for typo / format / dependency bump / docs-only / behavior-preserving refactor
   - Include `spec_path` or `spec_skip_reason` in context passed to Worker / Reviewer
2. Update task to `cc:WIP`
3. **TDD phase** (no `[skip:tdd]` and test framework exists):
   a. Create test file first (Red)
   b. Confirm failure
   c. Leave FAIL evidence in `.claude/state/tdd-red-log/<task-id>.jsonl` with `bash "${HARNESS_PLUGIN_ROOT}/scripts/log-tdd-red.sh"`. In environments where the script is unavailable, attach literal failing test output to `self_review` evidence in worker-report
   d. When using `--tdd-bypass`, explicitly set `HARNESS_TDD_BYPASS=1` and `HARNESS_TDD_BYPASS_REASON="<reason>"`, and leave the reason for skipping TDD in sprint-contract / worker-report
4. Generate `sprint-contract.json` with `node "${HARNESS_PLUGIN_ROOT}/scripts/generate-sprint-contract.js" <task-id>`
5. Add Reviewer perspective with `bash "${HARNESS_PLUGIN_ROOT}/scripts/enrich-sprint-contract.sh"` and confirm approved with `bash "${HARNESS_PLUGIN_ROOT}/scripts/ensure-sprint-contract-ready.sh"`
6. **Advisor consultation (only when needed)**:
   - For high-risk tasks (`needs-spike` / `security-sensitive` / `state-migration`), consult once before first execution
   - When the same root cause failure occurs twice, consult before the 3rd attempt
   - When plateau detection returns `PIVOT_REQUIRED`, consult once before stopping and escalating to user
   - Receive consultation result as `advisor-response.v1`: `PLAN` = restructure approach, `CORRECTION` = local fix, `STOP` = immediate escalation
   - Consult only once per the same `trigger_hash`. Maximum 3 consultations per task
7. Implement code (Green) (Read/Write/Edit/Bash)
8. Auto-Refinement with `/simplify` (skippable with `--no-simplify`)
9. **Automated review stage** (see "Review Loop"):
   - Run review prioritizing Codex exec → fallback to internal Reviewer agent
   - When `sprint-contract.json` has `reviewer_profile: runtime`, run `bash "${HARNESS_PLUGIN_ROOT}/scripts/run-contract-review-checks.sh"`
   - On REQUEST_CHANGES: fix per findings → re-review (`MAX_REVIEWS = read_contract(contract_path, ".review.max_iterations") or 3`)
   - Proceed on APPROVE; do not finalize on self-check alone
10. Normalize and save review artifact with `bash "${HARNESS_PLUGIN_ROOT}/scripts/write-review-result.sh"` (pass `--browser-result` for browser profile; adopt static verdict when `browser_verdict == PENDING_BROWSER`)
11. Auto-commit with `git commit` (skippable with `--no-commit`)
12. Update task to `cc:done` (with commit hash)
    - Get recent commit hash (7-char short form) with `git log --oneline -1`
    - Update Plans.md Status to `cc:done [a1b2c3d]` format
    - When no commit (`--no-commit`): `cc:done` without hash
13. **Rich completion report** (see "Completion Report Format")
14. **Automatic re-planning on failure** (only when test/CI fails):
    - Check test execution results
    - On failure: save fix task proposal to state and add to Plans.md via approval command (see "Automatic Failure Re-ticketing")
    - On success: proceed to next task

### Parallel mode (auto-selected for 2-3 tasks / forced with `--parallel N`)

Execute tasks marked `[P]` with N workers in parallel.
When `--parallel N` is explicitly specified, use this mode regardless of task count.
Isolate with git worktree when same-file write conflicts occur.

### Codex mode (explicit `--codex` only)

Delegate tasks to Codex CLI via the official plugin `codex-plugin-cc` companion:

```bash
# Task delegation (writable)
bash "${HARNESS_PLUGIN_ROOT}/scripts/codex-companion.sh" task --write "task content"

# Via stdin (for large prompts)
CODEX_PROMPT=$(mktemp /tmp/codex-prompt-XXXXXX.md)
cat "$CODEX_PROMPT" | bash "${HARNESS_PLUGIN_ROOT}/scripts/codex-companion.sh" task --write
rm -f "$CODEX_PROMPT"

# Continue previous thread
bash "${HARNESS_PLUGIN_ROOT}/scripts/codex-companion.sh" task --resume-last --write "continue"
```

Companion communicates with Codex via App Server Protocol, providing job management, thread resume, and structured output.
Verify results; fix independently when quality criteria are not met.

### Cursor mode (adapter candidate; not auto-selected)

On Cursor host, `.cursor/AGENTS.md` and `.cursor-plugin/plugin.json` are the bootstrap route. Cursor remains `candidate` — supported claims are prohibited.

- **Solo / Parallel**: Task tool or `.cursor/agents/worker.md` subagent
- **Breezing**: Worker parallelism for non-overlapping file groups only; Reviewer / cherry-pick / Advisor remain serial as in core
- **Multitask / background agents**: Smoke target only; do not claim Claude Agent Teams parity

Model routing:

```bash
bash scripts/model-routing.sh --host cursor --role worker --format json
```

Explicit Task/subagent `model` takes priority over routed default.

Verification:

```bash
bash tests/test-cursor-adapter-candidate.sh
```

### Breezing mode (auto-selected for 4+ tasks / forced with `--breezing`)

Team execution with role separation: Lead / Worker / Advisor / Reviewer.
In Codex, assumes native subagent orchestration using `spawn_agent`, `wait`, `send_input`, `resume_agent`, `close_agent` — does not use the old TeamCreate/TaskCreate-based description.
In Cursor, maps to Task/subagent/background agents, but review/cherry-pick serial responsibilities remain on the core side (adapter smoke target).

**Permission policy**:
- Current shipped default is `bypassPermissions`
- `--auto-mode` is treated as an opt-in rollout flag for compatible parent sessions
- Do not write undocumented `autoMode` value in `permissions.defaultMode` or agent frontmatter `permissionMode`

> **CC v2.1.69+**: Nested teammates are prohibited by the platform, so do not add redundant nested-prevention wording to Worker/Reviewer prompts.

```
Lead (this agent)
├── Worker (task-worker agent) — implementation
├── Advisor (claude-code-harness:advisor) — policy advice
└── Reviewer (code-reviewer agent) — review
```

**Phase A: Pre-delegate (preparation)**:
1. Load Plans.md and identify target tasks
2. Analyze dependency graph and determine execution order (Depends column)
3. Effort scoring per task (ultrathink injection determination)
4. Generate `sprint-contract.json` with `node "${HARNESS_PLUGIN_ROOT}/scripts/generate-sprint-contract.js"`
5. Add Reviewer perspective with `bash "${HARNESS_PLUGIN_ROOT}/scripts/enrich-sprint-contract.sh"` and stop if not approved with `bash "${HARNESS_PLUGIN_ROOT}/scripts/ensure-sprint-contract-ready.sh"`

**Phase B: Delegate (Worker spawn → Advisor when needed → review → cherry-pick)**:

Execute the following **sequentially** for each task (in dependency order):

> **API note**: Written in Claude Code API syntax below.
> In Codex environments, translate `Agent(...)` → `spawn_agent(...)`, `SendMessage(...)` → `send_input(...)`.
> See API mapping table in `team-composition.md` for details.

```
for task in execution_order:
    # B-1. Generate sprint-contract
    contract_path = bash("node \"${HARNESS_PLUGIN_ROOT}/scripts/generate-sprint-contract.js\" {task.number}")
    contract_path = bash("bash \"${HARNESS_PLUGIN_ROOT}/scripts/enrich-sprint-contract.sh\" {contract_path} --check \"Verify DoD from reviewer perspective\" --approve")
    bash("bash \"${HARNESS_PLUGIN_ROOT}/scripts/ensure-sprint-contract-ready.sh\" {contract_path}")

    # B-2. Worker spawn (foreground, worktree isolated)
    Plans.md: task.status = "cc:WIP"  # Update on start (untouched tasks remain cc:TODO)

    briefing_header = ""
    if universal_violations:
        briefing_header = (
            "🚨 Universal violations already detected in this session (do not repeat):\n"
            + "\n".join(f"- {v}" for v in universal_violations)
            + "\n\n"
        )

    worker_result = Agent(
        subagent_type="claude-code-harness:worker",
        prompt=briefing_header + "Task: {task.content}\nDoD: {task.DoD}\ncontract_path: {contract_path}\nmode: breezing",
        isolation="worktree",
        run_in_background=false
    )
    worker_id = worker_result.agentId

    # B-3. Lead calls Advisor only when Worker returns advice request
    if worker_result.type == "advisor-request.v1":
        advisor_result = Advisor(prompt=worker_result.request_json)
        worker_result = SendMessage(to=worker_id, message="advisor-response.v1: {advisor_result}")

    # B-3.5. self_review gate (Lead mechanically verifies before spawning Reviewer)
    self_review_failures = 0
    MAX_SELF_REVIEW_RETRIES = 2
    while True:
        unverified = [r for r in worker_result.self_review if (not r.get("verified")) or (not r.get("evidence"))]
        if not unverified:
            break
        self_review_failures += 1
        if self_review_failures > MAX_SELF_REVIEW_RETRIES:
            Plans.md: task.status = "cc:TODO"
            raise EscalationError(f"self_review not confirmed after 3 returns (rules: {[u['rule'] for u in unverified]})")
        SendMessage(to=worker_id, message=f"self_review has unconfirmed rules: {[u['rule'] for u in unverified]}. Fill evidence for each rule with actual command output or literal test results, attach TDD evidence when required, set verified=true, then amend")
        worker_result = wait_for_response(worker_id)

    # B-4. Lead runs review (Codex exec priority)
    diff_text = git("-C", worker_result.worktreePath, "show", worker_result.commit)
    verdict = codex_exec_review(diff_text) or reviewer_agent_review(diff_text)
    profile = jq(contract_path, ".review.reviewer_profile")
    review_input = "review-output.json"
    if profile == "runtime":
        review_input = bash("cd {worker_result.worktreePath} && bash \"${HARNESS_PLUGIN_ROOT}/scripts/run-contract-review-checks.sh\" {contract_path}")
        runtime_verdict = jq(review_input, ".verdict")
        if runtime_verdict == "REQUEST_CHANGES":
            verdict = "REQUEST_CHANGES"
        elif runtime_verdict == "DOWNGRADE_TO_STATIC":
            pass
    browser_result = ""
    if profile == "browser":
        browser_artifact = bash("bash \"${HARNESS_PLUGIN_ROOT}/scripts/generate-browser-review-artifact.sh\" {contract_path}")
        browser_result = bash("bash \"${HARNESS_PLUGIN_ROOT}/scripts/browser-review-runner.sh\" {browser_artifact}")
        browser_verdict = jq(browser_result, ".browser_verdict")
        if browser_verdict == "REQUEST_CHANGES":
            verdict = "REQUEST_CHANGES"
        elif browser_verdict == "APPROVE" and verdict != "REQUEST_CHANGES":
            verdict = "APPROVE"
    bash("bash \"${HARNESS_PLUGIN_ROOT}/scripts/write-review-result.sh\" {review_input} {latest_commit} --browser-result {browser_result}")

    # B-5. Fix loop (on REQUEST_CHANGES, up to max_iterations from contract)
    review_count = 0
    MAX_REVIEWS = read_contract(contract_path, ".review.max_iterations") or 3
    latest_commit = worker_result.commit
    while verdict == "REQUEST_CHANGES" and review_count < MAX_REVIEWS:
        SendMessage(to=worker_id, message="Findings: {issues}\nPlease fix and amend")
        updated_result = wait_for_response(worker_id)
        latest_commit = updated_result.commit
        diff_text = git("-C", worker_result.worktreePath, "show", latest_commit)
        verdict = codex_exec_review(diff_text) or reviewer_agent_review(diff_text)
        review_count++

    # B-6. APPROVE → cherry-pick to trunk (via feature branch)
    if verdict == "APPROVE":
        TRUNK=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main")
        git checkout "$TRUNK"
        if git("merge-base", "--is-ancestor", latest_commit, "HEAD"):
            pass  # Already on trunk — skip cherry-pick (re-entry prevention)
        else:
            git cherry-pick --no-commit {latest_commit}
            git commit -m "{task.content}"
        if worker_result.worktreePath:
            git worktree remove {worker_result.worktreePath} --force
        if worker_result.branch and worker_result.branch not in ["main", "master"] and worker_result.branch != TRUNK:
            git branch -D {worker_result.branch}
        Plans.md: task.status = "cc:done [{hash}]"
        HASH=$(git rev-parse --short HEAD)
        REVIEW_RESULT_PATH=".claude/state/review-results/${task.number}.review-result.json"
        bash "${HARNESS_PLUGIN_ROOT}/scripts/auto-checkpoint.sh" \
            "${task.number}" "${HASH}" "${contract_path}" "${REVIEW_RESULT_PATH}" \
            || true  # fail-open: continue even in environments without harness-mem
    else:
        → Escalate to user

    # B-7. Progress feed
    print("📊 Progress: Task {completed}/{total} done — {task.content}")
```

### Advisor Protocol (common to all modes)

Advisor is neither "implementer" nor "reviewer."
It is a consultation role that enters only when needed to help the executor decide the next step.

1. Worker does not spawn generic subagents; returns `advisor-request.v1` only when needed
2. Lead calls Advisor once
3. Advisor returns one of `PLAN` / `CORRECTION` / `STOP`
4. Lead returns that advice to the same Worker to continue
5. Reviewer looks only at the final artifact; does not issue APPROVE/REQUEST_CHANGES to Advisor responses

### Advisor in Solo mode

In solo execution, the parent session serves as Lead.
That is: "implement yourself, consult Advisor yourself, and then send to independent review at the end."

- Consultation conditions are the same as loop/breezing
- Consultation budget is also max 3 per task
- `STOP` stops there and escalates to user
- Do not skip the review artifact gate

### Sprint Contract

`sprint-contract` is a small contract file that makes "what this task needs to pass" readable in the same way by both machine and human.
Default location: `.claude/state/contracts/<task-id>.sprint-contract.json`

```bash
node "${HARNESS_PLUGIN_ROOT}/scripts/generate-sprint-contract.js" 32.1.1
```

Generated content includes:

- `checks`: Verification items broken down from DoD
- `non_goals`: What not to do this time
- `runtime_validation`: Verification commands such as test, lint, typecheck
- `browser_validation`: UI flow verification items the browser reviewer should leave
- `browser_mode`: `scripted` or `exploratory`
- `route`: Which of `playwright` / `agent-browser` / `chrome-devtools` the browser reviewer uses
- `risk_flags`: `needs-spike`, `security-sensitive`, `ux-regression`, etc.
- `reviewer_profile`: `static`, `runtime`, `browser`

**Phase C: Post-delegate (integration and reporting)**:
1. Aggregate commit logs for all tasks
2. Output **rich completion report** (Breezing template in "Completion Report Format")
3. Final check of Plans.md (are all tasks cc:done?)

## On CI failure

When CI fails:

1. Check logs to identify the error
2. Apply fix
3. Stop the automatic fix loop after 3 failures with the same root cause
4. Summarize failure log, attempted fixes, and remaining issues, then escalate

## Automatic failure re-ticketing

When tests/CI fail after task completion, auto-generate a fix task proposal and reflect in Plans.md after approval:

### Trigger conditions

| Condition | Action |
|-----------|--------|
| Test fails after `cc:done` | Save fix task proposal to state and wait for approval |
| CI failure (fewer than 3 times) | Apply fix and increment failure count |
| CI failure (3rd time) | Present fix task proposal + escalate |

### Auto-generation of fix task

1. Classify failure cause (syntax_error / import_error / type_error / assertion_error / timeout / runtime_error)
2. Save fix task proposal to `.claude/state/pending-fix-proposals.jsonl`:
   - Number: original task number + `.fix` suffix (e.g., `26.1.fix`)
   - Content: `fix: [original task name] - [failure cause category]`
   - DoD: tests/CI pass
   - Depends: original task number
3. When user sends `approve fix <task_id>`, add to Plans.md as `cc:TODO`
4. Discard proposal with `reject fix <task_id>`. When only 1 pending item, `yes` / `no` also works

## Review Loop

Quality verification stage that runs automatically after implementation (after step 5).
Applied **uniformly across all modes** (Solo / Parallel / Breezing).
In Parallel mode, each Worker runs the same loop as step 10 (external review acceptance).

### Review execution priority

```
1. Codex exec (priority)
   ↓ codex command not found or timeout (120s)
2. Internal Reviewer agent (fallback)
```

### APPROVE / REQUEST_CHANGES criteria

Pass the following threshold criteria to the reviewer and have it judge verdict by **these criteria only**.
Improvement suggestions outside the criteria are returned as `recommendations` but do not affect verdict.

| Severity | Definition | Verdict effect |
|----------|-----------|----------------|
| **critical** | Security vulnerability, data loss risk, potential production incident | 1 or more → REQUEST_CHANGES |
| **major** | Existing feature breakage, clear spec conflict, test failure | 1 or more → REQUEST_CHANGES |
| **minor** | Naming improvement, missing comment, style inconsistency | No effect on verdict |
| **recommendation** | Best practice suggestion, future improvement | No effect on verdict |

> **Important**: When only minor/recommendation, **always return APPROVE**.
> "Improvements that would be nice to have" are not a reason for REQUEST_CHANGES.

### Codex exec review (via official plugin)

Save HEAD at task start as `BASE_REF` and use the diff from that ref as the review target.
Use the companion review of official plugin `codex-plugin-cc`.

```bash
# Record base ref at task start (run before cc:WIP update in Step 2)
BASE_REF=$(git rev-parse HEAD)

# ... after implementation ...

# Run structured review from official plugin
bash "${HARNESS_PLUGIN_ROOT}/scripts/codex-companion.sh" review --base "${BASE_REF}"
REVIEW_EXIT=$?
```

**Verdict mapping** (official plugin → Harness format):

| Official plugin | Harness | Verdict effect |
|-----------------|---------|---------------|
| `approve` | `APPROVE` | — |
| `needs-attention` | `REQUEST_CHANGES` | — |
| `findings[].severity: critical` | `critical_issues[]` | 1 or more → REQUEST_CHANGES |
| `findings[].severity: high` | `major_issues[]` | 1 or more → REQUEST_CHANGES |
| `findings[].severity: medium/low` | `recommendations[]` | No effect on verdict |

AI Residuals scan continues to run with `bash "${HARNESS_PLUGIN_ROOT}/scripts/review-ai-residuals.sh"`,
combined with companion review results to determine final verdict.

```bash
AI_RESIDUALS_JSON="$(bash "${HARNESS_PLUGIN_ROOT}/scripts/review-ai-residuals.sh" --base-ref "${BASE_REF}" --include-untracked 2>/dev/null || echo '{"tool":"review-ai-residuals","scan_mode":"diff","base_ref":null,"include_untracked":true,"files_scanned":[],"untracked_files_scanned":[],"summary":{"verdict":"APPROVE","major":0,"minor":0,"recommendation":0,"total":0},"observations":[]}')"
```

### Internal Reviewer agent fallback

When Codex exec is unavailable (`command -v codex` fails or exit code ≠ 0):

```
Agent tool: subagent_type="reviewer"
prompt: "Please review the following changes. Criteria: critical/major → REQUEST_CHANGES; minor/recommendation only → APPROVE. diff: {git diff ${BASE_REF}}"
```

Reviewer agent runs safely in Read-only mode (Write/Edit/Bash disabled).

### Fix loop (on REQUEST_CHANGES)

```
review_count = 0
contract_path = get_sprint_contract_path()
MAX_REVIEWS = read_contract(contract_path, ".review.max_iterations") or 3

while verdict == "REQUEST_CHANGES" and review_count < MAX_REVIEWS:
    1. Parse review findings (critical / major only)
    2. Implement fix for each finding
    3. Run review again (same criteria, same priority)
    review_count++

if review_count >= MAX_REVIEWS and verdict != "APPROVE":
    → Escalate to user
    → Show "Fixed MAX_REVIEWS times but following critical/major findings remain" + finding list
    → Wait for user decision (continue / abort)
```

### Application in Breezing mode

In Breezing mode, **Lead** runs the review loop (see Phase B above):

1. Worker implements in worktree → commits → returns result to Lead
2. Lead runs Codex exec review (priority) / Reviewer agent (fallback)
3. REQUEST_CHANGES → Lead sends fix instruction to Worker via SendMessage → Worker amends
4. After fix, re-review (up to `MAX_REVIEWS = read_contract(contract_path, ".review.max_iterations") or 3` times)
5. APPROVE → Lead cherry-picks to trunk (default branch) → updates Plans.md to `cc:done [{hash}]`

## Completion Report Format

Visual summary auto-output at task completion (`cc:done` + after commit).
Intended to convey changes and impact to non-experts as well.

### Template

```
┌─────────────────────────────────────────────┐
│  ✓ Task {N} done: {task name}               │
├─────────────────────────────────────────────┤
│                                              │
│  ■ What was done                             │
│    • {change 1}                              │
│    • {change 2}                              │
│                                              │
│  ■ What changed                              │
│    Before: {old behavior}                    │
│    After:  {new behavior}                    │
│                                              │
│  ■ Changed files ({N} files)                 │
│    {file path 1}                             │
│    {file path 2}                             │
│                                              │
│  ■ Remaining issues                          │
│    • Task {X} ({status}): {content} ← Plans.md │
│    • Task {Y} ({status}): {content} ← Plans.md │
│    ({M} incomplete tasks in Plans.md)        │
│                                              │
│  commit: {hash} | review: {APPROVE}          │
└─────────────────────────────────────────────┘
```

### Generation rules

1. **What was done**: Auto-extracted from `git diff --stat HEAD~1` and commit message. Minimize jargon; start with a verb.
2. **What changed**: Infer Before/After from task "Content" and "DoD". Prioritize user experience changes.
3. **Changed files**: Retrieved from `git diff --name-only HEAD~1`. Abbreviate with count when exceeding 5 files.
4. **Remaining issues**: List `cc:TODO` / `cc:WIP` tasks from Plans.md. Explicitly note whether already in Plans.md.
5. **Review**: Display review result (APPROVE / REQUEST_CHANGES → APPROVE).

### Reporting in Parallel mode

- **1 task** (when `--parallel` is forced): Use Solo template
- **Multiple tasks**: Use Breezing aggregate template (see below)

### Reporting in Breezing mode

Output together after all tasks complete. List each task in abbreviated form (what was done + commit hash only),
then output an overall summary (total changed files + remaining issues) at the end:

```
┌─────────────────────────────────────────────┐
│  ✓ Breezing done: {N}/{M} tasks             │
├─────────────────────────────────────────────┤
│                                              │
│  1. ✓ {task name 1}            [{hash1}]    │
│  2. ✓ {task name 2}            [{hash2}]    │
│  3. ✓ {task name 3}            [{hash3}]    │
│                                              │
│  ■ Overall changes                           │
│    {N} files changed, {A} insertions(+),    │
│    {D} deletions(-)                          │
│                                              │
│  ■ Remaining issues                          │
│    {K} incomplete tasks in Plans.md         │
│    • Task {X}: {content}                    │
│                                              │
└─────────────────────────────────────────────┘
```

## Related skills

- `harness-plan` — Plan tasks to execute
- `harness-sync` — Sync implementation with Plans.md
- `harness-review` — Review implementation
- `harness-release` — Version bump and release
