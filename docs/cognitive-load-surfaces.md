# 3 HTML Surfaces for Reducing Cognitive Load (Phase 65)

Three HTML screens that let even non-engineers grasp in 3 seconds "what Claude is thinking," "where it is now," and "what it accomplished."

## Goal

When developing alongside AI, continuously reading commit logs and Plans.md (= task list markdown) creates high cognitive load.
Provide 3 one-page HTML screens that project sponsors, producers, and managers can **open in a browser and judge at a glance** during live AI development.

| Surface | Purpose | When to view |
|---------|---------|--------------|
| **Plan Brief** (before start) | "This is Claude's understanding. OK to proceed?" | Approval before implementation |
| **Progress Tracker** (in progress) | "How far along, and when is it expected to finish?" | Any time (auto-regenerated) |
| **Acceptance Demo** (at handoff) | "Do you accept this deliverable?" | Acceptance check after implementation |

## How to use

### Plan Brief (1st surface)

```bash
# During a Claude session
/harness-plan-brief
```

Claude summarizes the following into a single HTML page:
- Claude's understanding of the user's request
- Options (each option if multiple approaches exist)
- Risks (potential problem areas)
- Acceptance criteria
- Confidence level (0–100 with rationale)

The user responds with "proceed," "modify this," or "I have a question."
Decisions are recorded in `personal-preference.v1` schema (with sha256 hash).

### Progress Tracker (2nd surface)

```bash
# Check progress
/harness-progress
```

Or the PostToolUse hook auto-regenerates **once every 60 seconds** when Edit/Write/Bash fires.

Display contents:
- progress_pct (cc:done tasks / total tasks × 100)
- Current WIP task
- Last 5 completed tasks
- Next 5 pending tasks
- Drift alerts (5 types, severity color-coded: red=critical / yellow=warn / blue=info)

### Acceptance Demo (3rd surface)

```bash
# After implementation completes
/harness-accept
```

Claude summarizes the following into a single HTML page:
- Verdict (3 choices: ship / wait / reject)
- Acceptance criteria verification (each Plan Brief item marked "confirmed" or "unconfirmed")
- Unverified reservations
- Past issue pattern history
- List of presented deliverables

The user responds with accept / override / reject.
Decisions are recorded in `acceptance-decision.v1` and can be graph-joined with Plan Brief using the **same `user_request_hash`**.

## Notes

### 1. Plan Brief and Acceptance Demo are linked by user_request_hash

When Plan Brief is launched, the sha256 hash of the "user request text" is taken and saved in the record.
Acceptance Demo takes the same hash and saves it in the record.
**These 2 records can be graph-joined from `mcp__harness__harness_mem_search` using the same hash.**

This enables a complete retrospective: "What happened to that plan we made back then?"

### 2. Progress Tracker rate limit (60 seconds)

Even in scenarios where PostToolUse hook triggers large numbers of Edit/Write operations (large refactor), HTML regeneration is limited to once every 60 seconds.
State file: `.claude/state/progress-last-regen.txt` (epoch seconds).

### 3. Drift alerts accumulate within session; not persisted

The 5 alert types (scope-creep / time-overrun / repeated-failure / cost-warning / high-risk-file) display in-session state in the Progress Tracker HTML.
**They are not persisted to memory** (Issue #87 policy; Lead process in-memory only).

Past user judgments on alerts are aggregated by `progress-past-judgments.sh` and displayed as "You declined a similar proposal N out of M times in the past," but this has design space for separate `alert-judgment.v1` record permanent storage (not implemented in this phase).

### 4. Client information handling

When the `--cross-project-group <name>` flag enabling cross-project search is used,
**3-layer redaction** (Layer 2a dictionary + Layer 2b NER + Layer 3 final scan) is automatically applied.
Details: [cross-project-safety.md](cross-project-safety.md)

## Related files

| File | Purpose |
|------|---------|
| `skills/harness-plan-brief/` | Plan Brief skill (Phase 65.1) |
| `skills/harness-accept/` | Acceptance Demo skill (Phase 65.2) |
| `skills/harness-progress/` | Progress Tracker skill (Phase 65.4) |
| `templates/html/plan-brief.html.template` | Plan Brief HTML template |
| `templates/html/accept.html.template` | Acceptance Demo HTML template |
| `templates/html/progress.html.template` | Progress Tracker HTML template |
| `scripts/render-html.sh` | Mustache-style template renderer (supports `--with-redaction` flag) |
| `scripts/plan-brief-record-decision.sh` | Plan Brief decision recorder |
| `scripts/accept-record-decision.sh` | Acceptance Demo decision recorder |
| `scripts/progress-snapshot.sh` | Plans.md → snapshot JSON |
| `scripts/progress-detect-drift.sh` | 5 alert type detector |
| `scripts/progress-past-judgments.sh` | Past judgment lookup |
| `scripts/hook-handlers/posttool-progress-regen.sh` | PostToolUse auto-regeneration hook |

## Related schemas

- `plan-brief-context.v1` (Plan Brief render input)
- `acceptance-context.v1` (Acceptance Demo render input)
- `progress-snapshot.v1` (Progress Tracker render input)
- `personal-preference.v1` (Plan Brief decision record)
- `acceptance-decision.v1` (Acceptance Demo decision record)
- `progress-alert.v1` (drift alert)
