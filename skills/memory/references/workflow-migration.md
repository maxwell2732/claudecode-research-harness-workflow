---
name: migrate-workflow-files
description: "Migrates existing AGENTS.md/CLAUDE.md/Plans.md in a project to the new format through interactive review of existing content to confirm carry-over items (with backup; Plans.md uses task-preserving merge)."
allowed-tools: ["Read", "Write", "Edit", "Bash"]
---

# Migrate Workflow Files (Interactive Merge)

## Purpose

Updates files currently in use in an existing project to the new format **while respecting their existing content**.

- `AGENTS.md`
- `CLAUDE.md`
- `Plans.md`

Key points:

- **Carry-over information confirmed interactively** (nothing silently discarded or overwritten)
- Always leave a **backup** before making changes
- `Plans.md` follows the `merge-plans` approach: **preserving tasks while updating structure**

---

## Prerequisites (Important)

This skill proceeds in the order **user agreement → backup → generation → diff review**
to balance "safety on first application" with "intended behavior (new format)".

---

## Inputs (Can be auto-detected within this skill)

- `project_name`: Estimated from `basename $(pwd)`
- `date`: `YYYY-MM-DD`
- Existence of existing files:
  - `AGENTS.md`
  - `CLAUDE.md`
  - `Plans.md`
- Reference templates for the new format:
  - `templates/AGENTS.md.template`
  - `templates/CLAUDE.md.template`
  - `templates/Plans.md.template`

---

## Execution Flow

### Step 0: Detection and Agreement (Required)

1. Use `Read` to check whether `AGENTS.md` / `CLAUDE.md` / `Plans.md` exist.
2. If they exist, confirm with the user:
   - **Whether it is OK to migrate (update to new format)**
   - Important: Migration **includes content reorganization** (= some repositioning or rewording may occur)

If the user says NO:

- Stop this skill (do not rewrite anything)
- Instead, suggest safe operations such as "only safely merge `.claude/settings.json`"

### Step 1: Review Existing Content (Summarize)

`Read` each file and extract and briefly present:

- **AGENTS.md**: Role assignments, handoff procedures, prohibitions, environment/prerequisites
- **CLAUDE.md**: Key constraints (prohibitions/permissions/branch operations), test procedures, commit conventions, operational rules
- **Plans.md**: Task structure, marker operations, current WIP/requested tasks

### Step 2: Confirm Carry-over Items (Interactive)

Based on the summary, ask the user which items to **keep/adjust** (5–10 questions is sufficient):

- Constraints that must definitely be kept (e.g., production deploy prohibition, specific directory prohibition, security requirements)
- Role assignment assumptions (Solo/2-agent)
- Branch operations (main/staging, etc.)
- Representative test/build commands
- Plans marker operations (align with existing rules if any)

### Step 3: Create Backup (Required)

Gather backups in `.claude-code-harness/backups/` within the project (often preferred to keep out of Git).

Example:

- `.claude-code-harness/backups/2025-12-13/AGENTS.md`
- `.claude-code-harness/backups/2025-12-13/CLAUDE.md`
- `.claude-code-harness/backups/2025-12-13/Plans.md`

Use `mkdir -p` and `cp` via `Bash`.

### Step 4: Generate New Format (Merge)

#### 4-1. Plans.md (Task-Preserving Merge)

Execute following the `merge-plans` approach:

- Preserve existing 🔴🟡🟢📦 tasks
- Update marker legend and last-update info from template side
- If parsing fails, keep backup and adopt template

#### 4-2. AGENTS.md / CLAUDE.md (Template + Carry-over Block)

Build the skeleton with the template, then **reposition the items confirmed in Step 2 to the appropriate location in the new format**.

Minimum policy:

- Do not delete existing "important rules"; keep them as a **"Project-Specific Rules (Migrated)"** section
- Rewrite role assignments/flow to match the template format (preserve meaning)

### Step 5: Review Diff and Complete

- Briefly summarize changes via `git diff` (or file diff)
- Final confirmation that key points (permissions/prohibitions/task state) are as intended
- Fix immediately if there are any issues

---

## Deliverables (Completion Criteria)

- **New-format versions** of `AGENTS.md` / `CLAUDE.md` / `Plans.md` incorporating the existing content
- A backup exists in `.claude-code-harness/backups/`
- Plans tasks are not lost (preserved)
