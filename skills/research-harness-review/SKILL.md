---
name: research-harness-review
description: "RES: Read-only review of research outputs. Checks identification, model spec, numerical accuracy, causal claims, reproducibility. Produces review_report.md with APPROVE/REQUEST_CHANGES/BLOCK verdict. Trigger: review research, check results, review analysis, verify outputs. Do NOT load for: cleaning, execution, release, setup, audit, planning."
description-en: "RES: Read-only review of research outputs. Checks identification, model spec, numerical accuracy, causal claims, reproducibility. Produces review_report.md with APPROVE/REQUEST_CHANGES/BLOCK verdict. Trigger: review research, check results, review analysis, verify outputs. Do NOT load for: cleaning, execution, release, setup, audit, planning."
kind: workflow
purpose: "Independent read-only review of research outputs before release"
trigger: "review research, check results, review analysis, verify outputs, /research-harness-review"
shape: evaluate
role: evaluator
pair: research-harness-work
owner: research-harness-core
since: "2026-05-29"
allowed-tools: ["Read", "Write", "Glob", "Grep"]
argument-hint: "[--quick] [--task TASK-ID]"
user-invocable: true
effort: high
---

# Research Harness Review

Perform an independent, read-only review of research outputs before release.

This skill reads existing scripts, logs, and outputs. It does not run code. It does not edit scripts or data. It produces a structured review report with a verdict.

This skill runs after `/research-harness-work` and before `/research-harness-release`.

## Quick Reference

| Input | Action |
|---|---|
| `/research-harness-review` | Full review of all `cc:done` tasks in `analysis_plan.md` |
| `/research-harness-review --quick` | Abbreviated review: identification + numerical accuracy only |
| `/research-harness-review --task 2.1` | Review a single task |

## Pre-flight Checks

1. Read `analysis_plan.md`. If it does not exist, stop.
2. Confirm at least one task has status `cc:done`. If none, report that no completed tasks exist to review.
3. List all `cc:done` tasks. These are the review scope.
4. Read `study_spec.md`, `reports/data_audit_report.md`, `reports/data_cleaning_report.md`, and `reports/merge_report.md` (if it exists).

## Procedure

This skill is read-only throughout. No Bash commands, no script execution, no file writes except the review report.

### Step 1 — Identification credibility review

Read `study_spec.md` §2 (identification strategy).

For each main model task in `analysis_plan.md`, check:

- Does the estimator used in the script match the identification strategy in the study spec?
- Is the key identification assumption stated in the script header or task description?
- Is any falsification or placebo test present in the plan?
- For DiD: is there a pre-trend check task?
- For IV: is the instrument defined and the exclusion restriction described?
- For RD: is bandwidth selection documented?

Assign one of: `strong` / `moderate` / `weak` / `insufficient`

**`insufficient` identification immediately produces REQUEST_CHANGES.** Do not write findings as minor if the identification is insufficient for the causal claim being made.

### Step 2 — Model specification alignment

For each `cc:done` analysis task:

- Read the script
- Compare the estimator, outcome variable, covariates, sample restrictions, and fixed effects to `study_spec.md` §4 and §5
- Flag any deviation as: `minor` (changes that do not affect the main result), `major` (changes that affect the result), or `critical` (changes that contradict the approved study design)

### Step 3 — Numerical accuracy check

For each `cc:done` task with an output file:

- Read the log file
- Read the output file (table or figure metadata)
- For each key number that would appear in a paper (main coefficient, standard error, sample size, p-value, mean): confirm it appears in the log
- If a number appears in the output file but not in the log: flag as `unverified`

An unverified number is a critical finding if it will appear in the final reported results.

Do not verify numbers by re-running scripts. Only read existing logs and outputs.

### Step 4 — Sample construction check

- Read the cleaning report row counts
- Read the log files for each analysis task
- Verify that the N reported in analysis logs matches the expected N given the cleaning report and sample restrictions
- Flag any discrepancy as: `minor` (small difference with a plausible explanation), `major` (large unexplained difference), or `critical` (N is clearly wrong)

### Step 5 — Causal claim assessment

Read any interim outputs, table notes, or text summaries (if present in `output/` or `reports/`).

For every causal claim found:
- Record the claim text and its location
- Check that it carries an identification strength tag (`[descriptive]`, `[correlational]`, `[quasi-experimental: ...]`, `[experimental]`)
- Assess whether the tag is appropriate given the design
- Flag claims that overstate causal strength as `major` findings

Do not rewrite weak evidence as strong causal evidence. If the evidence is correlational, the claim must be correlational.

### Step 6 — Data cleaning completeness check

- Confirm `reports/data_cleaning_report.md` exists and its verification section is PASS
- Confirm `reports/merge_report.md` exists (if merges were performed) and all entries have pre/post row counts
- Confirm `data/raw/` was not modified (if `git status data/raw/` or equivalent is available from prior logs, read it)
- Flag any incompleteness as a finding

### Step 7 — Hallucination and fabrication check

- Confirm no result is claimed without a corresponding log file
- Confirm no script produces a hardcoded numerical result (i.e., check that output values are computed, not assigned as literals)
- If any citations appear in output text: note that citation accuracy cannot be verified by this skill and flag for manual check

### Step 8 — Write review_report.md

Copy `templates/review_report.md` to `reports/review_report.md` and fill in all sections from Steps 1–7.

**Verdict rules:**

| Condition | Verdict |
|---|---|
| No critical or major findings | `APPROVE` |
| One or more major findings (but no critical) | `REQUEST_CHANGES` |
| One or more critical findings | `BLOCK` |
| Identification is `insufficient` for the causal claims made | `BLOCK` |
| Any result cannot be traced to a log | `BLOCK` |

`BLOCK` is a stronger form of `REQUEST_CHANGES`. It means the research cannot be released in any form until the finding is resolved.

### Step 9 — Report verdict

Print a review summary:

```
Research Harness Review — Complete

Tasks reviewed: N
Scope: [task IDs]

Identification credibility: strong / moderate / weak / insufficient
Numerical accuracy: all verified / N unverified
Causal claims: all appropriate / N overstated

Critical findings: N
Major findings: N
Minor findings: N

Verdict: APPROVE / REQUEST_CHANGES / BLOCK

Review report: reports/review_report.md
```

If verdict is `REQUEST_CHANGES` or `BLOCK`:

```
Required actions before /research-harness-release:
1. [Finding 1 — required action]
2. [Finding 2 — required action]

Return to /research-harness-work to re-execute affected tasks, then re-run /research-harness-review.
```

## Forbidden Actions

- Do not run any script or Bash command
- Do not edit any script, data file, log, or output file
- Do not approve a result that cannot be traced to a log file
- Do not rewrite weak causal evidence as strong causal evidence in the review report
- Do not produce `APPROVE` when any critical finding exists

## Evidence Requirements

- `reports/review_report.md` exists with all sections populated
- Verdict is one of: `APPROVE`, `REQUEST_CHANGES`, `BLOCK`
- All findings are documented with location and required action

## Completion Criteria

- [ ] All `cc:done` tasks reviewed
- [ ] Identification credibility assessed
- [ ] Model specification checked against study spec
- [ ] Numerical accuracy checked (each key number traced to a log)
- [ ] Sample N checked
- [ ] Causal claims assessed with identification tags
- [ ] Data cleaning completeness confirmed
- [ ] `reports/review_report.md` written
- [ ] Verdict printed

## Handoff to Stage 7

If verdict is `APPROVE`:

> Review passed. Run `/research-harness-release` to package the replication archive.

If verdict is `REQUEST_CHANGES` or `BLOCK`:

> Return to `/research-harness-work` to resolve the findings listed in `reports/review_report.md`.
> After re-executing affected tasks, run `/research-harness-review` again.
> Do not run `/research-harness-release` until the verdict is `APPROVE`.
