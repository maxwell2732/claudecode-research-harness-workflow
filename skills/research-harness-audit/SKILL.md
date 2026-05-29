---
name: research-harness-audit
description: "RES: Read-only audit of raw data: variable inventory, missingness, IDs, units, merge keys, feasibility. Produces data_audit_report.md. Trigger: audit data, inspect data, data audit, check raw data. Do NOT load for: cleaning, analysis, review, release, setup."
description-en: "RES: Read-only audit of raw data: variable inventory, missingness, IDs, units, merge keys, feasibility. Produces data_audit_report.md. Trigger: audit data, inspect data, data audit, check raw data. Do NOT load for: cleaning, analysis, review, release, setup."
kind: workflow
purpose: "Perform a read-only audit of raw data files and produce a structured audit report"
trigger: "audit data, inspect data, data audit, check raw data, /research-harness-audit"
shape: evaluate
role: evaluator
pair: research-harness-clean
owner: research-harness-core
since: "2026-05-29"
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep"]
argument-hint: "[--file PATH] [--all]"
user-invocable: true
effort: medium
---

# Research Harness Audit

Perform a read-only audit of raw data files. No data file is modified. The only output is a structured audit report and a log.

This skill runs after `/research-harness-setup` and before `/research-harness-clean`.

## Quick Reference

| Input | Action |
|---|---|
| `/research-harness-audit` | Audit all files listed in `study_spec.md` §3 |
| `/research-harness-audit --file data/raw/X.csv` | Audit a specific file |
| `/research-harness-audit --all` | Audit everything found under `data/raw/` |

## Pre-flight Checks

Before starting:

1. Read `study_spec.md`. If it does not exist, stop and tell the user to run `/research-harness-setup` first.
2. Confirm the raw data path in `study_spec.md` §3 exists. If it does not, report the missing path and stop.
3. Write the audit log header to `logs/audit_YYYYMMDD.log`.

## Procedure

### Step 1 — File inventory

For each file under `data/raw/` (or the file specified by `--file`):

- Record: file name, file size, format (CSV, DTA, XLSX, parquet, etc.), encoding if detectable
- Record: row count (excluding header), column count
- Do not load entire files into memory if they are large — use shell commands (`wc -l`, `head`, column-sniffing) where possible

Log each file to `logs/audit_YYYYMMDD.log`.

### Step 2 — Variable inventory

For each file, record:

| Variable | Inferred type | Non-missing count | Missing count | Missing % | Min | Max | Sample values |
|---|---|---|---|---|---|---|---|

Use the actual variable names from the file headers. Do not rename or interpret variable names — record them as-is. If a variable name is ambiguous, note it in the audit report under §6 Open Issues; do not infer its meaning from the name alone.

### Step 3 — ID consistency check

For each file:

- Identify candidate ID variables (variables whose name suggests an identifier: e.g., `id`, `hhid`, `person_id`, `pid`, any variable ending in `_id` or `_code`)
- Check whether the candidate ID is unique within the file
- If multiple files share a candidate ID variable, check whether the ID values overlap

Do not assume that two variables with similar names are the same ID. Report the candidate match and leave it as `unknown` if not confirmed by the data dictionary.

### Step 4 — Time variable check

Identify candidate time variables (e.g., `year`, `wave`, `date`, `month`). For each:

- Record the range of values
- Record the format (numeric year, string date, etc.)
- Flag any irregularities (gaps in panel, mixed formats)

### Step 5 — Missingness patterns

- Identify any variable missing more than 50% of observations — flag as `high missingness`
- Identify any variables missing in a pattern correlated with other variables (e.g., income missing only for certain regions) — note but do not diagnose the mechanism
- Do not impute or infer missing values

### Step 6 — Duplicate check

For each file:

- Count fully duplicate rows
- Count rows with duplicate ID values (if ID was identified in Step 3)
- Report which ID variables have duplicates and how many

### Step 7 — Unit and coding check

- For numeric variables representing money, quantities, percentages, or geographic codes: note the apparent unit
- Flag any variables where values suggest a unit mismatch (e.g., income values of 500 mixed with 500000)
- Flag any variables with unusual coding (e.g., -9, 99, 9999 as apparent missing codes)
- Flag any date variables not in ISO 8601 format

### Step 8 — Merge key candidates

List pairs of files that appear to share a common ID variable. For each pair:

- Name the shared variable
- Report value overlap percentage
- Mark as `likely merge key`, `possible merge key`, or `unclear`

Do not perform any merge in this step.

### Step 9 — Feasibility assessment

Compare the raw data to `study_spec.md`:

- Can the outcome variable be constructed from the available variables?
- Can the treatment/exposure variable be constructed?
- Can the sample restrictions be applied?
- Is the expected sample size achievable?

Record each check as `feasible`, `partially feasible`, or `infeasible` with a one-line reason.

**Infeasibility gate:** If any required element is `infeasible`, the overall assessment is `infeasible`. Tell the user what is missing and that `study_spec.md` must be revised before cleaning can begin. Do not proceed to cleaning with an infeasible design.

### Step 10 — Write audit report

Copy `templates/data_audit_report.md` to `reports/data_audit_report.md` and fill in all sections from Steps 1–9.

Save `logs/audit_YYYYMMDD.log`.

## Forbidden Actions

- Do not modify any file under `data/raw/`
- Do not clean, reshape, or recode variables
- Do not run econometric models
- Do not infer the meaning of a variable from its name alone if the data dictionary does not confirm it
- Do not mark the audit as complete if required files are missing

## Evidence Requirements

- `reports/data_audit_report.md` exists and all sections are populated
- `logs/audit_YYYYMMDD.log` exists
- No files in `data/raw/` were modified (verify with `git status data/raw/` or file-size check)

## Completion Criteria

- [ ] All files in scope were inspected
- [ ] Variable inventory is complete
- [ ] ID consistency check is documented
- [ ] Missingness summary is present
- [ ] Feasibility assessment is present with explicit `feasible` / `infeasible` verdict
- [ ] `reports/data_audit_report.md` exists
- [ ] `logs/audit_YYYYMMDD.log` exists
- [ ] No raw data was modified

## Handoff to Stage 3

Tell the user:

> Audit complete. Review `reports/data_audit_report.md`.
>
> If the feasibility verdict is `infeasible`: revise `study_spec.md` before continuing.
>
> If `feasible` or `partially feasible`: fill in `templates/data_cleaning_plan.md`, save it as `reports/data_cleaning_plan.md`, review it, then run `/research-harness-clean`.
