# harness-loop: Wake-up Flow Details

Detailed procedures for each wake-up entry in `harness-loop`.
An implementation reference that supplements the summary in SKILL.md.

---

## Entry Procedure for Each Wake-up (Detailed)

### Step 0: Resolve plugin bundle root

`harness-loop` calls helper scripts under the plugin bundle root, not the host project's cwd.
Keep `Plans.md` and `.claude/state/...` on the host project side; only read scripts as tools from the plugin bundle.

```bash
resolve_harness_plugin_root() {
    if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -d "${CLAUDE_PLUGIN_ROOT}/scripts" ]; then
        (cd "${CLAUDE_PLUGIN_ROOT}" && pwd -P)
        return 0
    fi

    if [ -n "${CLAUDE_SKILL_DIR:-}" ]; then
        for candidate in "${CLAUDE_SKILL_DIR}/../.." "${CLAUDE_SKILL_DIR}/../../.."; do
            candidate_abs="$(cd "${candidate}" 2>/dev/null && pwd -P)" || continue
            if [ -f "${candidate_abs}/.claude-plugin/plugin.json" ] && [ -d "${candidate_abs}/scripts" ]; then
                printf '%s\n' "${candidate_abs}"
                return 0
            fi
        done
    fi

    echo "ERROR: cannot resolve Claude Harness plugin root. Set CLAUDE_PLUGIN_ROOT to the installed plugin bundle root." >&2
    return 1
}

HARNESS_PLUGIN_ROOT="$(resolve_harness_plugin_root)" || exit 1
```

- Use `CLAUDE_PLUGIN_ROOT` with highest priority if it is valid
- If `CLAUDE_PLUGIN_ROOT` is absent, reverse-calculate the distribution source from `CLAUDE_SKILL_DIR`
  - `${CLAUDE_SKILL_DIR}/../..` for `skills/harness-loop` distribution
  - `${CLAUDE_SKILL_DIR}/../../..` for `.agents/skills/harness-loop` mirror distribution
- Only treat candidates that have both `scripts/` and `.claude-plugin/plugin.json` as the plugin root
- Do not use the host project cwd's `scripts/`

### Step 0.1: Duplicate execution prevention lock (idempotency guard (a))

```bash
LOCK_DIR=".claude/state/locks/loop-session.lock.d"
mkdir -p ".claude/state/locks"

# Atomic creation (fails immediately if exists — avoids TOCTOU race)
if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    existing=$(cat "${LOCK_DIR}/meta.json" 2>/dev/null || echo '{}')
    echo "ERROR: harness-loop is already running (lock dir exists: ${LOCK_DIR})" >&2
    echo "Lock contents: ${existing}" >&2
    echo "To force-clear, run: rm -rf ${LOCK_DIR}" >&2
    exit 10
fi

# Write lock metadata inside the lock directory
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
ARGS_STR="$*"
cat > "${LOCK_DIR}/meta.json" <<EOF
{
  "pid": $$,
  "session_id": "${SESSION_ID}",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "args": "${ARGS_STR}"
}
EOF

# Delete lock on exit (normal or abnormal)
cleanup_loop_lock() {
    rm -rf "${LOCK_DIR}" 2>/dev/null || true
}
trap cleanup_loop_lock EXIT INT TERM
```

- `LOCK_DIR` is `.claude/state/locks/loop-session.lock.d` (a directory)
- `mkdir` is atomic so no TOCTOU race (even if 2 processes run simultaneously, only one succeeds)
- Write lock metadata to `${LOCK_DIR}/meta.json`: JSON `{"pid": <pid>, "session_id": <session>, "started_at": <ISO8601>, "args": "<args>"}`
- If a lock already exists, immediately stop with an `already running` error (exit 10)
- Delete the lock on `EXIT` / `INT` / `TERM` (cleanup regardless of normal or abnormal exit)
- `rm -rf` is idempotent (safe to delete twice)

### Step 0.5: State consistency check (idempotency guard (b))

```bash
# Run lightweight consistency check in --quick mode at the start of wake-up
# Stop the loop immediately if it fails (protection against Plans.md corruption / uninitialized environment)
if bash "${HARNESS_PLUGIN_ROOT}/tests/validate-plugin.sh" --quick; then
    : # OK — continue
else
    echo "harness-loop: state consistency check failed — stopping loop" >&2
    echo "Details: run bash \"${HARNESS_PLUGIN_ROOT}/tests/validate-plugin.sh\" --quick to inspect" >&2
    exit 1
fi
```

- `${HARNESS_PLUGIN_ROOT}/tests/validate-plugin.sh --quick` is lightweight and completes within a few seconds
- Check contents: existence of `.claude/state/` / Plans.md existence + v2 format / sprint-contract format
- Does not run full validation (39 verification items)
- If this check fails with intentionally corrupted Plans.md, the loop immediately stops

### Step 1: Read Plans.md first

```bash
# Extract cc:WIP / cc:TODO tasks and identify the first task's task_id
grep -E "cc:(WIP|TODO)" Plans.md | head -1
```

- If `cc:WIP` tasks remain: possibly interrupted from the previous cycle → get task_id and continue
- If `cc:TODO` tasks exist: get task_id as the next target task
- If neither: **all tasks complete** → loop exits normally

> **Prerequisite 41.1.2**: If `plans-watcher.sh` protects Plans.md with flock,
> Plans.md reading must be done within that flock scope.
> Before 41.1.2 release, direct reading without flock is allowed.

### Step 2: Check for and generate sprint-contract

```bash
CONTRACT_PATH=".claude/state/contracts/${task_id}.sprint-contract.json"

if [ ! -f "${CONTRACT_PATH}" ]; then
    # Contract not yet generated → generate it
    node "${HARNESS_PLUGIN_ROOT}/scripts/generate-sprint-contract.js" "${task_id}"

    # Step 2.5: Promote draft → approved (first generation only)
    # generate-sprint-contract.js initializes with review.status == "draft",
    # so promote before ensure-sprint-contract-ready.sh (which requires approved)
    bash "${HARNESS_PLUGIN_ROOT}/scripts/enrich-sprint-contract.sh" "${CONTRACT_PATH}" \
      --check "Auto-approve on wake-up (harness-loop: confirm DoD from reviewer perspective)" \
      --approve
fi
```

- Check whether `.claude/state/contracts/${task_id}.sprint-contract.json` exists
- If absent, generate with `node "${HARNESS_PLUGIN_ROOT}/scripts/generate-sprint-contract.js" ${task_id}`
  (Note: .sh→.js rename planned in 41.5.1; for now call existing name via node)
- **Immediately after generation (first time only)**: promote `draft` → `approved` with `enrich-sprint-contract.sh --approve`
  - `generate-sprint-contract.js` initializes with `review.status == "draft"`
  - `ensure-sprint-contract-ready.sh` (next Step 3) only accepts `approved`
  - Place inside `if [ ! -f ... ]` block so it does not apply to existing contracts (already approved in previous cycles)
- Reuse `${CONTRACT_PATH}` in subsequent steps

### Step 3: Contract readiness check

```bash
bash "${HARNESS_PLUGIN_ROOT}/scripts/ensure-sprint-contract-ready.sh" "${CONTRACT_PATH}"
```

- Confirm that the sprint-contract's `review.status == "approved"`
- Stop with an error if an unapproved contract remains

### Step 4: Reload Resume pack

```
Step 4. Reload harness-mem resume-pack:
  Call the mcp__harness__harness_mem_resume_pack tool.
  Required arguments:
    - project: current project name (follow the implementation example of the existing session-init skill.
              Example: get the repo root with `basename $(git rev-parse --show-toplevel)` and pass it)
  optional: session_id (when resuming from a previous session)

  Example (pseudo-code):
    resume_pack = mcp__harness__harness_mem_resume_pack(
      project="claude-code-harness",
      session_id=<session_id from previous checkpoint>
    )
```

After a wake-up with a fresh context, memory from the previous cycle is lost.
Re-inject the following with the harness-mem resume-pack equivalent operation:

- `decisions.md` — architecture decisions
- `patterns.md` — reuse patterns
- `session-state` — previous work state
- Most recent cycle `checkpoint` — what was completed

> **Note**: Resume pack reload must be done after Step 3 (contract readiness check).
> Skipping it risks duplicate implementation of previous cycle artifacts.

### Step 4.5: Advisor consult (only when needed)

The loop proceeds under executor initiative; advisor is called only when needed.
Consult at exactly the following 3 triggers.

1. Before first execution of a high-risk task
2. After the same cause fails twice in a row
3. Just before stopping due to `PIVOT_REQUIRED`

```bash
TRIGGER_HASH="${task_id}:${reason_code}:$(normalize_error_signature "${summary_or_risk}")"

if ! advisor_trigger_seen "${TRIGGER_HASH}"; then
    RESPONSE_FILE=$(
        bash "${HARNESS_PLUGIN_ROOT}/scripts/run-advisor-consultation.sh" \
          --request-file ".claude/state/codex-loop/${task_id}.${reason_code}.advisor-request.json" \
          --response-file ".claude/state/codex-loop/${task_id}.${reason_code}.advisor-response.json"
    )
    DECISION=$(jq -r '.decision' "${RESPONSE_FILE}")
fi
```

- `PLAN` / `CORRECTION`: insert advice at the top of the next executor prompt and re-execute
- `STOP`: stop the loop and record `last_decision`, `last_trigger`, `last_model` in `run.json`
- Consult the same `trigger_hash` only once
- Maximum 3 consultations per task

### Step 5: Execute one task cycle

Spawn `claude-code-harness:worker` via the Agent tool:

> **Important**: Specify `"claude-code-harness:worker"`, not `"harness-work"`, for `subagent_type`.
> `harness-work` is a skill, not an agent. The actual agents are `worker` / `reviewer` / `scaffolder`.
> Specifying `"harness-work"` will cause Agent spawn to fail and the loop will stop at the first Worker launch.

```python
worker_result = Agent(
    subagent_type="claude-code-harness:worker",  # <- worker agent (not a skill)
    prompt="""
    Task: ${task_id}
    DoD: <extracted from Plans.md>
    contract_path: ${CONTRACT_PATH}
    mode: breezing
    After completion: return commit hash, branch, and change summary.
    """,
    isolation="worktree",
    run_in_background=false  # foreground execution (wait until complete)
)
# worker_result: { commit, branch, worktreePath, files_changed, summary }
```

Worker operates in `mode: breezing` so:
- Only commits on the feature branch; does not touch main
- Changes are stored in `worktreePath`
- Lead (harness-loop) handles review → cherry-pick in Steps 5.5/5.6

> **Codex loop implementation difference**: The Codex version launches a background task via `${HARNESS_PLUGIN_ROOT}/scripts/codex-loop.sh`,
> and prepends guidance returned by the advisor to the next prompt before re-executing the same task.

> **Implementation note**: `Bash("harness-work --breezing")` is also an alternative,
> but going through the Agent tool makes context isolation clearer and easier to debug.

### Step 5.5: Lead review execution

Lead reviews the commit returned by Worker:

```bash
# Get diff (targeting the commit in the worktree)
diff_text=$(git -C "${worker_result.worktreePath}" show "${worker_result.commit}")

# ── (a) Codex companion review: Run in Worker's worktree directory ──────────────────────────────
# If Lead is in the main repo dir, the diff will be empty (risk of unconditional APPROVE).
# Running review from Worker's worktreePath passes the correct diff.
#
# If worktreePath is empty or same as main repo (worktree isolation not available),
# run in Lead dir (fallback equivalent to existing behavior).

MAIN_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
WORKER_PATH="${worker_result.worktreePath:-}"

if [ -n "${WORKER_PATH}" ] && [ "${WORKER_PATH}" != "${MAIN_REPO_ROOT}" ]; then
    # Run review in Worker's worktree → sees actual diff of Worker feature branch
    ( cd "${WORKER_PATH}" && bash "${HARNESS_PLUGIN_ROOT}/scripts/codex-companion.sh" review --base "${BASE_REF}" )
    REVIEW_EXIT=$?
    # review-output.json is created in Worker worktree dir, so manage with absolute path
    REVIEW_OUTPUT_PATH="${WORKER_PATH}/review-output.json"
else
    # Fallback: run in Lead dir (environment where worktree isolation is unavailable)
    bash "${HARNESS_PLUGIN_ROOT}/scripts/codex-companion.sh" review --base "${BASE_REF}"
    REVIEW_EXIT=$?
    REVIEW_OUTPUT_PATH="$(pwd)/review-output.json"
fi
# → verdict is written to the file indicated by REVIEW_OUTPUT_PATH
# All subsequent steps must use $REVIEW_OUTPUT_PATH (do not directly reference relative path "review-output.json")

# ── (b) reviewer_profile branching (check review.reviewer_profile in sprint-contract) ──
# CONTRACT_PATH uses the value determined in Step 2/3 (do not overwrite here)
if command -v jq >/dev/null 2>&1; then
    REVIEWER_PROFILE=$(jq -r '.review.reviewer_profile // "static"' "${CONTRACT_PATH}" 2>/dev/null || echo "static")
else
    REVIEWER_PROFILE="static"
fi

case "${REVIEWER_PROFILE}" in
    runtime)
        # Execute runtime validation commands, potentially overwriting verdict
        # run-contract-review-checks.sh must run inside Worker's worktree (test env is inside worktree)
        # Important: stdout of run-contract-review-checks.sh is the artifact "file path" (not JSON payload)
        if [ -n "${WORKER_PATH}" ] && [ "${WORKER_PATH}" != "${MAIN_REPO_ROOT}" ]; then
            RUNTIME_ARTIFACT_PATH=$(
                cd "${WORKER_PATH}" && bash "${HARNESS_PLUGIN_ROOT}/scripts/run-contract-review-checks.sh" "${CONTRACT_PATH}" 2>/dev/null
            ) || RUNTIME_ARTIFACT_PATH=""
        else
            RUNTIME_ARTIFACT_PATH=$(
                bash "${HARNESS_PLUGIN_ROOT}/scripts/run-contract-review-checks.sh" "${CONTRACT_PATH}" 2>/dev/null
            ) || RUNTIME_ARTIFACT_PATH=""
        fi

        # If empty (script failure), treat as DOWNGRADE_TO_STATIC
        if [ -z "${RUNTIME_ARTIFACT_PATH}" ]; then
            RUNTIME_ARTIFACT_PATH=""
            RUNTIME_VERDICT="DOWNGRADE_TO_STATIC"
        else
            # If relative path, make absolute using WORKER_PATH (or Lead dir) as base
            if [[ "${RUNTIME_ARTIFACT_PATH}" != /* ]]; then
                if [ -n "${WORKER_PATH}" ] && [ "${WORKER_PATH}" != "${MAIN_REPO_ROOT}" ]; then
                    RUNTIME_ARTIFACT_PATH="${WORKER_PATH}/${RUNTIME_ARTIFACT_PATH}"
                else
                    RUNTIME_ARTIFACT_PATH="$(pwd)/${RUNTIME_ARTIFACT_PATH}"
                fi
            fi

            # Read verdict from artifact file
            if command -v jq >/dev/null 2>&1; then
                RUNTIME_VERDICT=$(jq -r '.verdict // "DOWNGRADE_TO_STATIC"' "${RUNTIME_ARTIFACT_PATH}" 2>/dev/null || echo "DOWNGRADE_TO_STATIC")
            else
                RUNTIME_VERDICT=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('verdict','DOWNGRADE_TO_STATIC'))" "${RUNTIME_ARTIFACT_PATH}" 2>/dev/null || echo "DOWNGRADE_TO_STATIC")
            fi
        fi

        if [ "${RUNTIME_VERDICT}" = "REQUEST_CHANGES" ]; then
            # Runtime validation failed → overwrite verdict with REQUEST_CHANGES
            # Pass runtime artifact to write-review-result.sh (do not use static review-output.json)
            EFFECTIVE_VERDICT="REQUEST_CHANGES"
            REVIEW_RESULT_INPUT="${RUNTIME_ARTIFACT_PATH}"
        elif [ "${RUNTIME_VERDICT}" = "DOWNGRADE_TO_STATIC" ]; then
            # No runtime validation command → use static verdict as-is
            EFFECTIVE_VERDICT=""  # → read from REVIEW_OUTPUT_PATH
            REVIEW_RESULT_INPUT="${REVIEW_OUTPUT_PATH}"
        else
            EFFECTIVE_VERDICT="${RUNTIME_VERDICT}"
            REVIEW_RESULT_INPUT="${RUNTIME_ARTIFACT_PATH}"
        fi
        ;;
    browser)
        # Generate artifact for browser reviewer to use subsequently
        # Browser artifact is PENDING_BROWSER scaffold. Actual browser execution is the reviewer agent's responsibility.
        # review-result verdict stays static (not PENDING_BROWSER).
        bash "${HARNESS_PLUGIN_ROOT}/scripts/generate-browser-review-artifact.sh" "${CONTRACT_PATH}" 2>/dev/null || true
        EFFECTIVE_VERDICT=""  # → read from REVIEW_OUTPUT_PATH (use static verdict)
        REVIEW_RESULT_INPUT="${REVIEW_OUTPUT_PATH}"
        ;;
    *)
        # static (default): use Codex companion review verdict as-is
        EFFECTIVE_VERDICT=""
        REVIEW_RESULT_INPUT="${REVIEW_OUTPUT_PATH}"
        ;;
esac

# If EFFECTIVE_VERDICT is not set, read from REVIEW_OUTPUT_PATH (absolute path)
if [ -z "${EFFECTIVE_VERDICT}" ]; then
    if command -v jq >/dev/null 2>&1; then
        EFFECTIVE_VERDICT=$(jq -r '.verdict // "REQUEST_CHANGES"' "${REVIEW_OUTPUT_PATH}" 2>/dev/null || echo "REQUEST_CHANGES")
    else
        EFFECTIVE_VERDICT=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('verdict','REQUEST_CHANGES'))" "${REVIEW_OUTPUT_PATH}" 2>/dev/null || echo "REQUEST_CHANGES")
    fi
fi

# Normalize and save review-result
# REVIEW_RESULT_INPUT is the runtime artifact path when runtime REQUEST_CHANGES; otherwise REVIEW_OUTPUT_PATH
# This ensures runtime REQUEST_CHANGES propagates correctly to pretooluse-guard (response to point 4)
bash "${HARNESS_PLUGIN_ROOT}/scripts/write-review-result.sh" "${REVIEW_RESULT_INPUT}" "${worker_result.commit}"
```

**Verdict determination**:

| verdict | Action |
|---------|----------|
| `APPROVE` | Proceed to Step 5.6 (cherry-pick) |
| `REQUEST_CHANGES` | Enter correction loop (up to 3 times) |

**Correction loop (on REQUEST_CHANGES)**:

```python
review_count = 0
latest_commit = worker_result.commit
worker_id = worker_result.agentId
# Read max_iterations from sprint-contract if it exists. Default to 3 (backward compat) if not.
MAX_REVIEWS = read_contract(contract_path, ".review.max_iterations") or 3

while verdict == "REQUEST_CHANGES" and review_count < MAX_REVIEWS:
    # Instruct Worker to fix (resume via SendMessage)
    SendMessage(to=worker_id, message=f"Issues found: {issues}\nPlease fix and amend.")
    updated_result = wait_for_response(worker_id)
    latest_commit = updated_result.commit
    diff_text = git("-C", worker_result.worktreePath, "show", latest_commit)
    verdict = codex_exec_review(diff_text) or reviewer_agent_review(diff_text)
    review_count += 1

if review_count >= MAX_REVIEWS and verdict != "APPROVE":
    # Escalation
    raise PivotRequired(f"Still REQUEST_CHANGES after {MAX_REVIEWS} corrections: {issues}")
```

### Step 5.6: APPROVE → cherry-pick to main

```bash
# Return to trunk branch (Worker worked on feature branch)
TRUNK=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main")
git checkout "${TRUNK}"

# Confirm that the feature branch commit is not already merged into trunk (re-entry prevention)
if ! git merge-base --is-ancestor "${latest_commit}" HEAD; then
    git cherry-pick --no-commit "${latest_commit}"
    git commit -m "${task_title}"
fi

# ── (c) cleanup order: worktree remove → branch -D ────────────────────────────────────────────
# When a feature branch is checked out in a worktree,
# `git branch -D` errors with "branch is checked out at <path>".
# Running worktree remove first allows branch -D to work safely.
#
# Order:
#   1. cherry-pick → merged into main (git commit done above)
#   2. worktree remove (delete the worktree where the feature branch was checked out)
#   3. branch -D (now safe to delete since worktree was removed)

MAIN_REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
WORKER_PATH="${worker_result.worktreePath:-}"

# Step 2: worktree remove
if [ -n "${WORKER_PATH}" ] && [ "${WORKER_PATH}" != "${MAIN_REPO_ROOT}" ]; then
    git worktree remove "${WORKER_PATH}" --force 2>/dev/null || true
fi

# Step 3: branch -D (safe now that worktree is removed)
if [ -n "${worker_result.branch}" ] && \
   [ "${worker_result.branch}" != "main" ] && \
   [ "${worker_result.branch}" != "master" ] && \
   [ "${worker_result.branch}" != "${TRUNK}" ]; then
    git branch -D "${worker_result.branch}" 2>/dev/null || true
fi
```

Update Plans.md:

```bash
# Update cc:WIP → cc:done [{hash}]
HASH=$(git rev-parse --short HEAD)
# Update the relevant task line in Plans.md
```

### Step 6: Plateau determination

```bash
bash "${HARNESS_PLUGIN_ROOT}/scripts/detect-review-plateau.sh" ${current_task_id}
PLATEAU_EXIT=$?
# * current_task_id is the task_id identified in Step 1
```

| exit code | Meaning | Action |
|-----------|------|----------|
| `0` | `PIVOT_NOT_REQUIRED` | Continue |
| `1` | `INSUFFICIENT_DATA` | Continue (insufficient data) |
| `2` | `PIVOT_REQUIRED` | Insert advisor once. Stop loop + escalate only when `STOP` or advisory quota exhausted |

**Escalation message on PIVOT_REQUIRED**:

```
harness-loop: stopped due to plateau detection (cycle {N}/{max})

Detected issues:
  {plateau details: output from detect-review-plateau.sh}

Suggested responses:
  1. Manually review task content
  2. Re-run with `--pacing plateau` to increase interval
  3. Skip the problem task and restart `/harness-loop`

Please check the current Plans.md state.
```

### Step 7: Cycle count check

```
cycles_completed += 1
if cycles_completed >= max_cycles:
    stop loop
    print(f"harness-loop: stopped after {max_cycles} cycles")
    return
```

- default `max_cycles = 8`
- Stop at N cycles when `--max-cycles N` is specified

**Cycle count persistence**:
- Embed count in the `prompt` argument of `ScheduleWakeup`:
  ```
  /harness-loop all --max-cycles 8 --cycles-done {N} --pacing worker
  ```
- Restore count by reading `--cycles-done N` at wake-up

### Step 8: Record checkpoint

```json
{
  "session_id": "<current session ID>",
  "title": "harness-loop cycle {N}/{max}: {task_completed}",
  "content": "cycle {N} complete. commit: {commit}. changes: {files_changed}. next: {next_task}"
}
```

Record to memory using the `harness_mem_record_checkpoint` tool.
Automatically included in the next wake-up's resume pack.

### Step 9: Schedule next wake-up

```
ScheduleWakeup(
    delaySeconds=<value corresponding to pacing>,
    prompt="/harness-loop <same args> --cycles-done {N}",
    reason="cycle {N}/{max} complete: {task_completed}"
)
```

**delaySeconds corresponding to pacing**:

| pacing | delaySeconds | Selection rationale |
|--------|-------------|---------|
| `worker` | 270 | Re-entry right after Worker completion (within 5 min cache warm) |
| `ci` | 270 | Expected minimum CI job completion wait |
| `plateau` | 1200 | 20 min cooling period (plateau avoidance) |
| `night` | 3600 | Overnight batch (max clamp value) |

> **Clamp constraint**: `ScheduleWakeup` clamps `delaySeconds` to `[60, 3600]` at runtime.
> Values below 60 are rounded up to 60; values above 3600 are rounded down to 3600.
> All design values are within range, but note for future changes.

---

## Cycle Stop Condition Matrix

| Condition | Cycle count | exit | Stop reason | User notification |
|------|-----------|------|---------|------------|
| `cycles >= max_cycles` | N (limit) | 0 | Normal limit reached | "Stopped after {N} cycles" |
| `PIVOT_REQUIRED` | Any | 2 | Plateau detected | Escalation details |
| No incomplete tasks | Any | 0 | All tasks complete | Completion report |
| User cancel | Any | - | Manual interrupt | - |

---

## Pacing Selection Guide

### Which pacing to use

```
What is the nature of the task?
│
├── Want to re-enter right after Worker completion
│     → worker (270s)
│
├── Need to wait for CI / test completion
│     → ci (270s)
│     * Manually adjust --pacing if CI takes longer than 270s
│
├── Want to detect plateau and add a gap
│     → plateau (1200s)
│
└── Want to leave overnight and check in the morning
      → night (3600s)
```

### When to change pacing

- **On initial launch**: usually `worker` (default) is fine
- **When CI waits are frequent**: switch to `--pacing ci`
- **After plateau detection**: consider auto-switching to `--pacing plateau` (see Step 5)
- **Overnight leave**: launch with `--pacing night` and go to sleep

---

## ScheduleWakeup Constraint Details

### Runtime constraints on delaySeconds

```
ScheduleWakeup(delaySeconds=X)
  → X < 60  → clamp to 60
  → X > 3600 → clamp to 3600
  → 60 <= X <= 3600 → use as-is
```

### Relationship with cache TTL

ScheduleWakeup's cache TTL is **5 min (300s)**.

- `worker` / `ci` at 270s is within 5 min → wake-up with cache warm
- `plateau` at 1200s, `night` at 3600s wake up after cache expires
  → Step 2 (resume pack reload) is particularly important

### Passing arguments to the next wake-up

How to carry the cycle count to the next wake-up:

```bash
# Embed current cycle count in the prompt
NEXT_PROMPT="/harness-loop ${SCOPE} --max-cycles ${MAX_CYCLES} --cycles-done ${CYCLES_DONE} --pacing ${PACING}"

ScheduleWakeup(
    delaySeconds=${DELAY},
    prompt="${NEXT_PROMPT}",
    reason="cycle ${CYCLES_DONE}/${MAX_CYCLES} complete"
)
```

---

## Reference: spike 41.0.0 verification results

This design is based on the empirical results of spike 41.0.0:

- `ScheduleWakeup`: confirmed to exist as an internal tool. delay [60, 3600] clamp, cache 5min TTL
- `/loop`: confirmed to exist as CC dynamic mode. sentinel `<<autonomous-loop-dynamic>>`
- `harness_mem_record_checkpoint`: confirmed to exist (schema: session_id / title / content required)

Update this file if these assumptions change.
