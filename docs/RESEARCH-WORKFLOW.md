# Research Agent Harness — Workflow Narrative

This document explains the end-to-end research workflow enforced by the harness, the purpose of each stage, and the handoff contracts between stages.

---

## Why a Harness for Empirical Research?

AI-assisted research drifts without structure. Common failure modes:

- The analysis gets run with slightly different samples across sessions, producing inconsistent numbers.
- Coefficients in the text differ from the table because they were typed from memory rather than read from output.
- Causal language ("X causes Y") appears in descriptive analyses where the design cannot support it.
- Raw data gets modified by a cleaning script, making the original inputs unrecoverable.
- A merge silently drops 30% of observations because keys were mismatched, and no one notices until peer review.
- The paper cannot be reproduced because scripts used absolute paths or depended on intermediate files that were overwritten.

The Research Agent Harness enforces a structured loop that prevents each of these failure modes through source-of-truth files, human review gates, and mandatory evidence trails.

---

## Stage 1: `/research-harness-setup`

**Purpose:** Establish the research contract and the controlled folder structure before any data is touched.

**Inputs:** None (first command in a new project).

**Outputs:**
- `study_spec.md` — the research contract (research question, identification strategy, data, variables, sample restrictions, expected outputs)
- `analysis_plan.md` — empty task ledger
- Folder structure: `data/raw/`, `data/processed/`, `data/intermediate/`, `scripts/`, `analysis/`, `output/`, `logs/`, `reports/`
- Data protection rules documented

**Human gate:** The researcher reviews and approves `study_spec.md` before Stage 2 begins. Changes to the study spec after approval require a new explicit approval.

**Handoff to Stage 2:** `study_spec.md` is approved and committed.

---

## Stage 2: `/research-harness-audit`

**Purpose:** Understand the raw data before cleaning it. Identify problems before they propagate into the analysis.

**Constraint:** Read-only. No file in `data/raw/` is modified.

**Inputs:** Files in `data/raw/` as specified in `study_spec.md`.

**Outputs:**
- `reports/data_audit_report.md` — variable inventory, missingness, ID checks, unit problems, feasibility assessment
- `logs/audit_YYYYMMDD.log`

**Key checks:**
- Variable names, types, and missingness rates
- ID variable existence, uniqueness, and cross-file consistency
- Unit and coding problems (e.g., income in thousands vs. dollars, date formats)
- Outlier flags
- Sample restriction feasibility (can the restrictions in `study_spec.md` §5 be applied?)

**Infeasibility gate:** If the audit finds the data cannot support the proposed design, the analyst marks the audit report `infeasible`, explains why, and the researcher must revise `study_spec.md` before cleaning begins.

**Handoff to Stage 3:** Audit report is complete; feasibility is confirmed.

---

## Stage 3: `/research-harness-clean`

**Purpose:** Produce a reproducible, logged, analysis-ready dataset from raw inputs.

**Constraints:**
- Reads only from `data/raw/`
- Writes only to `data/processed/` or `data/intermediate/`
- Never modifies `data/raw/`

**Inputs:** Files in `data/raw/`; `reports/data_cleaning_plan.md` (filled in by the researcher before this stage).

**Outputs:**
- Cleaning scripts in `scripts/`
- `data/processed/analysis_ready.*` (or as specified)
- `logs/clean_YYYYMMDD.log`
- `reports/data_cleaning_report.md`
- `reports/merge_report.md` (one entry per merge operation)

**What the cleaning stage covers:**
Variable renaming, type conversion, date parsing, missing-value coding, duplicate checks, ID consistency, unit harmonization, winsorization/outlier flags (if explicitly requested), wide/long reshaping, wave appending, household/person/community file merging, treatment/policy timing file merging, derived variable generation, and production of the final analysis-ready dataset.

**Merge documentation requirement:** Every merge produces a `merge_report.md` entry with pre/post row counts, match rates, and duplicate diagnostics. A merge is not complete without this documentation.

**Handoff to Stage 4:** `data/processed/analysis_ready.*` exists; cleaning and merge reports are complete and verified.

---

## Stage 4: `/research-harness-plan`

**Purpose:** Translate the approved study spec and audit/cleaning findings into an executable analysis plan.

**Inputs:** `study_spec.md`, `reports/data_audit_report.md`, `reports/data_cleaning_report.md`, knowledge of the analysis-ready dataset structure.

**Outputs:**
- `analysis_plan.md` — populated with tasks, scripts, logs, outputs, DoD, and status markers

**Plan structure:** Descriptive analysis → Main models → Robustness checks → Heterogeneity analysis → Figures/tables.

**Human gate:** The researcher reviews and approves `analysis_plan.md` before Stage 5 begins.

**Handoff to Stage 5:** `analysis_plan.md` is approved.

---

## Stage 5: `/research-harness-work [task]`

**Purpose:** Execute the approved analysis tasks one at a time.

**Constraints:**
- Writes scripts to `analysis/<task>/scripts/` or `scripts/`
- Saves logs to `analysis/<task>/logs/` or `logs/`
- Saves outputs to `analysis/<task>/output/` or `output/`
- A task is `cc:done` only when script ran + log exists + output exists

**Inputs:** `analysis_plan.md` task definition; `data/processed/analysis_ready.*`.

**Outputs per task:**
- Script file
- Log file
- Output file (table or figure)
- Evidence row added to `analysis_plan.md`

**Escalation:** If a script fails three times, the task is marked `cc:infeasible` and the problem is documented. The researcher decides whether to revise the design.

**Handoff to Stage 6:** All `cc:done` tasks have script + log + output. The researcher triggers review.

---

## Stage 6: `/research-harness-review`

**Purpose:** Independent, read-only verification of identification credibility, numerical accuracy, model-spec alignment, and causal claim strength.

**Constraint:** Read-only. No scripts are run. The Reviewer reads existing logs and outputs only.

**Inputs:** `study_spec.md`, `analysis_plan.md`, all scripts, all logs, all outputs, `reports/data_cleaning_report.md`, `reports/merge_report.md`.

**Outputs:**
- `reports/review_report.md` — structured review with findings and verdict

**Review dimensions:**
1. Identification credibility
2. Model specification alignment with study spec
3. Numerical accuracy (every reported number traced to a log)
4. Data cleaning completeness
5. Causal claim strength
6. Hallucination and fabrication check (citations, sample sizes)

**Verdict:** `APPROVE` or `REQUEST_CHANGES`. Critical and major findings require `REQUEST_CHANGES`. Resolution returns to Stage 5 for the affected tasks.

**Handoff to Stage 7:** Review verdict is `APPROVE`.

---

## Stage 7: `/research-harness-release`

**Purpose:** Package the complete evidence archive for replication, submission, or handoff.

**Human gate:** The researcher must approve the release before packaging begins.

**Inputs:** All scripts, logs, outputs, cleaned data documentation, `reports/review_report.md` (verdict: APPROVE).

**Outputs:**
- `reports/reproducibility_report.md` — top-level evidence document with script list, log list, output list, verified claims, unverified items, and reproduction instructions
- Replication archive (folder or zip): all of the above

**Release is not complete until:**
- All items in the reproducibility report checklist are checked
- Every key numerical claim in the archive traces to a log
- Raw data access instructions are documented
- Reproduction instructions have been tested or explicitly marked as untested

---

## Evidence Chain

Every number in the final output must be traceable:

```
study_spec.md (design) →
analysis_plan.md (task) →
script file →
log file →
output file →
review_report.md (verified) →
reproducibility_report.md (archived)
```

If any link in this chain is broken, the result is unverified.
