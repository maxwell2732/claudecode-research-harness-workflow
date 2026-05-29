# Advisor Strategy

## In a Nutshell

The Advisor Strategy is an approach where **the executor operates autonomously most of the time, and the advisor is called in only for difficult situations**.

In Harness v1, this approach is first applied to the `harness-loop`.

## Analogy

Rather than a supervisor who gives detailed instructions at every step, think of it as a field worker handling day-to-day operations independently, and only consulting a senior colleague when a decision feels particularly weighty.

This arrangement means the heavy decision-maker doesn't need to be involved every time, making it easier to balance speed and safety.

## Roles

The Harness has four roles:

| Role | Responsibility |
|------|----------------|
| Lead | Manages the overall flow |
| Worker / executor | Advances implementation and fixes |
| Advisor | Provides guidance on direction only |
| Reviewer | Makes the final quality judgment |

The key point is that **the Advisor is not a substitute for the Reviewer**.

The Advisor returns "how to proceed next." The final decision of `APPROVE` or `REQUEST_CHANGES` remains with the Reviewer, as always.

## When the Advisor Is Called

In v1, consultation is limited to three situations:

1. Before the first execution of a high-risk task
2. After two consecutive failures with the same root cause
3. Just before `PIVOT_REQUIRED` is returned by plateau detection

High-risk tasks, under the current contract, are any of the following:

- `needs-spike`
- `security-sensitive`
- `state-migration`

To avoid repeating the same consultation multiple times, a `trigger_hash` identifier is used.

This is a fingerprint combining **"which task," "what reason," and "what kind of failure"**.

Only one consultation is made per unique `trigger_hash`. Additionally, the maximum number of consultations per task is 3.

## Three Decisions the Advisor Returns

The Advisor's response is fixed as the `advisor-response.v1` JSON format.
There are only three types of decisions:

| Decision | Meaning | Harness Action |
|----------|---------|----------------|
| `PLAN` | Reorganize the approach | Prepend the advice to the next execution prompt and re-run |
| `CORRECTION` | The direction is correct, only a local fix is needed | Re-run with correction instructions |
| `STOP` | It is better not to continue autonomously | Stop the loop, record the reason in state, and escalate |

## Concrete Example

Consider a scenario where a task containing `state-migration` is being processed in `harness-loop`:

1. The loop reads the sprint contract
2. The task is identified as high-risk
3. The advisor is consulted exactly once before implementation begins
4. The advisor returns `PLAN`
5. The loop prepends that advice to the next prompt and runs the executor
6. After implementation, the final judgment is made by the Reviewer

In other words, the advisor does not take over the implementation itself — it only sets the direction so the executor can proceed without hesitation.

## Why Start with `harness-loop`

There are three reasons:

1. In long-running executions, calling in the heavy decision-maker only when stuck is especially effective
2. With `run.json` and `cycles.jsonl` available, it is easy to preserve a consultation history
3. It can be introduced without disrupting the existing Reviewer and checkpoint flow

In other words, rather than changing all execution paths at once, **the approach starts where the impact is greatest and where it is easiest to observe**.

## Known Constraints

There are things intentionally left out of v1:

- Workers cannot freely spawn new subagents
- Natural-language-based confidence estimation is not yet used
- Advisor persistence remains file-based state rather than SQLite
- Phase 61 weak-supervision cues pass only a short set of evidence events recorded in `.claude/state/elicitation/events.jsonl`, rather than natural-language confidence estimates
- `breezing` and `harness-work` begin with unifying the protocol and documentation

## Related Files

- `agents/advisor.md`
- `scripts/run-advisor-consultation.sh`
- `scripts/codex-loop.sh`
- `skills/harness-loop/SKILL.md`
- `skills/harness-loop/references/flow.md`

## Why This Approach

Harness was originally designed to separate "planning," "implementation," and "review" to make the system more resilient.

When introducing the Advisor Strategy, it is safer to keep that foundation intact and **only increase the executor's autonomous capability**.

Therefore, in v1, "adding an advisor" is primary, while "transferring quality judgment responsibility" is not done.
