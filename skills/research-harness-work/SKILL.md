---
name: research-harness-work
description: "RES: Execute approved analysis tasks from analysis_plan.md. Writes scripts, runs them, saves logs and outputs, updates task status. Trigger: run analysis, execute task, run regression, produce table, produce figure. Do NOT load for: planning, review, release, setup, audit, cleaning."
description-en: "RES: Execute approved analysis tasks from analysis_plan.md. Writes scripts, runs them, saves logs and outputs, updates task status. Trigger: run analysis, execute task, run regression, produce table, produce figure. Do NOT load for: planning, review, release, setup, audit, cleaning."
kind: workflow
purpose: "Execute approved analysis tasks with reproducible scripts and mandatory log verification"
trigger: "run analysis, execute task, run regression, produce table, produce figure, /research-harness-work"
shape: workflow
role: executor
pair: research-harness-review
owner: research-harness-core
since: "2026-05-29"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
argument-hint: "[TASK-ID] [all] [--no-commit]"
user-invocable: true
effort: high
---

# Research Harness Work

Execute approved analysis tasks from `analysis_plan.md`. For each task, write a reproducible script, run it, verify the log exists, and update the evidence ledger.

This skill runs after `/research-harness-plan` (human-approved) and before `/research-harness-review`.

## Quick Reference

| Input | Action |
|---|---|
| `/research-harness-work 1.1` | Execute task 1.1 from `analysis_plan.md` |
| `/research-harness-work 2` | Execute all tasks in stage 2 sequentially |
| `/research-harness-work all` | Execute all `cc:todo` tasks sequentially |
| `/research-harness-work --no-commit` | Execute without committing; leave outputs for review |

**Default behavior with no argument:** ask the user which task or stage to run. Do not auto-select.

## Pre-flight Checks

Before executing any task:

1. Read `analysis_plan.md`. If it does not exist, stop and tell the user to run `/research-harness-plan` first.
2. Confirm the task ID exists in `analysis_plan.md` and its status is `cc:todo` or `cc:wip`. Do not re-execute `cc:done` tasks without explicit user instruction.
3. Confirm the analysis-ready dataset specified in `analysis_plan.md` exists under `data/processed/`.
4. If the task has `cc:blocked` status: report the blocking reason and stop. Do not work around a blocked task.

## Procedure

### Step 1 — Read the task definition

From `analysis_plan.md`, read for the specified task:

- Script path
- Log path
- Output path
- DoD (definition of done)
- Assumptions
- Unresolved questions
- Identification strength label

If the task has unresolved questions: stop and list them. Ask the user to resolve them before the task runs.

Mark the task `cc:wip` in `analysis_plan.md`.

### Step 2 — Write the analysis script

Write the script at the path specified in the task definition.

Script requirements:
- Language: use whichever language the study uses (R, Stata, Python). If not specified, use R.
- Header comment: study name, task ID, date, analyst (Claude Code), identification strategy from `study_spec.md` §2
- Project-relative paths only
- Set random seed if any random operation is used
- Open log file at the start; close at the end
- Log: task ID, date, dataset loaded, N rows loaded, any sample restrictions applied with N dropped and N remaining, all model results including coefficients and standard errors, N in estimation sample

**R template for regression task:**
```r
# Study: <study name>
# Task: <task-id> — <task description>
# Identification: <tag from study_spec.md>
# Date: YYYY-MM-DD
# Analyst: Claude Code

library(here)

log_file <- here("analysis", "<stage>", "logs", "<task>.log")
sink(log_file, append = FALSE, split = TRUE)

cat("Task:", "<task-id>", "\n")
cat("Started:", format(Sys.time()), "\n\n")

# Load
df <- read.csv(here("data", "processed", "analysis_ready.csv"))
cat("Loaded:", nrow(df), "rows\n")

# Sample restriction (if task-specific)
n_before <- nrow(df)
df <- df[<restriction>, ]
cat("After restriction:", nrow(df), "rows (dropped:", n_before - nrow(df), ")\n")

# Model
fit <- lm(<formula>, data = df)
cat("\n=== Results ===\n")
print(summary(fit))

# Save output
write.csv(broom::tidy(fit), here("output", "tables", "<task>.csv"), row.names = FALSE)
cat("\nOutput written to: output/tables/<task>.csv\n")
cat("Finished:", format(Sys.time()), "\n")
sink()
```

Do not hard-code numerical results into the script. The script computes them; the log records them.

### Step 3 — Run the script

Run the script. Capture the exit code and the full log output.

- Exit code 0: proceed to Step 4
- Exit code non-zero (attempt 1): read the log, identify the error, fix the script, re-run
- Exit code non-zero (attempt 2): read the log again, fix the specific error, re-run
- Exit code non-zero (attempt 3): stop. Do not invent output. Write the error to `analysis_plan.md` under the task. Mark the task `cc:blocked`. Tell the user what failed and why.

Do not continue to the next step if the script did not exit with code 0.

### Step 4 — Verify evidence

After a successful run, verify:

1. Log file exists at the path specified in the task definition
2. Output file (table or figure) exists at the path specified
3. The log contains the numerical results that will be reported (coefficients, standard errors, sample size)

If any verification fails: do not mark the task `cc:done`. Report what is missing.

### Step 5 — Update analysis_plan.md

Add an evidence row to the Evidence Ledger in `analysis_plan.md`:

| Task | Script | Log | Output | Verified | Date |
|---|---|---|---|---|---|
| 1.1 | `analysis/descriptive/scripts/table1.R` | `analysis/descriptive/logs/table1.log` | `output/tables/table1.csv` | YES | YYYY-MM-DD |

Mark the task status `cc:done`.

### Step 6 — Report completion

Print a task completion summary:

```
Task 1.1 — Complete

Script:  analysis/descriptive/scripts/table1.R
Log:     analysis/descriptive/logs/table1.log   [exists: YES]
Output:  output/tables/table1.csv               [exists: YES]
Status:  cc:done

Key results from log:
  N = <value from log>
  [other key stats from log]

Next task: 1.2 or run /research-harness-work 1.2
```

Do not paraphrase or interpret the results. Quote them from the log.

## Forbidden Actions

- Do not report any number that is not present in the log file
- Do not mark a task `cc:done` unless the log file and output file both exist
- Do not continue after a script failure without documenting the error
- Do not change `analysis_plan.md` task scope without recording the change under the task
- Do not use absolute file paths in scripts
- Do not execute a task that is `cc:blocked` without user instruction
- Do not run tasks that were not in the approved `analysis_plan.md` without user instruction

## Evidence Requirements

- Script file exists at the documented path
- Log file exists at the documented path
- Output file exists at the documented path
- Evidence row added to `analysis_plan.md`
- Task status updated to `cc:done` in `analysis_plan.md`

## Completion Criteria (per task)

- [ ] Task definition read from approved `analysis_plan.md`
- [ ] No unresolved questions blocking the task
- [ ] Script written with header comment, project-relative paths, log file
- [ ] Script ran with exit code 0
- [ ] Log file exists
- [ ] Output file exists
- [ ] Key results visible in log
- [ ] Evidence row added to `analysis_plan.md`
- [ ] Task status: `cc:done`

## Escalation (task failure)

If a task fails after 3 attempts:

1. Write to `analysis_plan.md` under the task:
   - What error occurred (quoted from log)
   - What was tried
   - What is needed to resolve it
2. Mark task `cc:blocked`
3. Tell the user: the data or design may not support this task. They must decide whether to revise the plan.

Do not invent output, use estimated values, or continue as if the task completed.

## Handoff to Stage 6

After all approved tasks are complete:

> All requested tasks are done. Review `analysis_plan.md` to confirm all expected tasks are `cc:done`.
>
> When ready, run `/research-harness-review` to check identification, numerical accuracy, and causal claims before release.
