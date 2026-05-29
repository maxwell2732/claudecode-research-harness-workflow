---
name: research-harness-clean
description: "RES: Generate and run reproducible data cleaning, harmonization, reshaping, and merging scripts. Preserves raw data. Produces cleaned datasets, cleaning report, and merge report. Trigger: clean data, merge data, process data, harmonize data. Do NOT load for: audit, analysis, review, release, setup."
description-en: "RES: Generate and run reproducible data cleaning, harmonization, reshaping, and merging scripts. Preserves raw data. Produces cleaned datasets, cleaning report, and merge report. Trigger: clean data, merge data, process data, harmonize data. Do NOT load for: audit, analysis, review, release, setup."
kind: workflow
purpose: "Generate and run reproducible data cleaning and merging scripts while preserving raw data integrity"
trigger: "clean data, merge data, process data, harmonize data, /research-harness-clean"
shape: workflow
role: executor
pair: research-harness-plan
owner: research-harness-core
since: "2026-05-29"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
argument-hint: "[--plan PATH] [--dry-run] [--task TASK-ID]"
user-invocable: true
effort: high
---

# Research Harness Clean

Generate and run reproducible data cleaning, harmonization, reshaping, and merging scripts.
Raw data is never modified. Every cleaning decision is documented in the cleaning report.

This skill runs after `/research-harness-audit` and before `/research-harness-plan`.

## Quick Reference

| Input | Action |
|---|---|
| `/research-harness-clean` | Run all cleaning tasks in `reports/data_cleaning_plan.md` |
| `/research-harness-clean --task 3` | Run only cleaning task 3 from the plan |
| `/research-harness-clean --dry-run` | Write scripts but do not execute them; report what would run |
| `/research-harness-clean --plan PATH` | Use a cleaning plan at a custom path |

## Pre-flight Checks

Before writing any script:

1. Read `reports/data_audit_report.md`. If it does not exist, stop — audit must run first.
2. Read `reports/data_cleaning_plan.md`. If it does not exist, stop. Tell the user to fill in `templates/data_cleaning_plan.md` and save it as `reports/data_cleaning_plan.md`.
3. Confirm all source files listed in the cleaning plan exist under `data/raw/`.
4. Confirm all target output paths are under `data/processed/` or `data/intermediate/`, not `data/raw/`.

If any pre-flight check fails: report which check failed and stop. Do not write scripts around the failure.

## Procedure

### Step 1 — Review the cleaning plan

Read `reports/data_cleaning_plan.md` in full.

Identify:
- All cleaning tasks (renaming, type conversion, date parsing, missing-value coding, duplicates, unit harmonization, reshaping, winsorization flags)
- All merge tasks (in execution order)
- All derived variable definitions
- All sample restriction filters
- The final analysis-ready dataset name and path

If any merge task has `unknown` merge keys or `unknown` expected match rate: stop before writing any merge script. Report the ambiguity and ask the user for clarification.

### Step 2 — Write the cleaning script

Write a single cleaning script (or one script per major task if the cleaning plan is large).

Script requirements:
- Language: R, Stata, or Python — use whichever the user specifies or whichever is appropriate given the data format. Default to R if unspecified.
- Header comment: project name, task ID, date, description, analyst name (Claude Code)
- Project-relative paths only (no absolute paths)
- Log all operations to a log file (open log at the start, close at the end)
- Every filter that drops observations: log the condition and the count before and after
- Exit with non-zero code on error

**R skeleton:**
```r
# Project: <study name>
# Task: data cleaning
# Date: YYYY-MM-DD
# Analyst: Claude Code

library(here)
library(dplyr)

log_file <- here("logs", "clean_YYYYMMDD.log")
sink(log_file, append = FALSE, split = TRUE)

cat("=== Data Cleaning Log ===\n")
cat("Started:", format(Sys.time()), "\n\n")

# --- Load ---
df <- read.csv(here("data", "raw", "filename.csv"))
cat("Loaded:", nrow(df), "rows\n")

# --- Filter ---
n_before <- nrow(df)
df <- df |> filter(...)
cat("Dropped:", n_before - nrow(df), "rows —", "reason\n")
cat("Remaining:", nrow(df), "rows\n")

# --- Save ---
write.csv(df, here("data", "processed", "analysis_ready.csv"), row.names = FALSE)
cat("\nFinished:", format(Sys.time()), "\n")
sink()
```

**Stata skeleton:**
```stata
* Project: <study name>
* Task: data cleaning
* Date: YYYY-MM-DD
* Analyst: Claude Code

log using "logs/clean_YYYYMMDD.log", replace text

use "data/raw/filename.dta", clear
display "Loaded: `c(N)' rows"

* Filter
count
keep if ...
display "Remaining after filter: `c(N)'"

save "data/processed/analysis_ready.dta", replace
log close
```

### Step 3 — Handle each cleaning task from the plan

Implement each task in the cleaning plan in order:

**Renaming:** rename variables exactly as specified in the plan. Do not rename variables not in the plan.

**Type conversion:** convert types as specified. Log any values that cannot be converted.

**Date parsing:** parse dates to ISO 8601 (YYYY-MM-DD). Log any unparseable dates.

**Missing-value coding:** recode non-standard missing codes to `NA` / `.`. Log the count of values recoded.

**Duplicate check:** identify and handle duplicates per the plan (drop first / drop last / flag / stop). Log duplicates found.

**ID consistency:** verify IDs are consistent per the plan. Log any inconsistencies.

**Unit harmonization:** apply conversion factors as specified. Do not guess conversion factors not in the plan.

**Winsorization / outlier flags:** apply only if explicitly specified in the plan. Log bounds and count of affected observations.

**Reshaping:** reshape as specified. Log the row count before and after.

**Derived variables:** generate each derived variable per the formula in the plan. Log the count of non-missing values produced.

### Step 4 — Handle each merge task

For each merge task in the cleaning plan, in execution order:

**Before merging:**
- Confirm merge keys exist in both files
- Count rows in each file
- Check for duplicate keys in each file
- Log pre-merge counts

**Merge:**
- Perform the merge using the specified keys and merge type
- Log post-merge row count
- Count and log matched, unmatched-left, unmatched-right

**After merging:**
- If match rate is far below the expected rate in the plan: stop, report the discrepancy, and ask the user whether to continue
- If variable conflicts exist (same variable name, different values): do not silently choose one. Report the conflict and stop unless the plan specifies a resolution
- Handle unmatched observations per the plan (keep / drop / flag)

**Write merge_report.md entry:**

For every merge, copy the `templates/merge_report.md` block and fill in all fields. Append to `reports/merge_report.md`.

If merge keys are ambiguous or missing from the plan: stop. Do not guess. Document the problem and ask for clarification.

### Step 5 — Run the script

Run the cleaning script. Capture the exit code.

- If exit code is 0: proceed
- If exit code is non-zero: read the log, identify the error, fix the script, and re-run (up to 2 retries)
- If the script fails after 3 attempts: stop. Write the error to the cleaning report under "Unresolved Issues." Mark the task `cc:blocked` in `analysis_plan.md`. Do not fabricate output.

### Step 6 — Verify output

After the script runs:

- Confirm the output file exists at the path specified in the plan
- Confirm the row count in the output matches the cleaning report
- Confirm `data/raw/` was not modified (check that file sizes match or use `git status data/raw/`)

### Step 7 — Write the cleaning report

Copy `templates/data_cleaning_report.md` to `reports/data_cleaning_report.md` and fill in all sections.

All of these must be present:
- Input file row counts
- Output file row count
- Every filter step with obs dropped
- Every rename, recode, and derived variable
- Merge summary (with reference to `reports/merge_report.md`)
- Verification checklist: all items checked PASS or documented as FAIL

## Forbidden Actions

- Do not write to or modify any file under `data/raw/`
- Do not silently drop observations — every filter must be logged with a count
- Do not guess merge keys — stop and ask if ambiguous
- Do not silently resolve variable conflicts across source files — report and stop
- Do not claim a cleaned dataset was created unless the script ran successfully (exit code 0) and a log exists
- Do not use absolute file paths in scripts
- Do not winsorize or flag outliers unless explicitly specified in the cleaning plan

## Evidence Requirements

- Cleaning script exists at documented path
- `logs/clean_YYYYMMDD.log` exists
- `data/processed/` output file exists
- `reports/data_cleaning_report.md` exists with all sections populated
- `reports/merge_report.md` exists with one entry per merge (if any merges occurred)
- No files in `data/raw/` were modified

## Completion Criteria

- [ ] Pre-flight checks passed
- [ ] Cleaning script wrote and ran without error
- [ ] Log file exists
- [ ] Output file exists with expected row count
- [ ] All observations dropped are documented with reason and count
- [ ] All merges have a `merge_report.md` entry with pre/post counts and match rates
- [ ] `reports/data_cleaning_report.md` verification section: PASS
- [ ] `data/raw/` unmodified

## Handoff to Stage 4

Tell the user:

> Cleaning complete. Review `reports/data_cleaning_report.md` and `reports/merge_report.md`.
>
> If any merge had unresolved problems: resolve them before continuing.
>
> When satisfied with the cleaned data, run `/research-harness-plan` to generate the executable analysis plan.
