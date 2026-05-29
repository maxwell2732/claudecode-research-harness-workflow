---
name: state-transition
description: "Execute session state transitions using session-state.sh"
allowed-tools: [Read, Bash]
---

# State Transition

Executes session state transitions.

## Inputs

Workflow variables:
- `target_state` (string): Target state to transition to
- `event_name` (string): Trigger event
- `event_data` (string, optional): Additional event data (JSON)

## Valid States

| State | Description |
|-------|-------------|
| `idle` | Session not started |
| `initialized` | SessionStart complete |
| `planning` | Preparing Plan/Work |
| `executing` | /work running |
| `reviewing` | review running |
| `verifying` | build/test running |
| `escalated` | Awaiting human confirmation |
| `completed` | Deliverable confirmed |
| `failed` | Unrecoverable |
| `stopped` | Stop hook reached |

## Typical Transitions

| From | Event | To |
|------|-------|----|
| idle | session.start | initialized |
| initialized | plan.ready | planning |
| planning | work.start | executing |
| executing | work.task_complete | reviewing |
| reviewing | verify.start | verifying |
| verifying | verify.passed | completed |
| verifying | verify.failed | escalated |
| * | session.stop | stopped |
| stopped | session.resume | initialized |

## Execution

```bash
./scripts/session-state.sh --state <state> --event <event> [--data <json>]
```

### Example: Transition to executing state

```bash
./scripts/session-state.sh --state executing --event work.start
```

### Example: Escalation (with data)

```bash
./scripts/session-state.sh --state escalated --event escalation.requested \
  --data '{"reason":"Build failed 3 times","retry_count":3}'
```

## Expected Results

- `state`, `updated_at`, `last_event_id`, `event_seq` in `.claude/state/session.json` are updated
- Event is appended to `.claude/state/session.events.jsonl`
- Invalid transitions output an error to stderr + non-zero exit

## Error Handling

If a transition fails (invalid transition, etc.):
1. Output current state and allowed transitions to stderr
2. Return non-zero exit code
3. Caller (workflow) handles escalation
