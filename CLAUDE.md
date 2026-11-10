# CLAUDE.md — Claude Code Instructions for Research Agent Harness

This file defines the operating model and Claude Code rules for empirical research projects. Read it before starting any research task.

---

## 0. Operating Model

### Roles

Two roles share every project:

| Role | Agent | Responsibilities |
|---|---|---|
| **Analyst** | Claude Code | Writes scripts, runs scripts, saves outputs and logs, documents every transformation |
| **Reviewer** | Human + Claude (read-only) | Checks identification, numerical accuracy, model-spec alignment, causal claim strength |

The Analyst executes. The Reviewer judges. They do not switch roles mid-task.

### Workflow

```
Human (Principal)          Analyst (Claude Code)        Reviewer (Claude, read-only)
       |                           |                              |
       | 1. Approve study_spec.md  |                              |
       |-------------------------->|                              |
       |                           | 2. /research-harness-audit   |
       |                           |    (read-only, saves report)  |
       |                           |                              |
       |                           | 3. /research-harness-clean   |
       |                           |    (scripts + logs + reports) |
       |                           |                              |
       |                           | 4. /research-harness-plan    |
       |                           |    (analysis_plan.md)         |
       | 5. Approve analysis_plan  |                              |
       |<--------------------------|                              |
       |-------------------------->|                              |
       |                           | 6. /research-harness-work    |
       |                           |    (scripts + logs + outputs) |
       |                           |                              |
       |                           |----------------------------->|
       |                           | 7. /research-harness-review  |
       |                           |    (APPROVE or REQUEST_CHANGES)|
       |                           |<-----------------------------|
       |                           |                              |
       | 8. Approve release        |                              |
       |<--------------------------|                              |
       |-------------------------->|                              |
       |                           | 9. /research-harness-release |
       |                           |    (replication package)      |
```

### File Map

| File / Folder | Who owns it | Notes |
|---|---|---|
| `study_spec.md` | Human (with Analyst draft) | Research contract: changes require human approval |
| `analysis_plan.md` | Analyst (human approves) | Task ledger with status markers and evidence paths |
| `data/raw/` | **Read-only** | No script or agent may write here under any circumstance |
| `data/intermediate/` | Analyst | Work-in-progress datasets during cleaning |
| `data/processed/` | Analyst | Final analysis-ready datasets |
| `scripts/` | Analyst | Cleaning and analysis scripts |
| `analysis/<task>/` | Analyst | Per-task scripts, outputs, logs |
| `output/` | Analyst | Tables and figures |
| `logs/` | Analyst | Script run logs: must exist before any task is marked done |
| `reports/` | Analyst | Audit, cleaning, review, and reproducibility reports |

### Prohibited Actions (Analyst)

The following actions are **never permitted**, regardless of instruction:

1. Write, edit, or delete any file under `data/raw/`
2. Report a numerical result (coefficient, p-value, sample size, percentage) that is not present in a log file
3. Mark a task `cc:done` without verifying that a log file exists on disk
4. Drop observations without documenting the reason and the observation count
5. Perform a merge without recording merge keys, pre-merge counts, post-merge counts, and match rates
6. Guess merge keys when they are ambiguous: stop and ask
7. Use absolute file paths in scripts
8. Claim a causal effect without stating the identification strategy and its strength

### Prohibited Actions (Reviewer)

1. Write or edit any script, data file, or output file
2. Run code: the Reviewer reads existing logs and outputs only
3. Approve a result that cannot be traced to a script and a log file

### Status Markers (in `analysis_plan.md`)

| Marker | Meaning |
|---|---|
| `cc:todo` | Not started |
| `cc:wip` | In progress |
| `cc:done` | Complete: script ran, log exists, output verified |
| `cc:blocked` | Cannot proceed: reason documented |
| `cc:infeasible` | Data or design cannot support this task: stop condition |

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

## 6. Task Completion Report（任务完成报告）

**每次任务完成后，必须生成一份中文报告**，保存到 `reports/` 目录，文件名格式为 `report_<task-slug>_<YYYYMMDD>.md`。

报告必须包含以下章节：

| 章节 | 内容 |
|------|------|
| **任务背景** | 任务目标、触发原因、数据或问题描述 |
| **执行过程** | 按步骤列出做了什么，包括脚本名、输入输出、关键参数 |
| **关键结果** | 数量统计（行数、列数、匹配率等）均须来自日志，不得估算 |
| **数据质量说明** | 跳过/合并的文件、缺失率、已知问题 |
| **输出文件清单** | 每个输出文件的路径、行数、列数（来自日志） |
| **证据链** | 每个关键数字对应的脚本路径 → 日志路径 |
| **待办/遗留问题** | 本次未解决或需下一步跟进的事项 |

**报告规则：**
- 全文中文
- 所有数字必须可追溯到日志文件，不得凭记忆填写
- 报告本身不包含任何数据内容（无行内数据、无样本记录）
- 报告完成后提交到 git（`git add reports/report_*.md`）

---

## 7. Data Protection and Version Control

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

## 8. Research Integrity Rules

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

---

## 9. Survey Microdata Pipeline — Engineering Rules

Lessons distilled from CHNS (2026-05-29) and CHARLS (2026-06-02) pipeline runs. Apply these rules to any new survey dataset pipeline.

### 9.1 Codebook Requirements

**Every codebook CSV must include a `description` column** populated from the source data's native variable labels.

- For Stata `.dta` files: read labels via `pyreadstat` metadata — `meta.column_labels` (list aligned with `meta.column_names`)
- Write a dedicated enrichment script (e.g., `*_08_enrich_codebook.py`) that scans all raw `.dta` files with `metadataonly=True` and back-fills descriptions into the codebook after export
- Pipeline-derived columns (e.g., `WAVE`, `N_CHILDREN_W2013`, `EXIT_INTERVIEWED_W2020`) have no Stata label; add manual descriptions in the enrichment script
- Target coverage ≥ 99%; log how many variables received descriptions and how many remain empty
- Column order in codebook: `variable_name`, `description`, then statistics columns

### 9.2 Memory Management for Wide DataFrames

CHARLS-style survey data routinely produces panels with 10,000–25,000 columns after cross-wave stacking. These rules prevent OOM failures:

1. **Indicator join must use key columns only.** In `do_merge`, the intermediate join used to count matched/unmatched rows must operate on `left[keys]`, never on the full left panel:
   ```python
   # WRONG — copies entire 20k-col panel:
   ind = left.merge(right[keys], on=keys, how="left", indicator=True)
   # CORRECT — copies only key columns:
   ind = left[keys].merge(right[keys].drop_duplicates(), on=keys, how="left", indicator=True)
   ```

2. **Supplement scripts must load key columns only.** Any script that merges auxiliary modules into an already-wide panel should:
   - Load only `[ID, WAVE, HOUSEHOLDID, COMMUNITYID]` from the wide parquet (not all 19k+ cols)
   - Merge supplements against this slim key frame → save as a separate `*_supplement.parquet`
   - Let the export script do the final column-join

3. **Parquet intermediate files are preferred** over CSV for intermediate stages (faster I/O, preserves dtypes). Use `df.to_parquet()` with `write_parquet()` wrapper that calls `clean_dtypes()` first.

4. **CSV export for very wide panels** should be done in row chunks (`pd.read_csv(..., chunksize=N)` or `pq.ParquetFile.iter_batches(batch_size=N)`) to avoid loading the full panel into RAM.

### 9.3 Mixed-Type Column Handling (Stata Cross-Wave Stacking)

When stacking `.dta` files from multiple waves with `pd.concat`, object-dtype columns can contain mixed Python types (e.g., `str` from one wave, `float` from another). This causes `ArrowTypeError` when writing to parquet. Always call `clean_dtypes(df)` before `df.to_parquet()`.

The `clean_dtypes` function must:
- Decode `bytes` → `str` (pyreadstat can return bytes for some Stata string variables)
- For object columns with mixed `str + numeric`: check if ALL string values are empty (Stata missing sentinel `""`); if so, coerce the entire column to numeric via `pd.to_numeric`
- For mixed str + numeric where strings have content: convert all values to `str`
- Use head+tail sampling (e.g., 200 rows each) for type detection, NOT a full-column `.apply(type)` scan — the full scan is O(n × cols) and takes tens of minutes on wide DataFrames

### 9.4 Merge Duplicate Column Prevention

When merging modules into a growing panel with `suffixes=("", "_right")`, columns like `HOUSEHOLDID` and `COMMUNITYID` that exist in both left and right will generate `HOUSEHOLDID_right` in every merge, accumulating duplicates.

**Rule:** In the pre-merge drop step, drop ALL non-key columns that already exist in the panel — including `HOUSEHOLDID` and `COMMUNITYID`. Do not exempt them:

```python
# WRONG — HOUSEHOLDID/COMMUNITYID exempted, causing _right chains:
drop = [c for c in module.columns if c in existing and c not in keys + ["HOUSEHOLDID", "COMMUNITYID"]]

# CORRECT — drop everything already in panel except merge keys:
drop = [c for c in module.columns if c in existing and c not in keys]
```

As a safety net, `write_parquet()` should also deduplicate column names before writing:
```python
df = df.loc[:, ~df.columns.duplicated()]
```

### 9.5 Cross-Wave File Naming Differences

Survey waves often differ in file naming conventions. Always use a case-insensitive file finder (`find_file()` helper) rather than hardcoded names:

- CHARLS 2011: all filenames **lowercase** (`demographic_background.dta`)
- CHARLS 2013+: **CamelCase** (`Demographic_Background.dta`)
- Module availability varies by wave (e.g., no `Health_Care_and_Insurance.dta` in 2020)
- Variable availability within same-named modules varies by wave

Encode wave→filename mappings explicitly in the script (a dict per module) rather than relying on glob patterns.

### 9.6 Python Environment Notes

- CHARLS pipeline uses: `C:\Users\zhuch\.conda\envs\gnn\python.exe` (Python 3.10)
- CHNS pipeline used: `C:\Users\zhuch\.conda\envs\snipar_env\python.exe` (Python 3.9, currently broken)
- Required packages: `pandas`, `pyreadstat`, `pyarrow`
- Install via: `gnn_python -m pip install pyreadstat pyarrow pandas --only-binary :all:`
- Python 3.9 note: avoid `X | Y` type unions and `list[str]` annotations; use `Optional[X]` and `List[str]` from `typing`

---

## 10. Paper Replication — Subsample Extraction

This repo supports extracting analysis-ready subsamples from raw survey panels to replicate published papers. The pattern was established with the CHARLS LTCI replication (Zhang et al. 2026, 2026-06-03).

### 10.1 Three-Script Pipeline

Every paper replication subsample follows three scripts, numbered `<dataset>_10/11/12` (or higher to avoid collision with the main pipeline):

| Script | Role | Output |
|--------|------|--------|
| `*_10_discover_vars.py` | Read `.dta` metadata with `metadataonly=True` across all relevant waves and modules; log all variable names + Stata labels; flag variables matching paper keywords | `data/processed/*_10_var_list.csv` |
| `*_11_<paper>_subsample.py` | Load only the needed columns per wave, apply the paper's sample filter, construct all outcome/treatment/control variables, save the analysis-ready dataset | `data/processed/*_subsample.parquet` + `.csv` |
| `*_12_<paper>_codebook.py` | Read the subsample parquet, compute per-variable statistics, attach paper-level definitions and target means, flag mismatches | `data/processed/*_codebook.csv` |

**All three outputs go to `data/processed/`** — never `data/intermediate/` for files the researcher will use directly.

### 10.2 Variable Discovery Protocol

Before writing `charls_11`, always run `charls_10` first to confirm actual variable names for each concept. Do not assume variable names from paper descriptions alone — names differ across waves and dataset versions.

The discovery script must:
- Use `pyreadstat.read_dta(path, metadataonly=True)` — never load full data for discovery
- Scan 8–10 modules × 3+ waves in a single run
- Log every variable whose name OR label matches the keyword list
- Export a CSV with columns `[wave, module, file, var_name, label, flagged]`

### 10.3 Wave-Specific Variable Routing (CHARLS Lessons)

CHARLS variable names and encoding change across waves. Hard-won rules from the LTCI replication:

**Naming conventions:**
- CHARLS 2011: all module filenames **lowercase** (`family_transfer.dta`)
- CHARLS 2013+: **CamelCase** (`Family_Transfer.dta`)
- CHARLS 2018: some modules renamed (`Work_Retirement.dta`, not `Work_Retirement_and_Pension.dta`)
- Always use `find_file(wave_dir, *candidates)` — never hardcode a single filename

**Demographic variable priority per wave:**

| Variable | 2011 | 2013 | 2018 |
|----------|------|------|------|
| Birth year | `BA002_1` | `ZBA002_1` (preloaded) then `BA002_1` | `BA004_W3_1` (full coverage) |
| Gender | `RGENDER` | Not in demo file — fill from 2011 baseline | `XRGENDER` |
| Hukou | `BC001` | `ZBC001` (preloaded) | Not in demo file — fill from baseline |
| Marital | `BE001` | `BE001` | `BE001` |
| Education | `BD001` | `ZBD001` (preloaded; `BD001` = update only, sparse) | `BD001_W2_4` |

**ID format differs across waves** (2011 = 11 chars, 2013+ = 12 chars). Cross-wave baseline filling by ID fails without an official crosswalk file. Document this limitation; do not silently assume the fill succeeded.

**When a variable is "preloaded" (Z-prefix in 2013):** use it when the direct variable is sparse (update-only). Always coalesce: `series.fillna(other_series)`.

### 10.4 CHARLS-Specific Variable Encoding Gotchas

These encoding rules were validated against paper Table 2 descriptive statistics and must be applied to any future CHARLS replication:

**Education (BD001):**
- Value 4 = primary school **graduate** (小学毕业) — this is "primary or less"
- Value 5 = middle school (初中毕业) — this is where "middle school and above" starts
- Correct threshold: `BD001 >= 5` (NOT `>= 4`)

**Health insurance (EA001S / EA001_W4_S):**
- 2011/2013: multi-select, each variable is **NULL when not selected**, value = type number when selected. Detection: `.notna().any()`
- 2018: multi-select, but each variable is **0 when not selected**, non-zero when selected. Detection: `(df[ins_cols] != 0).any(axis=1)`
- "No insurance" sentinel: `EA001S10` (2011/2013) / `EA001_W4_S12` (2018) — non-null/non-zero → uninsured

**Marital status (BE001):**
- Value 1 = married, living together
- Value 2 = married, living apart (temporary separation)
- Paper's "Married = 0, Others = 1": use `BE001 > 2` (values 1 AND 2 are "married")

**Non-agricultural employment (CHARLS 2011/2013):**
- FA001=1 respondents (agricultural workers) are routed **away from FA002** — they never answer it
- FC014 captures whether agricultural-primary workers also held non-agri jobs
- Correct construction: `FA002==1 OR FC014==1 OR FA003==1 OR FC015==1`
- Do NOT use FA002 alone; it misses the agri+non-agri group entirely

**Agricultural employment:**
- Use `FC001` ("worked for OTHER farmers/employers for wage"), NOT `FA001` ("any agricultural work ≥10 days" — includes own-farm)

**City identification for LTCI pilots:**
- PSU.dta (2011/2013) contains a `CITY` string field with city name in Chinese
- Use partial string matching against the 12 pilot city names
- 2018 has no PSU file; use `Sample_Infor.dta` + community ID mapping from 2011/2013 PSU

### 10.5 Codebook Validation Against Paper

The `*_12_codebook.py` script must include a `mean_match` column comparing our constructed variable means against the paper's Table 2 (or equivalent descriptive statistics table). Thresholds:

| Match label | Criterion |
|-------------|-----------|
| `CLOSE` | `|our_mean − paper_mean| < 0.02` |
| `MODERATE` | `0.02 ≤ diff < 0.10` |
| `DIFFERS` | `diff ≥ 0.10` |

Any variable marked `DIFFERS` must have a documented explanation in the codebook `notes` column before the subsample is considered ready for regression.

### 10.6 CHARLS LTCI Replication — Reference Numbers

Baseline established 2026-06-03. Scripts: `charls_10/11/12_*`. Target paper: Zhang et al. (2026).

| Variable | Achieved | Paper | Status |
|----------|----------|-------|--------|
| Sample N | 4,665 | 4,626 | ✓ |
| Treat=1 | 358 | 357 | ✓ |
| MARITAL | 0.075 | 0.074 | CLOSE |
| EDUCATION | 0.530 | 0.534 | CLOSE |
| HEALTH_INSURED | 0.960 | 0.965 | CLOSE |
| HUKOU | 0.303 | 0.290 | CLOSE |
| AGRI_EMPLOY | 0.057 | 0.075 | CLOSE |
| NON_AGRI_EMPLOY | 0.401 | 0.462 | MODERATE |
| GENDER | 0.473 | 0.450 | MODERATE |

Remaining gap for `NON_AGRI_EMPLOY` (6.1 pp): attributable to questionnaire routing in 2011/2013 — some self-employed and family business workers are not captured by available CHARLS variables. Documented in codebook.
