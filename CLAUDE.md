# CLAUDE.md — Claude Code Instructions for Research Agent Harness

Read `AGENTS.md` first for the full operating model and role boundaries.

This file contains Claude Code-specific rules for empirical research projects.

---

## 1. Work Scope

### What You Do

- Write R, Stata, or Python scripts based on the approved `analysis_plan.md`
- Save scripts to `scripts/` or `analysis/<task>/scripts/`
- Run scripts and save logs to `logs/` or `analysis/<task>/logs/`
- Save cleaned/processed data to `data/processed/` or `data/intermediate/`
- Save tables and figures to `output/` or `analysis/<task>/output/`
- Populate `analysis_plan.md` with evidence paths after each completed task
- Fill in report templates under `reports/`

### What You Must Not Do

- **Never write to `data/raw/`** — this is an absolute prohibition, no exceptions
- **Never invent or estimate numbers** — every coefficient, p-value, sample size, or percentage must come from an actual script run with a log
- **Never mark a task `cc:done`** without verifying a log file exists at the documented path
- **Never use absolute file paths** in scripts — always use paths relative to the project root
- **Never claim a merge is complete** without producing a `merge_report.md` entry with pre/post row counts
- **Never silently drop observations** — every filter must be logged with the reason and count

---

## 2. Script Standards

All scripts must:

- Begin with a header comment: project name, task ID, date, author (Claude Code)
- Use project-relative paths only (e.g., `data/raw/households.csv`, not `/Users/...`)
- Log all operations to a file (not just to stdout)
- Exit with a non-zero code on error so failures are visible in logs
- Be deterministic: same inputs → same outputs (set random seeds if needed)

### Language-specific conventions

**R:** Use `sink()` or `tee` for logs; `here::here()` for paths; `set.seed()` for randomness.

**Stata:** Use `log using`, `quietly`, and `assert` for verification; relative paths via `cd` at script top set once.

**Python:** Use `logging` module to file; `pathlib.Path` for paths; `random.seed()` / `numpy.random.seed()` for reproducibility.

---

## 3. Commit Convention

```
audit:   data audit report for <dataset>
clean:   cleaning script for <task> — N obs in, M obs out
plan:    analysis plan for <study>
analysis: <task-id> <description> — script ran, log saved
review:  review report — APPROVE / REQUEST_CHANGES
release: replication package v<version>
```

---

## 4. Escalation Rules

If a script fails, follow this path:

1. Read the log. Identify the error.
2. Fix the script. Re-run. Save new log.
3. If it fails a second time: check whether the raw data supports the operation. Document what is missing.
4. If it fails a third time: **stop**. Write an infeasibility note in `analysis_plan.md` under the task. Mark the task `cc:infeasible`. Do not invent output or work around a data limitation silently.

**Never** present fabricated or estimated output as if a script produced it.

---

## 5. Data Cleaning Rules

When running `/research-harness-clean`:

- Read source files only from `data/raw/`
- Write output only to `data/processed/` or `data/intermediate/`
- Every dropped observation: log the filter condition and the count dropped
- Every merge: fill in `merge_report.md` — keys, left count, right count, post-merge count, unmatched counts
- If merge keys are ambiguous or missing: stop, document the problem, and ask the user for clarification
- If two source files contain overlapping variables with different values: report the conflict, do not silently choose one

---

## 6. Data Protection and Version Control

The following directories contain survey microdata or derived individual-level data and are subject to data protection requirements. They **must never be committed to git or pushed to any remote repository (including GitHub)**:

| Directory | Reason |
|-----------|--------|
| `input/data/` | Raw CHNS survey microdata — licensed, individual-level |
| `data/raw/` | Raw data mirror — same protection as above |
| `data/intermediate/` | Derived individual-level datasets during processing |
| `data/processed/` | Final merged panel and codebook — individual-level |
| `logs/` | May contain row counts and identifiers from data runs |

These paths are listed in `.gitignore`. Do not remove them from `.gitignore` under any circumstance.

**Enforcement rules for Claude Code:**

- **Never `git add`** any file under the above directories, even if explicitly asked
- **Never commit** `chns_merged_panel.csv`, `chns_codebook.csv`, or any `.parquet` file
- **Never push** data files to any remote; if a user asks, explain the data protection requirement and refuse
- Before any `git add .` or `git add -A`, verify no data files are staged
- Replication packages (for sharing) include **scripts and reports only** — never the data itself

---

## 7. Research Integrity Rules

Full canonical list: [`docs/INTEGRITY-RULES.md`](docs/INTEGRITY-RULES.md)

Short reference:

1. Never modify `data/raw/`
2. Never fabricate results, citations, sample sizes, coefficients, p-values, or robustness checks
3. Never claim an analysis ran without a corresponding script and log on disk
4. Never silently drop observations
5. Always use project-relative paths
6. Mark all causal claims with identification strength: `[descriptive]` / `[correlational]` / `[quasi-experimental: DiD/IV/RD]` / `[experimental]`
7. If data are insufficient, stop and report infeasibility — never invent a workaround
8. Every merge must report pre/post row counts, match rates, and duplicate diagnostics
9. If merge keys are ambiguous or missing, stop and ask — never guess
10. Preserve an evidence trail for every table, figure, and number: script path + log path + output path
11. Keep code execution separate from narrative interpretation
