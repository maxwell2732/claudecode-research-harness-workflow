---
name: research-harness-release
description: "RES: Build the replication/evidence package after a review APPROVE verdict. Assembles scripts, logs, cleaned-data docs, tables, figures, and reproducibility report. Requires human confirmation gate. Trigger: release research, build replication package, package evidence, finalize study. Do NOT load for: planning, execution, review, setup, audit, cleaning."
description-en: "RES: Build the replication/evidence package after a review APPROVE verdict. Assembles scripts, logs, cleaned-data docs, tables, figures, and reproducibility report. Requires human confirmation gate. Trigger: release research, build replication package, package evidence, finalize study. Do NOT load for: planning, execution, review, setup, audit, cleaning."
kind: workflow
purpose: "Assemble and verify the complete replication package after an APPROVE review verdict"
trigger: "release research, build replication package, package evidence, finalize study, /research-harness-release"
shape: workflow
role: orchestrator
pair: research-harness-review
owner: research-harness-core
since: "2026-05-29"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob"]
argument-hint: "[--dry-run] [--no-data]"
user-invocable: true
effort: medium
---

# Research Harness Release

Assemble the complete replication/evidence package after a successful review. This skill requires an `APPROVE` verdict from `/research-harness-review` before it will package any output.

A single human confirmation gate precedes all packaging operations.

This skill runs after `/research-harness-review` (verdict: APPROVE).

## Quick Reference

| Input | Action |
|---|---|
| `/research-harness-release` | Full replication package assembly |
| `/research-harness-release --dry-run` | List what would be included; do not copy or create the package |
| `/research-harness-release --no-data` | Package without processed data (for confidential data projects) |

## Pre-flight Checks

1. Read `reports/review_report.md`. If it does not exist, stop.
2. Check the verdict in `reports/review_report.md`. If it is not `APPROVE`, stop and tell the user: the review must pass before release can proceed.
3. Read `study_spec.md` and `analysis_plan.md`. If either does not exist, stop.
4. Confirm that all tasks marked `cc:done` in `analysis_plan.md` have a corresponding evidence row (script + log + output).

**If the review verdict is `REQUEST_CHANGES` or `BLOCK`: do not proceed. Tell the user to resolve review findings first.**

## Procedure

### Step 1 — Inventory all artifacts

Collect paths for every artifact that will go into the replication package:

**Source-of-truth files:**
- `study_spec.md`
- `analysis_plan.md`

**Reports:**
- `reports/data_audit_report.md`
- `reports/data_cleaning_plan.md` (if exists)
- `reports/data_cleaning_report.md`
- `reports/merge_report.md` (if merges occurred)
- `reports/review_report.md`

**Scripts:** all scripts referenced in `analysis_plan.md` Evidence Ledger

**Logs:** all logs referenced in `analysis_plan.md` Evidence Ledger

**Outputs:** all tables and figures referenced in `analysis_plan.md` Evidence Ledger

**Cleaned data:** `data/processed/` files referenced in the cleaning report (skip if `--no-data`)

**Templates used:** list only (do not copy templates themselves)

For each artifact, record whether the file exists on disk. Flag missing files as gaps.

### Step 2 — Human confirmation gate

Print the full artifact inventory:

```
Research Harness Release — Confirmation Required

Review verdict: APPROVE
Review report: reports/review_report.md

Artifacts to include:

  Source-of-truth:
    [x] study_spec.md
    [x] analysis_plan.md

  Reports:
    [x] reports/data_audit_report.md
    [x] reports/data_cleaning_report.md
    [x] reports/merge_report.md
    [x] reports/review_report.md

  Scripts (N files):
    [x] scripts/clean.R
    [x] analysis/main/scripts/main_regression.R
    ...

  Logs (N files):
    [x] logs/clean_YYYYMMDD.log
    [x] analysis/main/logs/main_regression.log
    ...

  Outputs (N files):
    [x] output/tables/table1.csv
    [x] output/tables/table2.csv
    [x] output/figures/figure1.pdf
    ...

  Cleaned data:
    [x] data/processed/analysis_ready.csv    [included / excluded with --no-data]

Gaps (files listed in analysis_plan.md but not found on disk):
  [list or "none"]

Data access note:
  [If --no-data: "Processed data excluded. Add access instructions to reproducibility_report.md."]
  [If data included: "Processed data included. Confirm you have permission to share this data."]

Proceed with release? (yes / no)
```

**Wait for user confirmation. Do not proceed without it.**

If the user says no: stop. Print: "Release cancelled. No files were packaged."

### Step 3 — Write reproducibility_report.md

Copy `templates/reproducibility_report.md` to `reports/reproducibility_report.md`.

Fill in all sections:

**§1 Software environment:** read from script headers (language and package versions mentioned in comments or `sessionInfo()` / `pip freeze` output in logs if present; otherwise write `unknown`)

**§2 Scripts:** list all scripts from the Evidence Ledger in execution order. Record file name and last-modified timestamp (SHA if git is available).

**§3 Data files:** list raw data files (with access instructions) and processed data files (with paths). If `--no-data`, note that processed data is not included and explain how to obtain raw data.

**§4 Logs:** list all logs from the Evidence Ledger with date run and exit code (read from log header).

**§5 Output files:** list all tables and figures from the Evidence Ledger.

**§6 Verified claims:** for each key numerical claim verified during review (from `reports/review_report.md` §3), list the claim, the reported value, and the log file where it appears.

**§7 Unverified items:** list any items from `reports/review_report.md` that were flagged as unverified or advisory, with risk level.

**§8 How to reproduce:** write step-by-step instructions. Steps must be specific (e.g., "Run `Rscript scripts/clean.R` from the project root") not generic.

**§9 Remaining limitations:** copy from `reports/review_report.md` minor findings and from `study_spec.md` §7 open questions.

**§10 Checklist:** fill in each item as checked or explain why it is not applicable.

### Step 4 — Create the release folder

Create `release/` at the project root (or the user-specified path).

Copy all artifacts from Step 1 into `release/` preserving the folder structure:

```
release/
├── study_spec.md
├── analysis_plan.md
├── reports/
│   ├── data_audit_report.md
│   ├── data_cleaning_report.md
│   ├── merge_report.md          (if applicable)
│   └── review_report.md
├── scripts/
│   └── clean.R
├── analysis/
│   └── <stage>/scripts/<task>.R
├── logs/
│   └── clean_YYYYMMDD.log
├── analysis/
│   └── <stage>/logs/<task>.log
├── output/
│   ├── tables/
│   └── figures/
├── data/processed/              (omit if --no-data)
└── reports/reproducibility_report.md
```

Do not include raw data under `data/raw/` unless the user explicitly instructs it (and it is not confidential).

### Step 5 — Final verification

After copying:

- Confirm every file in the inventory exists in `release/`
- Re-read the reproducibility report checklist — confirm all items are checked
- Count: total files in package, total verified claims, total unverified items

### Step 6 — Print release summary

```
Research Harness Release — Complete

Package location: release/
Total files: N
Verified claims: N
Unverified items: N (see reports/reproducibility_report.md §7)

⚠ Before sharing this package:
  - Confirm you have permission to share any data files included
  - Confirm data/raw/ contents are not in release/ (unless intended)
  - Test reproduction instructions on a clean environment if possible

Reproducibility report: release/reports/reproducibility_report.md
```

## Forbidden Actions

- Do not proceed if the review verdict is not `APPROVE`
- Do not proceed without human confirmation (Step 2)
- Do not include files from `data/raw/` unless the user explicitly approves
- Do not claim full reproducibility if data access restrictions prevent it — document them in §3 and §8
- Do not omit known limitations from the reproducibility report
- Do not fabricate software version numbers or timestamps not present in logs

## Evidence Requirements

- `reports/review_report.md` with verdict `APPROVE`
- `reports/reproducibility_report.md` with all sections filled in
- `release/` folder exists and contains all inventoried artifacts
- Release summary printed

## Completion Criteria

- [ ] Review verdict confirmed as `APPROVE`
- [ ] Human confirmation received
- [ ] Artifact inventory complete with no unexpected gaps
- [ ] `reports/reproducibility_report.md` written with all sections
- [ ] `release/` folder created and populated
- [ ] Reproducibility report checklist fully checked
- [ ] Release summary printed with file count and verified claims

## Post-Release

The release package is complete. Remaining researcher responsibilities (outside harness scope):

- Submit the package to a data repository (e.g., Harvard Dataverse, ICPSR, OSF)
- Add a README to the repository explaining how to obtain restricted data (if applicable)
- Archive the `release/` folder alongside the paper submission
