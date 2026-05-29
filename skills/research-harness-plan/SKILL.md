---
name: research-harness-plan
description: "RES: Generate an executable empirical analysis plan from study_spec.md, audit report, and cleaned data structure. Produces analysis_plan.md. Trigger: create analysis plan, plan analysis, generate analysis plan. Do NOT load for: cleaning, execution, review, release, setup."
description-en: "RES: Generate an executable empirical analysis plan from study_spec.md, audit report, and cleaned data structure. Produces analysis_plan.md. Trigger: create analysis plan, plan analysis, generate analysis plan. Do NOT load for: cleaning, execution, review, release, setup."
kind: workflow
purpose: "Generate an executable, evidence-backed analysis plan from the approved study specification"
trigger: "create analysis plan, plan analysis, generate analysis plan, /research-harness-plan"
shape: workflow
role: generator
pair: research-harness-work
owner: research-harness-core
since: "2026-05-29"
allowed-tools: ["Read", "Write", "Edit", "Glob"]
argument-hint: "[--update] [--add STAGE]"
user-invocable: true
effort: medium
---

# Research Harness Plan

Generate an executable empirical analysis plan based on the approved study specification, audit findings, and cleaned data structure.

This skill runs after `/research-harness-clean` and before `/research-harness-work`. The output — `analysis_plan.md` — requires human approval before any analysis script is run.

## Quick Reference

| Input | Action |
|---|---|
| `/research-harness-plan` | Generate a fresh `analysis_plan.md` from `study_spec.md` + reports |
| `/research-harness-plan --update` | Update an existing `analysis_plan.md` with new tasks or revised scope |
| `/research-harness-plan --add robustness` | Add a robustness-check stage to an existing plan |

## Pre-flight Checks

Before writing any plan content:

1. Read `study_spec.md`. If it does not exist or is substantially empty, stop and tell the user to run `/research-harness-setup` first.
2. Read `reports/data_audit_report.md`. If it does not exist, stop and tell the user to run `/research-harness-audit` first.
3. Read `reports/data_cleaning_report.md`. If it does not exist, stop and tell the user to run `/research-harness-clean` first.
4. Identify the analysis-ready dataset path from the cleaning report.
5. Check that the analysis-ready dataset file exists.

If any check fails: report which check failed and stop. Do not generate a plan for data that does not exist.

## Procedure

### Step 1 — Synthesize inputs

Read and synthesize:
- `study_spec.md`: research question, identification strategy, outcome, treatment, covariates, sample restrictions, expected outputs
- `reports/data_audit_report.md`: available variables, sample sizes, ID structure, missingness, feasibility assessment
- `reports/data_cleaning_report.md`: final row count, variable names in the analysis-ready dataset, any unresolved issues

Identify:
- Which variables in the study spec are confirmed to exist in the cleaned data
- Which variables in the study spec are missing or ambiguous — list them as `unknown` in the plan
- Whether the feasibility verdict from the audit is `feasible` or `partially feasible`

Do not propose analysis tasks that depend on variables not found in the cleaned data. If a key variable is missing, note the task as `cc:blocked` with the reason.

### Step 2 — Draft the analysis plan structure

The plan must follow this stage structure:

1. **Descriptive analysis** — summary statistics, variable distributions, pre-treatment trends (for DiD), balance tables (for experimental)
2. **Main models** — the primary estimator as specified in `study_spec.md` §2
3. **Robustness checks** — alternative specifications, samples, or estimators that test the main result
4. **Heterogeneity analysis** — subgroup analyses, if specified in the study spec or motivated by the data
5. **Figures and tables** — all outputs required by `study_spec.md` §6

For each task, specify:
- Task ID (e.g., `1.1`, `2.1`, `3.1`)
- Task description
- Script path (`analysis/<stage>/scripts/<task>.R`)
- Log path (`analysis/<stage>/logs/<task>.log`)
- Output path (`output/tables/<task>.csv` or `output/figures/<task>.pdf`)
- Definition of done (DoD): script ran + log exists + output matches log + specific acceptance criteria
- Key assumptions this task relies on
- Unresolved questions that must be answered before this task can be marked done
- Status: `cc:todo`

### Step 3 — Apply identification constraints

For every task in the main models and robustness stage:

- Copy the identification strategy from `study_spec.md` §2 into the task description
- Label every task with the identification strength tag: `[descriptive]`, `[correlational]`, `[quasi-experimental: ...]`, or `[experimental]`
- Do not label an observational study task as `[experimental]`
- Do not propose an IV specification unless an instrument is defined in `study_spec.md`
- Do not propose a DiD specification unless panel data is confirmed in the audit report

### Step 4 — Flag limitations and unresolved questions

At the end of the plan, include a section:

**Limitations:**
- List any analysis tasks that could not be proposed because required variables are missing
- List any identification threats noted in the audit report
- List any data quality issues from the cleaning report that affect the analysis

**Unresolved questions:**
- List any decisions that the researcher must make before the corresponding task can run (e.g., choice of bandwidth for RD, choice of control group for DiD)

Do not invent answers to unresolved questions. Leave them as `unknown` and mark the dependent tasks `cc:blocked`.

### Step 5 — Write analysis_plan.md

Write the complete `analysis_plan.md` to the project root using `templates/analysis_plan.md` as the structure.

If `analysis_plan.md` already exists and `--update` was not passed: ask the user whether to overwrite or append. Do not silently overwrite an existing plan.

### Step 6 — Confirm and request approval

Print a plan summary:

```
Research Harness Plan — Draft Complete

Tasks generated:
  Stage 1 (Descriptive):    N tasks
  Stage 2 (Main models):    N tasks
  Stage 3 (Robustness):     N tasks
  Stage 4 (Heterogeneity):  N tasks
  Stage 5 (Figures/tables): N tasks
  Blocked (missing data):   N tasks

Limitations: [count]
Unresolved questions: [count]

⚠ HUMAN APPROVAL REQUIRED before running /research-harness-work.
Review analysis_plan.md and confirm the plan is correct before proceeding.
```

## Forbidden Actions

- Do not propose analysis tasks that depend on variables not present in the cleaned data
- Do not overstate the identification strategy (e.g., do not call a DiD design "causal" without noting the parallel trends assumption)
- Do not invent variables, instruments, or control groups not specified in `study_spec.md`
- Do not run any analysis scripts in this step
- Do not mark any task `cc:done` — all tasks start as `cc:todo` or `cc:blocked`
- Do not silently overwrite an existing `analysis_plan.md`

## Evidence Requirements

- `analysis_plan.md` exists at the project root
- All tasks have script, log, and output paths specified
- All tasks have a DoD with at least: script ran + log exists + output exists
- All tasks have an identification strength label
- Limitations and unresolved questions sections are present

## Completion Criteria

- [ ] Pre-flight checks passed
- [ ] All inputs read and synthesized
- [ ] `analysis_plan.md` written with all stages
- [ ] Every task has a script path, log path, output path, DoD, and identification label
- [ ] Limitations and unresolved questions documented
- [ ] Plan summary printed and human approval requested

## Handoff to Stage 5

Tell the user:

> Review `analysis_plan.md`. When you are satisfied with the plan, approve it.
>
> Then run `/research-harness-work 1.1` (or the task number you want to execute first).
>
> Do not run `/research-harness-work` until you have reviewed and approved the plan.
