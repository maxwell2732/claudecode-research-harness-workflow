# Research Integrity Rules

This file is the canonical reference for all research safety and integrity rules enforced by the Research Agent Harness. It is referenced by `CLAUDE.md` and `AGENTS.md`.

---

## Rule 1 — Never modify raw data

All files under `data/raw/` are read-only. No script, agent, or tool may write, edit, rename, or delete files in `data/raw/`.

All data transformations produce new files in `data/processed/` or `data/intermediate/`. The original raw files must remain byte-identical throughout the project lifecycle.

**How to verify:** `git status data/raw/` must show no changes. The `protect-files.sh` hook enforces this at the tool level.

---

## Rule 2 — Never fabricate results

No agent may report, write, or include in any document a numerical result — coefficient, p-value, standard error, sample size, percentage, mean, or count — unless that number appears verbatim in a script log file that exists on disk.

This rule applies regardless of whether the number seems reasonable, is close to an expected value, or is described as a "placeholder" or "estimate."

**Consequence of violation:** Any result not traceable to a log is treated as fabricated and must be removed. The analysis task must be re-run.

---

## Rule 3 — Never claim an analysis ran without evidence

A task may not be marked `cc:done` and a result may not be reported unless:

1. A script file exists at the documented path.
2. A log file exists at the documented path.
3. An output file exists at the documented path (for table/figure tasks).

If any of these three conditions is not met, the task is `cc:wip` or `cc:blocked`, never `cc:done`.

---

## Rule 4 — Never silently drop observations

Every filter operation that removes observations must be:

- Documented in the cleaning plan (`templates/data_cleaning_plan.md`)
- Logged by the script (count before filter, count dropped, count after filter)
- Reported in the cleaning report (`templates/data_cleaning_report.md`)

Zero-observation drops are also documented (to confirm the filter had no unintended effect).

---

## Rule 5 — Always use project-relative paths

All scripts must use file paths relative to the project root. No absolute paths (e.g., `/Users/researcher/...`, `C:\Users\...`) may appear in any script.

Use language-appropriate helpers: `here::here()` in R, `pathlib.Path` in Python, relative `cd` at script top in Stata.

**Reason:** Absolute paths break reproducibility on any machine other than the one where the script was written.

---

## Rule 6 — Mark all causal claims with identification strength

Every causal claim in any output, table note, or report must carry one of these tags:

| Tag | Meaning |
|---|---|
| `[descriptive]` | Describes patterns in data; no causal inference claimed |
| `[correlational]` | Association after controlling for observables; confounding possible |
| `[quasi-experimental: DiD]` | Difference-in-differences with parallel trends assumption |
| `[quasi-experimental: IV]` | Instrumental variables with exclusion restriction assumption |
| `[quasi-experimental: RD]` | Regression discontinuity with continuity assumption |
| `[quasi-experimental: event study]` | Event study design; assumption stated |
| `[quasi-experimental: synthetic control]` | Synthetic control; donor pool described |
| `[experimental]` | Randomized controlled trial; randomization verified |

A claim marked `[experimental]` when the study is observational is a violation of this rule.

---

## Rule 7 — Stop at infeasibility; never invent a workaround

If the available data cannot support the proposed research design — insufficient sample size, missing key variable, unresolvable ID ambiguity, inadequate overlap for matching — the correct action is:

1. Document the infeasibility in `analysis_plan.md` under the relevant task.
2. Mark the task `cc:infeasible`.
3. Notify the human principal with a clear description of what is missing.

The correct action is **not** to substitute a different variable, fabricate a proxy, relax the design without disclosure, or proceed with results the researcher did not approve.

---

## Rule 8 — Every merge must produce a complete merge report

Every merge operation (joining two datasets) must produce a `merge_report.md` entry containing:

- Merge type (1:1, m:1, 1:m, m:m)
- Merge keys
- Left file row count (before merge)
- Right file row count (before merge)
- Post-merge row count
- Matched observation count
- Unmatched-left count
- Unmatched-right count
- Duplicate key diagnostics
- Variable conflicts and how they were resolved

A merge without this documentation is incomplete, regardless of whether the script ran successfully.

---

## Rule 9 — Stop if merge keys are ambiguous or missing

If the merge key variables are:

- Not clearly defined in the cleaning plan,
- Present in one file but not the other,
- Present in both files but with incompatible formats or values,
- Producing unexpected match rates (far below or above what the cleaning plan anticipated),

the correct action is to stop, document the problem in `analysis_plan.md`, and ask the human principal for clarification.

The correct action is **not** to guess, use a fallback key without disclosure, or proceed with a low-quality merge and report it as successful.

---

## Rule 10 — Preserve a complete evidence trail

Every table, figure, and numerical claim in any output must be traceable through:

```
Script file path → Log file path → Output file path
```

The `reproducibility_report.md` must contain this three-way trace for every key result.

If any link in the chain is missing, the corresponding result is unverified and must be labeled as such.

---

## Rule 11 — Keep code execution separate from narrative interpretation

Scripts produce outputs. Humans (and read-only review agents) interpret those outputs.

An analysis script must not:
- Write narrative conclusions into its log
- Describe its own results as "significant," "large," or "policy-relevant"
- Include language that pre-interprets results before the Reviewer has checked them

Interpretation belongs in reports and papers, written after `/research-harness-review` has run.
