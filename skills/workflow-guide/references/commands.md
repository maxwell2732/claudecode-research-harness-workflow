# Command Reference

Details of commands used in the 2-agent workflow.

---

## Claude Code Commands

### /setup

Initial project setup (formerly `/harness-init`).

```
/setup
```

**Files generated**:
- Plans.md - Task management
- AGENTS.md - Role assignment definitions
- CLAUDE.md - Claude Code configuration
- .claude/rules/ - Project rules

---

### /setup codex

Install/update Harness configuration for Codex CLI at **user base** (`${CODEX_HOME:-~/.codex}`).

```
/setup codex
```

**Files generated (default)**:
- ${CODEX_HOME:-~/.codex}/skills/
- ${CODEX_HOME:-~/.codex}/rules/
- (optional) ${CODEX_HOME:-~/.codex}/config.toml

**In project mode only**:
- .codex/skills/
- .codex/rules/
- AGENTS.md

---

### /plan-with-agent

Plan and break down tasks.

```
/plan-with-agent [task description]
```

**Example**:
```
/plan-with-agent I want to implement user authentication
```

**Output**: Tasks are added to Plans.md

---

### /work

Execute tasks in Plans.md.

```
/work
```

**Features**:
- Automatically detects `cc:TODO` or `pm:requested` tasks
- Supports parallel execution of multiple tasks
- Automatically updates to `cc:done` on completion

---

### /sync-status

Output current state summary.

```
/sync-status
```

**Sample output**:
```
📊 Current Status
- In progress: 2
- Not started: 5
- Completed (awaiting confirmation): 1
```

---

### /handoff-to-cursor

Completion report to Cursor PM.

```
/handoff-to-cursor
```

**Included information**:
- List of completed tasks
- Changed files
- Test results
- Suggested next actions

---

## Cursor Commands (For Reference)

### /handoff-to-claude

Task delegation to Claude Code.

### /review-cc-work

Review Claude Code's completion report.
If not approving (request_changes), update Plans.md and **generate a revision request via `/claude-code-harness/handoff-to-claude` and pass it directly**.

---

## Skills (Auto-invoked in Conversation)

### handoff-to-pm

**Trigger**: "Report completion to PM", "Report work complete"

Generates a completion report from Worker → PM.

### handoff-to-impl

**Trigger**: "Hand off to implementation", "Delegate to Claude Code"

Formats a task delegation from PM → Worker.

---

## Command Usage Flow

```
[Session start]
    │
    ▼
/sync-status  ←── Check current status
    │
    ▼
/work  ←── Execute tasks
    │
    ▼
/handoff-to-cursor  ←── Completion report
    │
    ▼
[Session end]
```
