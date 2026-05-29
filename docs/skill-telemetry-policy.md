# Skill Telemetry Policy (Phase 62.2.3)

> **Status**: Active (2026-05-07)
> **Scope**: Operational rules for recording the `invocation_trigger` field of the `claude_code.skill_activated` OTel event (fired in Claude Code `2.1.126+`) to a local ledger.

## In a nutshell

Record the trigger type (human / model / skill-chain) for skill activations in a **local ledger** to identify skills firing unnecessarily.
When recording, always comply with **privacy / retention / opt-out** requirements.

## Analogy

Similar to "writing only the title of a book read in a household ledger."
Do not write the contents (skill input / output); only record when, under which trigger type, and which skill was activated (`skill_activated` event).

## Telemetry sink design assumptions

Phase 58.2.3 concluded "design the telemetry sink first." This document specifies that sink.

| Item | Spec |
|------|------|
| Sink type | **Local-only JSON Lines ledger** (no external transmission) |
| Ledger path | `.claude/state/skill-trigger-stats.jsonl` |
| Append method | **Append-only** (append only; no compaction or deletion) |
| Collection path | Receive OTel events from Claude Code via `scripts/skill-trigger-telemetry.sh` |
| Output format | 1 JSON object per line |

## Recorded fields

Each record contains only the following fields. **No personally identifiable information is recorded.**

```json
{
  "timestamp": "2026-05-07T00:00:00Z",
  "skill_name": "harness-work",
  "invocation_trigger": "human|model|skill-chain",
  "session_id": "session-abc123",
  "duration_ms": 0
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `timestamp` | yes | RFC3339 UTC |
| `skill_name` | yes | Name of the activated skill (`harness-work`, `harness-review`, etc.) |
| `invocation_trigger` | yes | One of `human` / `model` / `skill-chain` |
| `session_id` | yes | CC session ID (truncated to first 12 characters if 12+ chars) |
| `duration_ms` | no | Skill execution time; only recorded if provided by CC |

**Fields NOT recorded**:
- Skill input prompt
- Skill output body
- Username / email address
- API token / credentials
- Individual file paths (no granularity beyond skill name)

## Privacy principles

1. **Local-only**: Ledger is placed under `.claude/state/`; not transmitted externally
2. **Identifier minimization**: session_id is truncated to a prefix of 12 characters or fewer
3. **Content opacity**: Skill input/output body is not recorded
4. **Opt-out available**: Disable with env var `HARNESS_SKILL_TELEMETRY_DISABLE=1`

## Retention

| Trigger | Retention period | Deletion timing |
|---------|-----------------|-----------------|
| Default | **30 days** | `scripts/maintenance/prune-skill-telemetry.sh` (manual or cron) |
| User deletion request | Immediate | `rm .claude/state/skill-trigger-stats.jsonl` |
| On repo clone / share | Do not share | Add to `.gitignore` (existing .gitignore covers state path bulk exclusion) |

Records older than 30 days are **recommended** for manual deletion but are not auto-deleted (to allow long-term retention for audit purposes).
If auto-deletion is implemented, use rotation format (`stats.jsonl.{date}` move) to preserve append-only property.

## Opt-out

### Full disable

Disable via `.claude/settings.json` or env var:

```bash
export HARNESS_SKILL_TELEMETRY_DISABLE=1
```

Or:

```json
{
  "env": {
    "HARNESS_SKILL_TELEMETRY_DISABLE": "1"
  }
}
```

### Partial disable (per skill)

Write an exclude list in `.claude/settings.local.json`:

```json
{
  "harness": {
    "skill_telemetry_exclude": ["harness-work", "harness-loop"]
  }
}
```

## Related docs

- Phase 58.2.3 (`docs/upstream-followups-phase58-2026-05-03.md`) — telemetry sink design decision
- Phase 61 (`docs/sandbagging-aware-weak-supervision.md`) — follows the same append-only design as the `.claude/state/elicitation/events.jsonl` ledger
- Claude Code OTel reference (Anthropic docs)

## Acceptance criteria (Phase 62.2.3 DoD)

- [x] `docs/skill-telemetry-policy.md` exists (this document)
- [x] Privacy / retention / opt-out documented
- [x] Consistent with Phase 58.2.3 decision (sink design fixed as local-only)
- [x] Sink path: `.claude/state/skill-trigger-stats.jsonl`
- [x] Schema: timestamp / skill_name / invocation_trigger / session_id / duration_ms

## References

- Claude Code 2.1.126 CHANGELOG: `claude_code.skill_activated` OTel event includes `invocation_trigger`
- Phase 61 sandbagging-aware weak-supervision ledger design (privacy-first, append-only)
