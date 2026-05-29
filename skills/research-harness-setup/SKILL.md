---
name: research-harness-setup
description: "RES: Initialize research project structure, create study_spec.md and analysis_plan.md, set up data protection rules and folder layout. Trigger: setup research project, initialize study, new research project. Do NOT load for: audit, cleaning, analysis, review, release."
description-en: "RES: Initialize research project structure, create study_spec.md and analysis_plan.md, set up data protection rules and folder layout. Trigger: setup research project, initialize study, new research project. Do NOT load for: audit, cleaning, analysis, review, release."
kind: workflow
purpose: "Initialize the research project with source-of-truth files, controlled folder structure, and data protection rules"
trigger: "setup research project, initialize study, new research project, /research-harness-setup"
shape: workflow
role: generator
pair: research-harness-audit
owner: research-harness-core
since: "2026-05-29"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Bash"]
argument-hint: "[--study-name NAME] [--data-path PATH]"
user-invocable: true
effort: low
---

# Research Harness Setup

Initialize a new empirical research project with source-of-truth files, a controlled folder structure, and data protection rules.

This skill runs once at the start of a project. It does not run analysis, audit data, or claim feasibility.

## Quick Reference

| Input | Action |
|---|---|
| `/research-harness-setup` | Interactive: prompt for study name and data path, then create all files |
| `/research-harness-setup --study-name "X" --data-path "data/raw/X.csv"` | Non-interactive: use provided values |

## Procedure

### Step 1 — Collect study context

If arguments are not provided, ask the user for:

1. Study name or working title
2. Path to raw data file(s) (may be `unknown` if data not yet available)
3. Brief description of the research question (one or two sentences; may be `unknown`)

Do not invent answers. If the user says `unknown`, write `unknown` in the spec.

### Step 2 — Create folder structure

Create the following directories if they do not exist. Do not delete or overwrite existing content.

```
data/raw/
data/intermediate/
data/processed/
scripts/
analysis/
output/
logs/
reports/
```

### Step 3 — Create study_spec.md

Copy `templates/study_spec.md` to `study_spec.md` at the project root.

Fill in:
- Study name from Step 1
- Raw data path from Step 1
- Research question from Step 1

Leave all other fields as `unknown`. The researcher fills in the full spec before Stage 2.

If `study_spec.md` already exists: read it, confirm with the user before overwriting, and preserve existing content unless the user explicitly requests replacement.

### Step 4 — Create analysis_plan.md

Copy `templates/analysis_plan.md` to `analysis_plan.md` at the project root.

Fill in:
- Study spec path: `study_spec.md`
- Date: today's date
- Analyst: Claude Code

Leave all task fields as `cc:todo` with `unknown` paths.

If `analysis_plan.md` already exists: do not overwrite. Notify the user.

### Step 5 — Write data protection notice

Append the following block to the project `.gitignore` if it does not already contain it:

```
# Research Agent Harness — raw data is read-only
# Never commit cleaned or processed datasets unless explicitly approved
data/processed/
data/intermediate/
logs/
```

Write a `data/raw/READONLY.md` file with the following content:

```markdown
# data/raw — READ-ONLY

This folder contains raw, unmodified data files.

No script, agent, or tool may write, edit, rename, or delete files in this folder.
All data transformations must produce new files in data/processed/ or data/intermediate/.

See docs/INTEGRITY-RULES.md Rule 1.
```

### Step 6 — Confirm and report

Print a setup summary:

```
Research Agent Harness — Setup Complete

Study spec:     study_spec.md         [created / already existed]
Analysis plan:  analysis_plan.md      [created / already existed]
Folders:        data/raw, data/intermediate, data/processed,
                scripts, analysis, output, logs, reports
Data protection: data/raw/READONLY.md written

Next step: Fill in study_spec.md, then run /research-harness-audit
```

## Forbidden Actions

- Do not modify any file under `data/raw/`
- Do not invent a research question if the user did not provide one
- Do not claim the data is feasible for the proposed design before an audit is run
- Do not run any analysis or data inspection in this step
- Do not overwrite `study_spec.md` without user confirmation if it already exists

## Completion Criteria

- [ ] `study_spec.md` exists with study name, data path, and research question filled in (or `unknown`)
- [ ] `analysis_plan.md` exists with header fields populated
- [ ] All 8 folders exist
- [ ] `data/raw/READONLY.md` exists
- [ ] No files under `data/raw/` were modified

## Handoff to Stage 2

Tell the user:

> Fill in the remaining fields in `study_spec.md` — particularly identification strategy, variables, and sample restrictions — before running `/research-harness-audit`.
> When `study_spec.md` is complete and you have approved it, run `/research-harness-audit`.
