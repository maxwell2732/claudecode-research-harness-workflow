---
name: harness-loop
description: "Long-running task loop using /loop (Claude Code dynamic mode) and ScheduleWakeup to re-enter with fresh context on each wake-up. Internally invokes harness-work through Agent. Trigger: long-running, loop, wake-up, autonomous. Do NOT load for: one-shot task execution, review, release, planning."
description-en: "Long-running task loop using /loop (Claude Code dynamic mode) and ScheduleWakeup to re-enter with fresh context on each wake-up. Internally invokes harness-work through Agent. Trigger: long-running, loop, wake-up, autonomous. Do NOT load for: one-shot task execution, review, release, planning."
kind: workflow
purpose: "Re-enter long-running Plans.md execution with fresh context"
trigger: "long-running, loop, wake-up, autonomous"
shape: delegate
role: orchestrator
base: harness-work
pair: harness-sync
owner: harness-core
since: "2026-05-05"
allowed-tools: ["Read", "Edit", "Bash", "Task", "ScheduleWakeup", "mcp__harness__harness_mem_resume_pack", "mcp__harness__harness_mem_record_checkpoint"]
argument-hint: "[all|N-M] [--max-cycles N] [--pacing worker|ci|plateau|night]"
user-invocable: true
---

# harness-loop

A meta-skill that combines `/loop` (CC dynamic mode) with `ScheduleWakeup` to **re-enter long-running tasks with fresh context on each wake-up**.

Calls `harness-work --breezing` via Agent on each wake-up,
constructing a re-enterable loop where 1 cycle = 1 task completion.

> **Long-session helpers (CC 2.1.108+)**:
> When you return, run `/recap` to get a fresh summary before checking `/harness-loop status`.
> For operations with long absences or frequent re-entries, prioritize `ENABLE_PROMPT_CACHING_1H=1`.

> **Long session recommendation (CC 2.1.108+)**:
> When the session is expected to exceed 30 minutes, run `bash "${HARNESS_PLUGIN_ROOT}/scripts/enable-1h-cache.sh"` after resolving the plugin bundle root to opt in to 1-hour prompt caching.

> **Codex 0.123.0 automatic bug fix inheritance**:
> Manual shell follow-up queue and `/copy` after rollback are automatically inherited as Codex TUI fixes.
> The loop runner does not add additional input queues, copy wrappers, or rollback workarounds.
> Queueing when manual shell follow-ups are sent during long-running work is left to the Codex runtime.

## Quick Reference

| Input | Action |
|------|------|
| `/harness-loop all` | Loop through all incomplete tasks (default: max 8 cycles) |
| `/harness-loop all --max-cycles 3` | Stop after 3 cycles |
| `/harness-loop 41.1-41.3 --pacing ci` | Execute task range with CI pacing |
| `/harness-loop all --plan roadmap` | Loop through the `roadmap` named Plans |
| `/harness-loop all --pacing night` | Overnight batch (3600s interval) |
| `/harness-loop status` | Check status of running runner |
| `/harness-loop stop` | Request stop of running runner |

## Options

| Option | Description | Default |
|----------|------|----------|
| `all` | Target all incomplete tasks | - |
| `N-M` | Specify task number range | - |
| `--plan NAME` | Use named plan from `plans/manifest.json` | active/default |
| `--max-cycles N` | Maximum number of cycles | `8` |
| `--pacing <mode>` | Wake-up interval mode | `worker` (270s) |

### Pacing value mapping

| pacing | delaySeconds | Use |
|--------|-------------|------|
| `worker` | 270 | Right after Worker completion (cache warm within 5 min) |
| `ci` | 270 | Short CI job wait |
| `plateau` | 1200 | 20 min (retry interval after plateau detection) |
| `night` | 3600 | Extended overnight leave |

> **Constraint**: `ScheduleWakeup`'s `delaySeconds` is clamped to **[60, 3600]** at runtime.
> `worker` / `ci` at 270s and `night` at 3600s are within this range.
> `plateau` at 1200s is also within range. When specifying directly, always use 60 or above and 3600 or below.

## Launch Flow (entry per wake-up)

Detailed version: [`${CLAUDE_SKILL_DIR}/references/flow.md`](${CLAUDE_SKILL_DIR}/references/flow.md)

### Plugin bundle root resolution

`harness-loop` calls helper scripts under the plugin bundle root, not the host project's cwd.
Think of it as separating the workbench (host project) from the toolbox (plugin bundle).

At the start of each wake-up, determine `HARNESS_PLUGIN_ROOT` in this order:

1. Use `CLAUDE_PLUGIN_ROOT` if it is present and contains `scripts/`
2. If `CLAUDE_PLUGIN_ROOT` is absent, reverse-calculate the plugin bundle root from `CLAUDE_SKILL_DIR`
   - `${CLAUDE_SKILL_DIR}/../..` for `skills/harness-loop` distribution
   - `${CLAUDE_SKILL_DIR}/../../..` for `.agents/skills/harness-loop` mirror distribution
3. If neither resolves, stop and re-run after setting `CLAUDE_PLUGIN_ROOT` to the plugin bundle root

Keep `Plans.md` and `.claude/state/...` on the host project side.
Only call helper scripts from `${HARNESS_PLUGIN_ROOT}/scripts/...`.

In repos with multiple Plans.md, specify `--plan NAME` explicitly at the start of a long run.
The runner retains the Plans file resolved at start time across cycles; do not switch the active plan mid-run.

```
wake-up
  │
  ▼
[Step 0] Resolve plugin bundle root to HARNESS_PLUGIN_ROOT
  Use CLAUDE_PLUGIN_ROOT if valid
  Otherwise reverse-calculate plugin bundle root from CLAUDE_SKILL_DIR
  * Do not reference host project cwd's scripts/
  │
  ▼
[Step 1] Read Plans.md first
  Identify first cc:WIP / cc:TODO task (get task_id)
  * No incomplete tasks → loop ends (normal completion)
  │
  ▼
[Step 2] Check for and generate sprint-contract
  Check for .claude/state/contracts/${task_id}.sprint-contract.json
  If absent, generate with node "${HARNESS_PLUGIN_ROOT}/scripts/generate-sprint-contract.js" ${task_id}
  Immediately after generation (first time only): bash "${HARNESS_PLUGIN_ROOT}/scripts/enrich-sprint-contract.sh" <contract-path> \
    --check "Auto-approve on wake-up (harness-loop: confirm DoD from reviewer perspective)" \
    --approve  <- promote draft → approved
  (Skip for existing contracts since they are already approved)
  │
  ▼
[Step 3] Contract readiness check
  bash "${HARNESS_PLUGIN_ROOT}/scripts/ensure-sprint-contract-ready.sh" <contract-path>
  │
  ▼
[Step 4] Reload Resume pack
  harness-mem resume-pack (re-inject context)
  │
  ▼
[Step 4.5] Advisor consult (only when needed)
  Consult before first execution of high-risk tasks / after 2nd failure with same cause / just before plateau
  Build `advisor-request.v1` and consult
  │
  ├── PLAN        → prepend advice to next executor prompt
  ├── CORRECTION  → re-execute as local fix instruction
  └── STOP        → stop loop immediately and record reason
  │
  ▼
[Step 5] Execute one task cycle
  worker_result = Agent(
      subagent_type="claude-code-harness:worker",  # worker agent (not harness-work)
      prompt="Task: ${task_id}\nDoD: <extracted from Plans.md>\ncontract_path: ${CONTRACT_PATH}\nmode: breezing",
      isolation="worktree",
      run_in_background=false
  )
  # worker_result: { commit, branch, worktreePath, files_changed, summary }
  │
  ▼
[Step 5.5] Lead review execution
  diff_text = git show worker_result.commit
  verdict = codex_exec_review(diff_text) or reviewer_agent_review(diff_text)
  * See flow.md for details
  │
  ▼
[Step 5.6] APPROVE → cherry-pick to main / REQUEST_CHANGES → correction loop (max_iterations from contract, default 3)
  APPROVE: git cherry-pick → update Plans.md to cc:done [{hash}] → delete feature branch
  Still rejected after MAX_REVIEWS: escalation
  * See flow.md for details
  │
  ▼
[Step 6] Plateau determination
  bash "${HARNESS_PLUGIN_ROOT}/scripts/detect-review-plateau.sh" ${current_task_id}
  │
  ├── PIVOT_REQUIRED (exit 2)  → stop loop + user escalation
  ├── INSUFFICIENT_DATA (exit 1) → continue
  └── PIVOT_NOT_REQUIRED (exit 0) → continue
  │
  ▼
[Step 7] Cycle count check
  │
  ├── cycles >= max_cycles → stop loop (limit reached)
  │
  ▼
[Step 8] Record checkpoint
  harness_mem_record_checkpoint(
      session_id, title, content=cycle result summary
  )
  │
  ▼
[Step 9] Schedule next wake-up
  ScheduleWakeup(
      delaySeconds=<pacing value>,
      prompt="/harness-loop <same args>",
      reason="cycle {N}/{max} complete — proceeding to next task"
  )
```

## Cycle Stop Conditions

| Condition | Stop type | Response |
|------|---------|------|
| `cycles >= max_cycles` | Normal stop (limit reached) | Report to user |
| `PIVOT_REQUIRED` (exit 2) | Abnormal stop (escalation) | Ask user for decision |
| No incomplete tasks | Normal stop (all complete) | Output completion report |

Stops after 3 cycles when `--max-cycles 3` is specified.
Stops after 8 cycles by default (`--max-cycles 8`).

## Interim Reports / Silence Policy

In long-running loops, interim reports are treated as "notifications when a decision changes" rather than "heartbeats for reassurance".
In environments where Codex `0.123.0` background agents can receive transcript deltas, do not respond merely because a delta arrived; maintain explicit silence when not needed.

Report:

- Cycle complete, limit reached, all complete, blocked
- Validation failure, review `REQUEST_CHANGES`, plateau, advisor `STOP`
- Advisor / reviewer drift, contract readiness failure
- Summary when user requests `status`

Silence is acceptable:

- When only transcript deltas increase and task / review / advisor state has not changed
- When only fine-grained stdout in logs increases
- During pacing wait between next wake-ups

Default is "1 final report per cycle".
However, unanswered Advisor requests, pending Reviewer results, and pre-plateau warnings take priority over the silence policy.

## Integration with /loop

This skill is used in combination with CC's `/loop` (dynamic mode).

When `/loop` is enabled, CC continues autonomous re-entry execution,
and calls `ScheduleWakeup` at the end of each cycle to schedule the next wake-up.

`/loop` sentinel: `<<autonomous-loop-dynamic>>`

Each wake-up starts with **fresh context**, preventing context contamination from previous cycles.
Reloading the resume pack via `harness-mem resume-pack` is required (Step 2).

## Checkpoint recording

`harness_mem_record_checkpoint` schema:

```json
{
  "session_id": "<session ID>",
  "title": "harness-loop cycle {N}/{max}: {task name}",
  "content": "One-line summary of cycle_result + commit hash"
}
```

## Advisor Strategy

The main actor in this skill is the executor; the advisor is called only when needed.
Think of it as the responsible party running autonomously and consulting a veteran only for difficult parts.

Consultation conditions are fixed; natural-language "low confidence" judgments are not used.

| Condition | Consult? |
|------|-----------|
| `needs-spike` / `security-sensitive` / `state-migration` | Yes |
| `<!-- advisor:required -->` | Yes |
| 2nd failure with same cause | Yes |
| Just before stopping due to plateau | Yes |

Consult the same trigger only once.
Use `trigger_hash = task_id + reason_code + normalized_error_signature` for that determination.

## Related Skills

- `harness-work` — Task implementation skill executed each cycle
- `harness-plan` — Planning for loop target tasks
- `harness-review` — Review of individual tasks
- `session-control` — Session state management
