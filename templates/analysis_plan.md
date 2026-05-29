# Analysis Plan

> This file is the task ledger. It tracks every analysis task, its definition of done, and the evidence paths.
> Generated during `/research-harness-plan`. Updated by `/research-harness-work` as tasks complete.
> Source of truth precedence: `study_spec.md` > `analysis_plan.md`.

---

## Project

- **Study spec path:** `study_spec.md`
- **Analysis plan version:** 1
- **Last updated:** YYYY-MM-DD
- **Analyst:** Claude Code

---

## Stage 1 — Descriptive Analysis

### Task 1.1: Summary statistics

- **Script:** `analysis/descriptive/scripts/table_descriptive.R`
- **Log:** `analysis/descriptive/logs/table_descriptive.log`
- **Output:** `output/tables/table1_descriptive.csv`
- **DoD:**
  - [ ] Script runs without error
  - [ ] Log file exists at the path above
  - [ ] Output file exists and matches log
  - [ ] Observation count matches `study_spec.md` sample restrictions
- **Assumptions:** Sample restrictions applied per `study_spec.md` §5
- **Unresolved questions:** none
- **Status:** `cc:todo`

### Task 1.2: [Add additional descriptive tasks]

- **Script:** unknown
- **Log:** unknown
- **Output:** unknown
- **DoD:**
  - [ ] Script runs without error
  - [ ] Log file exists
  - [ ] Output matches log
- **Status:** `cc:todo`

---

## Stage 2 — Main Models

### Task 2.1: Main regression / estimator

- **Script:** `analysis/main/scripts/main_regression.R`
- **Log:** `analysis/main/logs/main_regression.log`
- **Output:** `output/tables/table2_main.csv`
- **Identification:** Per `study_spec.md` §2
- **DoD:**
  - [ ] Script runs without error
  - [ ] Log file exists
  - [ ] All reported coefficients traceable to log
  - [ ] Identification assumption stated in script header
- **Status:** `cc:todo`

---

## Stage 3 — Robustness Checks

### Task 3.1: [Robustness check description]

- **Script:** unknown
- **Log:** unknown
- **Output:** unknown
- **DoD:**
  - [ ] Script runs without error
  - [ ] Log file exists
  - [ ] Results compared to main specification
- **Status:** `cc:todo`

---

## Stage 4 — Heterogeneity Analysis

### Task 4.1: [Subgroup or heterogeneity analysis]

- **Script:** unknown
- **Log:** unknown
- **Output:** unknown
- **DoD:**
  - [ ] Script runs without error
  - [ ] Log file exists
  - [ ] Subgroup definitions documented in script
- **Status:** `cc:todo`

---

## Stage 5 — Figures

### Task 5.1: [Figure description]

- **Script:** unknown
- **Log:** unknown
- **Output:** `output/figures/figure1.pdf`
- **DoD:**
  - [ ] Script runs without error
  - [ ] Log file exists
  - [ ] Figure renders without error
- **Status:** `cc:todo`

---

## Evidence Ledger

After each task completes, the Analyst adds a row here.

| Task | Script | Log | Output | Verified | Date |
|---|---|---|---|---|---|
| 1.1 | | | | | |

---

## Blocked and Infeasible Tasks

| Task | Reason | Date flagged |
|---|---|---|
| | | |
