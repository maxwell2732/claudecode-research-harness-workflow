# Long-Running Task Execution Guide

This document is a practical guide for safely running **tasks that cannot be completed in a single session** with Claude Code.
"Long-running tasks" here refers to work that progresses incrementally using `/loop` and `ScheduleWakeup`.
This document is the output of Phase 41.4.1.

The scope is **same-session operation within Phase 41**. Automatic re-entry across different hosts is not covered at this stage.

Reference: [skills/harness-loop/SKILL.md](../skills/harness-loop/SKILL.md) / [skills/harness-loop/references/flow.md](../skills/harness-loop/references/flow.md) / [docs/CLAUDE-feature-table.md](CLAUDE-feature-table.md)

---

## 1. Understanding the big picture

Long-running tasks progress by repeating these 4 steps:

1. Decide the one unit of work to do now
2. Implement or verify in small increments
3. Leave the result as a checkpoint
4. Schedule the next wake-up

The key is **re-entering with a "fresh perspective" each time**.
Rather than carrying over the previous conversation as-is, re-inject only the necessary information via a resume pack and resume.

### 12-axis reference table (B1–B12)

| Axis | What to decide | Harness approach |
|------|---------------|-----------------|
| B1 | What to achieve | Read the target task and DoD in Plans.md |
| B2 | How far to go in one round | 1 cycle = 1 task unit |
| B3 | Where to start | Use `/loop` as the entry point |
| B4 | How to resume | Schedule the next wake-up with `ScheduleWakeup` |
| B5 | What to carry over | Use `harness-mem resume-pack` to return only needed info |
| B6 | How long to wait | Use `pacing` to choose the interval |
| B7 | When to stop | Set an upper limit with `--max-cycles` |
| B8 | How to avoid conflicts | Prevent multiple concurrent runs with lock and idempotency guard |
| B9 | How to record progress | Record checkpoints with `harness_mem_record_checkpoint` |
| B10 | Whether progress is going well | Detect stalls with plateau detection |
| B11 | What to include in scope | Phase 41 is limited to the same session |
| B12 | What to watch out for | Understand the limits of `bypassPermissions` and Plans.md flock |

---

## 2. How to use `/loop` + `ScheduleWakeup`

`/loop` is the entry point for telling Claude Code "assume work continues."
`ScheduleWakeup` is the mechanism for scheduling the next resume time.

### Basic usage

```text
/loop all
/loop 41.1-41.3 --pacing ci
/loop all --pacing night
```

### Flow for one round

1. Select the next target task from `Plans.md` (1 task)
2. Execute only the minimum work needed for that task
3. Leave a checkpoint
4. Schedule the next wake-up with `ScheduleWakeup`

### Example schedule

```text
ScheduleWakeup(
  delaySeconds=270,
  prompt="/harness-loop all --cycles-done 1 --pacing worker",
  reason="1 cycle complete. Proceeding to next task."
)
```

`delaySeconds` is "how many seconds before returning."
Too short feels rushed; too long makes it easy to forget the previous flow.
Keep it within the 60–3600 second range.

---

## 3. Choosing pacing presets

`pacing` is the setting for how long to wait before the next wake-up.

| pacing | delaySeconds | Best for | Note |
|--------|-------------:|---------|------|
| `worker` | 270 | Continuing right after previous work | Standard setting |
| `ci` | 270 | Waiting for CI results | Keeps wait time short |
| `plateau` | 1200 | Progress tends to stall | Cool down a bit longer |
| `night` | 3600 | Running through the night | Longest wait |

### Thinking about cache boundaries

Claude Code has a "short-term cache" that remembers the recent flow for a short time.
The 270 seconds for `worker` and `ci` is a length that tends to still fit within this short-term cache.

On the other hand, `plateau` and `night` are likely to exhaust the short-term cache, so **always assume resume pack** — the design shifts toward "re-inject needed information" rather than "remember on your own."

### Using 1-hour cache

Since Claude Code `2.1.108`, attaching `ENABLE_PROMPT_CACHING_1H=1` enables opt-in **1-hour cache**, longer than the usual 5-minute cache.

This is suited for "re-reading nearly the same premise each time, but the next input tends to exceed 5 minutes."
For long-running tasks covered in this document, it works well especially in these scenarios:

1. `/harness-loop` with wait periods between each cycle
2. Re-using the same premise across `/resume` or `/continue`
3. Returning after 5+ minutes following a review or advisor consult

Conversely, if only short back-and-forth of seconds to minutes continues, the default 5-minute cache is sufficient.

### 1h vs 5m cache selection criteria

| Criterion | Choose 1h cache | 5m cache (default) is sufficient |
|-----------|----------------|----------------------------------|
| Expected session length | **Exceeds 30 minutes** | Within 30 minutes |
| Wake-up interval | `plateau` (1200s) or `night` (3600s) | `worker`/`ci` (270s) |
| Premise information reuse | Reading nearly the same SKILL.md/Plans.md each cycle | Short back-and-forth where premises change every time |
| Target skill | `/breezing` / `/harness-loop` multi-task execution | One-off `/work` or dialogue |

**Decision rule**: Choose 1h cache if the **session is expected to exceed 30 minutes**. Otherwise, the default 5-minute cache is sufficient.

Opt-in procedure:

```bash
bash scripts/enable-1h-cache.sh
```

This command appends `ENABLE_PROMPT_CACHING_1H=1` to `env.local` (idempotent).
Does not change global settings. Does nothing if already set.

### Recommended adoption policy

In this repository, **do not enable always-on for all sessions**.
The reason is that the 1-hour cache is convenient but assumes additional cost and tends to be excessive for short dialogues.

Instead, use a thin startup wrapper dedicated to long-running tasks:

```bash
bash scripts/claude-longrun.sh
```

Arguments can be passed directly:

```bash
bash scripts/claude-longrun.sh --resume
bash scripts/claude-longrun.sh --model claude-opus-4-6
```

This script simply starts `claude` with `ENABLE_PROMPT_CACHING_1H=1` internally.
Since it does not change global settings, it does not spread impact to regular work.

### Env inheritance to child processes (Codex CLI integration)

When calling Codex CLI via `/breezing --codex` or `scripts/codex-companion.sh task --write`, you need to check whether `ENABLE_PROMPT_CACHING_1H` is inherited by child processes.

| Path | Inherited? | Notes |
|------|-----------|-------|
| `bash scripts/codex-companion.sh task --write "..."` | Yes | Normal bash subprocess inherits parent env |
| `bash scripts/codex-companion.sh review --base "${REF}"` | Yes | Same as above |
| Parent process launched by `claude-longrun.sh` | Yes | Scripts export before launching claude internally |
| When `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` is active | **May be scrubbed** | Design must not include `ENABLE_PROMPT_CACHING_1H` in scrub target env list |

The `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB="1"` in `.claude-plugin/settings.json` is intended to purge contaminated env vars in subprocesses, so Claude Code's own behavior-control env like `ENABLE_PROMPT_CACHING_1H` is normally preserved.
When adding new hook scripts or wrappers, either explicitly `export ENABLE_PROMPT_CACHING_1H` or use an implementation that does not discard env with `env -i bash`.

---

## 4. Wake-up count limit, lock, and idempotency guard

Long-running tasks can unknowingly run the same process twice.
To prevent this, use 3 layers of protection.

### 4-1. Count limit

Use `--max-cycles` to decide how many times to continue.
When the limit is reached, stop there for the time being.

### 4-2. Lock

Take a lock to prevent the same task from running twice simultaneously.
This repository uses `.claude/state/locks/loop-session.lock.d`.

A lock is a marker saying "this is already running."
If a lock already exists, stop the new execution.
This prevents conflicts from parallel execution.

### 4-3. Idempotency guard

Idempotency is the property of not breaking when the same operation is performed twice.
By running a light check like `tests/validate-plugin.sh --quick` first, you avoid proceeding forcefully in a broken state.

Also, always clean up the lock at exit.
Whether normal or abnormal exit, this prevents remnants from interfering with the next run.

---

## 5. Plateau detection and golden fixtures

A plateau is a state where work appears to be progressing but is actually going in circles in the same place.
For example, repeating the same fix over and over, or re-executions increasing without any new decision material.

### Thinking about thresholds

Actual judgment is based on the results of `scripts/detect-review-plateau.sh`.
The emphasis here is **whether new information is increasing** rather than "how many failures before stopping."

### What to use as fixtures

Golden fixtures to prevent regression are best placed under `tests/fixtures/`.
For example, organizing them in a dedicated bundle like `tests/fixtures/long-running-harness/` makes them easy to find.
For plateau-related cases in particular, fixing these scenarios is useful:

1. Cases where the failure reason is the same every time
2. Cases where the verdict does not change even when conditions are changed
3. Cases that appear to be progressing but are actually stalled

A fixture is a sample of "this verdict should remain the same in the future."
With this, when you later touch the logic, you can easily verify that stall detection is not broken.

---

## 6. Phase 41 scope

Phase 41 covers only **long-running tasks that are completed within the same Claude Code session**.

The work is limited to these 2 points:

1. Safe re-entry within the current session
2. Ability to continue the same work across wake-ups

What is NOT covered: automatic re-entry across different hosts.
That falls within the scope of future Phase 42+.

---

## 7. Known limitations

### Relationship with `bypassPermissions`

`/loop` is not a mechanism for increasing permissions.
It operates on the assumption that existing permission guards are in place.
This means that even when using `bypassPermissions`, dangerous operations are not unlimited.

In long-running tasks, it is more important to "not do powerful things without authorization."
Only the necessary operations, at the necessary timing, the necessary number of times.

### Limits of Plans.md flock

`Plans.md` may be touched by multiple executors.
The design uses flock for queuing, but this is **a mechanism to prevent simultaneous overwrites of the same file** — it is not foolproof.

In particular, when another session or process is reading simultaneously, the visible state may be slightly delayed.
Therefore, when reading `Plans.md`, hold the assumption that "what is visible now may not be the latest" and judge in conjunction with checkpoints and contracts.

---

## 8. Quick reference links

- Execution flow details: [skills/harness-loop/references/flow.md](../skills/harness-loop/references/flow.md)
- Command entry point: [skills/harness-loop/SKILL.md](../skills/harness-loop/SKILL.md)
- Claude Code feature list: [docs/CLAUDE-feature-table.md](CLAUDE-feature-table.md)

> **Note (v4.2.0+)**: `HARNESS_WEBHOOK_URL` should be set as an env variable. `[telemetry] webhook_url` in `harness.toml` was deprecated (2026-04-18 dead config cleanup).
