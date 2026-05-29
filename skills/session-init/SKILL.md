---
name: session-init
description: "Internal sub-skill for session startup checks, Plans.md status, git state, and harness-mem resume pack. Invoked by session/startup workflows only. Do NOT load for: implementation, reviews, or mid-session tasks."
description-en: "Internal sub-skill for session startup checks, Plans.md status, git state, and harness-mem resume pack. Invoked by session/startup workflows only. Do NOT load for: implementation, reviews, or mid-session tasks."
allowed-tools: ["Read", "Write", "Bash", "mcp__harness__harness_mem_resume_pack", "mcp__harness__harness_mem_sessions_list", "mcp__harness__harness_mem_health"]
user-invocable: false
disable-model-invocation: true
---

# Session Init Skill

A skill for checking the environment and understanding the current task status at session start.

---

## Invocation Conditions

This skill is called internally from `session` / SessionStart-type flows.
The user-facing entry point is `/session` or the normal session start flow.

Legacy trigger phrases:

- "Start session"
- "Begin work"
- "Start today's work"
- "Check status"
- "What should I do?"
- "start session"
- "what should I work on?"

---

## Overview

The Session Init skill automatically checks the following at Claude Code session start:

1. **Git state**: Current branch, uncommitted changes
2. **Plans.md**: In-progress tasks, requested tasks
3. **AGENTS.md**: Role assignments, review of prohibitions
4. **Previous session**: Review of carry-over items
5. **Latest snapshot**: Summary of progress snapshot and diff from previous session

---

## Execution Steps

### Step 0: File State Check (Automatic Cleanup)

Check file sizes before session start:

```bash
# Check Plans.md line count
if [ -f "Plans.md" ]; then
  lines=$(wc -l < Plans.md)
  if [ "$lines" -gt 200 ]; then
    echo "⚠️ Plans.md has ${lines} lines. Recommend organizing with 'organize it'"
  fi
fi

# Check session-log.md line count
if [ -f ".claude/memory/session-log.md" ]; then
  lines=$(wc -l < .claude/memory/session-log.md)
  if [ "$lines" -gt 500 ]; then
    echo "⚠️ session-log.md has ${lines} lines. Recommend organizing with 'organize session log'"
  fi
fi
```

Display a suggestion if cleanup is needed (does not affect work).

### Step 0.5: Legacy Local Memory Compatibility Handling (Optional)

The current standard is the Unified Harness Memory in Step 0.7.
Checking legacy local memory compatibility is generally unnecessary; reference it individually only for special migration checks.

> **Note**: In normal operation, skip this step and treat the common DB Resume Pack as the sole resume entry point.

### Step 0.7: Unified Harness Memory Resume Pack (Required)

Retrieve resume context from the Codex / Claude / OpenCode shared DB (`~/.harness-mem/harness-mem.db`).

Required call:

```text
harness_mem_resume_pack(project, session_id?, limit=5, include_private=false)
```

Operational rules:
- Always specify current project name for `project`
- Obtain `session_id` in order: `$CLAUDE_SESSION_ID` → `.session_id` in `.claude/state/session.json`
- Use of the first result from `harness_mem_sessions_list(project, limit=1)` is limited to read-only (resume check); do not use for writes via `record_checkpoint` / `finalize_session`
- Inject retrieval results into session start context
- On retrieval failure, check daemon state with `harness_mem_health()`, note the failure, and continue
- Recovery order: `scripts/harness-memd doctor` → `scripts/harness-memd cleanup-stale` → `scripts/harness-memd start`

### Step 1: Environment Check

Run the following in parallel:

```bash
# Git state
git status -sb
git log --oneline -3
```

```bash
# Plans.md
cat Plans.md 2>/dev/null || echo "Plans.md not found"
```

```bash
# AGENTS.md key points
head -50 AGENTS.md 2>/dev/null || echo "AGENTS.md not found"
```

### Step 2: Understand Task Status

Extract from Plans.md:

- `cc:WIP` - Tasks continuing from previous session
- `pm:requested` - Tasks newly requested by PM (compatible: cursor:requested)
- `cc:TODO` - Unstarted but assigned tasks

### Step 3: Output Status Report

```markdown
## 🚀 Session Started

**Date/Time**: {{YYYY-MM-DD HH:MM}}
**Branch**: {{branch}}
**Session ID**: ${CLAUDE_SESSION_ID}

---

### 📋 Today's Tasks

**Priority tasks**:
- {{pm:requested (compatible: cursor:requested) or cc:WIP tasks}}

**Other tasks**:
- {{List of cc:TODO tasks}}

---

### ⚠️ Notes

{{Key constraints/prohibitions from AGENTS.md}}

---

**Ready to start work?**
```

---

## Output Format

At session start, present the following information concisely:

| Item | Content |
|------|---------|
| Current branch | e.g., `staging` |
| Priority tasks | Most important 1–2 items |
| Notes | Summary of prohibitions |
| Next action | Specific suggestion |

---

## Related Commands

- `/work` - Task execution (parallel execution supported)
- `/sync-status` - Plans.md progress summary
- `/maintenance` - Automatic file cleanup

---

## Notes

- **Always check AGENTS.md**: Understand role assignments before starting work
- **If Plans.md is missing**: Guide to `/harness-init`
- **If previous work was interrupted**: Confirm whether to continue
