---
name: workflow-guide
description: "Explicit helper for Cursor PM ↔ Claude Code two-agent workflow guidance. Do NOT load for: solo implementation, workflow setup, handoff execution, or general process coaching."
description-en: "Explicit helper for Cursor PM ↔ Claude Code two-agent workflow guidance. Do NOT load for: solo implementation, workflow setup, handoff execution, or general process coaching."
allowed-tools: ["Read"]
user-invocable: false
disable-model-invocation: true
---

# Workflow Guide Skill

A skill providing guidance on the Cursor ↔ Claude Code 2-agent workflow.

---

## Trigger Phrases

This skill is invoked by the following phrases:

- "Tell me about the workflow"
- "How do I collaborate with Cursor?"
- "Explain the work process"
- "How should I proceed?"
- "how does the workflow work?"
- "explain 2-agent workflow"

---

## Overview

This skill explains the role assignment and collaboration method between Cursor (PM) and Claude Code (Worker).

---

## 2-Agent Workflow

### Role Assignment

| Agent | Role | Responsibilities |
|-------|------|-----------------|
| **Cursor** | PM (Project Manager) | Task assignment, review, production deploy decisions |
| **Claude Code** | Worker | Implementation, testing, CI fixes, staging deploy |

### Workflow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Cursor (PM)                          │
│  - Add tasks to Plans.md                                │
│  - Delegate work to Claude Code (/handoff-to-claude)    │
│  - Review completion reports                            │
│  - Make production deploy decisions                     │
└─────────────────────┬───────────────────────────────────┘
                      │ Task delegation
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  Claude Code (Worker)                   │
│  - Execute tasks with /work (parallel execution)        │
│  - Implement → Test → Commit                            │
│  - Auto-fix CI failures (up to 3 times)                 │
│  - Completion report with /handoff-to-cursor            │
└─────────────────────┬───────────────────────────────────┘
                      │ Completion report
                      ▼
┌─────────────────────────────────────────────────────────┐
│                    Cursor (PM)                          │
│  - Review changes                                       │
│  - Verify on staging                                    │
│  - Execute production deploy (after approval)           │
└─────────────────────────────────────────────────────────┘
```

---

## Task Management with Plans.md

### Marker List

| Marker | Meaning | Set by |
|--------|---------|--------|
| `pm:requested` | Requested by PM (compatible: cursor:requested) | PM (Cursor/PM Claude) |
| `cc:TODO` | Claude Code not started | Either |
| `cc:WIP` | Claude Code in progress | Claude Code |
| `cc:done` | Claude Code complete | Claude Code |
| `pm:confirmed` | PM confirmation complete (compatible: cursor:confirmed) | PM (Cursor/PM Claude) |
| `cursor:requested` | (compatible) Same as pm:requested | Cursor |
| `cursor:confirmed` | (compatible) Same as pm:confirmed | Cursor |
| `blocked` | Blocked | Either |

### Task State Transitions

```
pm:requested → cc:WIP → cc:done → pm:confirmed
```

---

## Key Commands

### Claude Code Side

| Command | Purpose |
|---------|---------|
| `/harness-init` | Project setup |
| `/plan-with-agent` | Planning/task breakdown |
| `/work` | Task execution (parallel execution supported) |
| `/handoff-to-cursor` | Completion report (to Cursor PM) |
| `/sync-status` | Status check |

### Skills (Auto-invoked in Conversation)

| Skill | Trigger Example |
|-------|----------------|
| `handoff-to-pm` | "Report completion to PM" |
| `handoff-to-impl` | "Hand off to implementation" |

### Cursor Side (For Reference)

| Command | Purpose |
|---------|---------|
| `/handoff-to-claude` | Delegate tasks to Claude Code |
| `/review-cc-work` | Review completion reports |

---

## CI/CD Rules

### Claude Code's Scope of Responsibility

- ✅ Up to staging deploy
- ✅ Auto-fix CI failures (up to 3 times)
- ❌ Production deploy is prohibited

### 3-Strike Rule

If CI fails 3 times in a row:
1. Stop auto-fix
2. Generate escalation report
3. Defer decision to Cursor

---

## Frequently Asked Questions

### Q: What if Cursor is not available?

A: Even when working alone, task management with Plans.md is recommended.
Perform production deploys manually and carefully.

### Q: What if a task is unclear?

A: Request clarification from Cursor, or use `/sync-status` to organize the current state.

### Q: What if CI keeps failing?

A: Do not auto-fix more than 3 times; escalate to Cursor.

---

## Related Documents

- AGENTS.md - Detailed role assignments
- CLAUDE.md - Claude Code specific configuration
- Plans.md - Task management file
