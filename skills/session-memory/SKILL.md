---
name: session-memory
description: "Internal sub-skill for cross-session handoff, durable learning, and memory persistence. Invoked by session/memory workflows only. Do NOT load for: implementation, review, ad-hoc notes, or SSOT editing."
description-en: "Internal sub-skill for cross-session handoff, durable learning, and memory persistence. Invoked by session/memory workflows only. Do NOT load for: implementation, review, ad-hoc notes, or SSOT editing."
allowed-tools: ["Read", "Write", "Edit", "Bash"]
user-invocable: false
disable-model-invocation: true
---

# Session Memory Skill

A skill for managing learnings and memory across sessions.
Records and references past work, decisions, and learned patterns.

---

## Trigger Phrases

This skill is automatically invoked by the following phrases:

- "What did we do last time?", "Continue from last time"
- "Show me the history", "Past work"
- "Tell me about this project"
- "what did we do last time?", "continue from before"

---

## Overview

This skill saves work history to `.claude/memory/` and
enables knowledge continuity across sessions.

It also clarifies "where important information should be stored" (details: `docs/MEMORY_POLICY.md`).

---

## Memory Structure

```
.claude/
├── memory/
│   ├── session-log.md      # Per-session log
│   ├── decisions.md        # Important decisions
│   ├── patterns.md         # Learned patterns
│   └── context.json        # Project context
└── state/
    └── agent-trace.jsonl   # Agent Trace (tool execution history)
```

### Recommended Operation (SSOT/Local separation)

- **SSOT (recommended for sharing)**: `decisions.md` / `patterns.md`
  - Consolidates "decisions (Why)" and "reusable solutions (How)"
  - Each entry has a **title + tags** (e.g., `#decision #db`) with an **Index** at the top
- **Recommended as local**: `session-log.md` / `context.json` / `.claude/state/`
  - Prone to noise/bloat; generally not Git-managed (decide individually if needed)

---

## Auto-Recorded Information

### session-log.md

Each session record is assigned a session ID obtained from the runtime environment.
In Claude Code, `${CLAUDE_SESSION_ID}` is preferred; in Codex, the Codex runtime session / thread ID is preferred.
If neither is available, read `.session_id` from `.claude/state/session.json`, with datetime-based ID as final fallback.
This improves cross-session traceability.

```markdown
## Session: 2024-01-15 14:30 (session: abc123def)

### Tasks Completed
- [x] User authentication implementation
- [x] Login page creation

### Files Generated
- src/lib/auth.ts
- src/app/login/page.tsx

### Important Decisions
- Authentication method: Adopted Supabase Auth

### Handoff to Next Session
- Logout feature not yet implemented
- Password reset also needed
```

> **Note**: `${CLAUDE_SESSION_ID}` is an environment variable automatically set by Claude Code.
> This variable may not exist on the Codex side, so do not assume it is fixed; use the Codex runtime session / thread ID or `.claude/state/session.json` instead.

### decisions.md

```markdown
## Technology Selections

| Date | Decision | Reason |
|------|---------|--------|
| 2024-01-15 | Supabase Auth | Free tier available, easy setup |
| 2024-01-14 | Next.js App Router | Latest best practices |

## Architecture

- Components: `src/components/`
- Utilities: `src/lib/`
- Type definitions: `src/types/`
```

### patterns.md

```markdown
## Patterns in This Project

### Component Naming
- PascalCase
- Examples: `UserProfile.tsx`, `LoginForm.tsx`

### API Endpoints
- `/api/v1/` prefix
- RESTful design

### Error Handling
- Wrap in try-catch
- Error messages in English
```

### context.json

```json
{
  "project_name": "my-blog",
  "created_at": "2024-01-14",
  "stack": {
    "frontend": "next.js",
    "backend": "next-api",
    "database": "supabase",
    "styling": "tailwind"
  },
  "current_phase": "Phase 2: Core Features",
  "last_session": "2024-01-15T14:30:00Z"
}
```

---

## Processing Flow

### At Session Start

1. Load `.claude/memory/context.json`
2. Check previous session log
3. **Retrieve recent edit history from Agent Trace**
4. Identify incomplete tasks
5. Generate context summary

**Agent Trace Usage**:
```bash
# Get list of edited files from last session
tail -50 .claude/state/agent-trace.jsonl | jq -r '.files[].path' | sort -u

# Get project information
tail -1 .claude/state/agent-trace.jsonl | jq '.metadata'
```

### During Session

1. Record important decisions to `decisions.md`
2. Add new patterns to `patterns.md`
3. Record file generation to `session-log.md`

### At Session End

1. Generate session summary
2. Update `context.json`
3. Record handoff items for next session

---

## Memory Optimization (CC 2.1.49+)

From Claude Code 2.1.49 onward, memory usage when resuming sessions has been **reduced by 68%**.

### Recommended Workflow

```bash
# Use --resume for long work sessions
claude --resume

# Split large tasks and resume sessions
claude --resume "Continue from where we left off"
```

| Scenario | Recommendation |
|---------|----------------|
| Long implementation | Resume session every 1–2 hours |
| Large-scale refactoring | Split by feature unit |
| Memory shortage warning | Immediately resume with `--resume` |

> Memory efficiency has greatly improved — actively leverage session resumption.

### /recap — Mid-Session Status Check (CC 2.1.108+)

The `/recap` command added in CC 2.1.108 (alias for `/rewind`) is used to quickly review
what has been done so far in the current session.
Most effective when combined with checking before returning to another session with `--resume`, or for mid-session checks during long work.

**Recommended Timing**:

| Timing | Usage |
|--------|-------|
| Just before resuming with `--resume` | Use `/recap` to organize context before `claude --resume` |
| Before resuming a Breezing Worker | Check in-session progress with `/recap` before moving to next task |
| Midpoint of long implementation (over 1 hour) | Check status with `/recap` → manually append to `session-log.md` if needed |

```bash
# Typical usage flow
# 1. Check current work status
/recap

# 2. After manually appending to session-log.md if needed, resume session
claude --resume
```

> `/recap` only reviews within the current session. Previous session content is checked via
> `session-log.md` or context inheritance with `claude --resume`.

---

## Usage Examples

### Continue from Last Time

```
User: "Continue from last time"

Claude Code:
📋 Previous Session (2024-01-15)

Completed tasks:
- User authentication
- Login page

Incomplete:
- Logout feature
- Password reset

Say "Create the logout feature" to continue implementation.
```

### Check Project Status

```
User: "Tell me about this project"

Claude Code:
📁 Project: my-blog

Technology stack:
- Next.js + Tailwind CSS + Supabase

Current phase: Core feature development
Progress: 40% complete

Recent decisions:
- Adopted Supabase Auth
- Using App Router
```

---

## Relationship with Claude Code Auto-Memory (D22)

Claude Code 2.1.32+ has an "auto-memory" feature that automatically saves cross-session learnings to `~/.claude/projects/<project>/memory/MEMORY.md`.

It coexists with the Harness memory system as a **3-layer architecture**:

| Layer | System | Content | Management |
|-------|--------|---------|------------|
| **Layer 1** | Claude Code auto-memory | General learnings (avoiding mistakes, tool usage) | Implicit/automatic |
| **Layer 2** | Harness SSOT | Project-specific decisions and patterns | Explicit/manual |
| **Layer 3** | Agent Memory | Per-agent task learnings | Agent-defined |

**Usage guidelines**:
- If Layer 1 insights are important for the whole project → Promote to Layer 2 with `/memory ssot`
- Leave everyday learnings to Layer 1 (do not disable)
- Note parallel write contention when using Agent Teams

Details: [D22: 3-Layer Memory Architecture](../../.claude/memory/decisions.md#d22-3layer-memory-architecture)

---

## Notes

- **Auto-save**: Recommend appending a session summary to `session-log.md` automatically via `hooks/Stop` at session end (manual operation is fine if not set up)
- **Privacy**: Do not record sensitive information
- **Git policy**: `decisions.md`/`patterns.md` recommended for sharing; `session-log.md`/`context.json`/`.claude/state/` recommended as local-only (details: `docs/MEMORY_POLICY.md`)
- **Capacity management**: When logs grow large, recommend "organize session log"
