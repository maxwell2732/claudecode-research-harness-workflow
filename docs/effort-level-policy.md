# Effort Level Policy

## Overview

Defines the mapping between the `effort` field in CC frontmatter and the Anthropic API effort parameter, and the adoption policy within Harness.

## CC Frontmatter to API Effort Matrix

`max` was deprecated in CC v2.1.72; `xhigh` was added in v2.1.111.

| CC frontmatter `effort` value | Effective API effort | Behavior on Opus 4.7 | Behavior on non-Opus 4.7 |
|-------------------------------|---------------------|---------------------|--------------------------|
| `low` | low | low | low |
| `medium` | medium | medium | medium |
| `high` | high | high | high |
| `xhigh` | xhigh (extended thinking) | xhigh (maximum thinking budget) | Falls back to `high` (documented in changelog) |

**Notes**:
- `xhigh` was added to frontmatter in CC v2.1.111 (see `CLAUDE-feature-table.md` / `cc-2.1.99-2.1.111-impact.md`)
- `max` was deprecated in CC v2.1.72. Writing it in frontmatter has no effect.
- When `xhigh` is specified for non-Opus 4.7 models (e.g., Sonnet), CC automatically downgrades to `high`.

### Determining whether xhigh can be passed to the API via CC

**Verdict: Adopt (evidence exists that xhigh is accepted in frontmatter)**

Basis:
1. The v2.1.111 section of `docs/CLAUDE-feature-table.md` records `xhigh effort` as `A: Explicit adoption target`
2. The Opus 4.7 section of the same file also records `xhigh effort` as `A: Explicit adoption target`
3. `docs/cc-2.1.99-2.1.111-impact.md` documents the addition of `xhigh` in v2.1.111
4. Harness `opus-4-7-prompt-audit.md` defines `xhigh` as "the reasoning intensity chosen by the caller"

When `xhigh` is written in frontmatter, CC sends a request to the Anthropic API with extended thinking enabled. On non-Opus 4.7 models, it silently downgrades to `high` equivalent — no rejection or error.

## Harness adoption policy

| Flow | Adopted effort | Reason |
|------|---------------|--------|
| Plan | `high` | Good balance of speed and organization |
| Work (Worker agent) | `high` | Implementation benefits more from iterative verification than deep thinking |
| Review (Reviewer agent, harness-review) | `xhigh` | Incremental thinking benefit appears for comparison, counter-argument, and gap detection |
| Advisor | `xhigh` | Prioritize decision accuracy for PLAN / CORRECTION / STOP |
| Release / Setup | `high` | Procedure compliance is central; `xhigh` always is excessive |

### Frontmatter update targets

| File | Before | After | Reason |
|------|--------|-------|--------|
| `agents/reviewer.md` | `effort: medium` | `effort: xhigh` | Adopt xhigh for Review |
| `agents/advisor.md` | `effort: high` | `effort: xhigh` | Adopt xhigh for Advisor |
| `skills/harness-review/SKILL.md` | `effort: high` | No change | Skill effort is overridden by the caller; maintain high |

## Operational rules

1. **Prioritize review and advisory for `xhigh`**
   Reason: Bug detection and counter-arguments benefit more from incremental thinking than implementation itself.

2. **Keep work at default `high`**
   Reason: Implementation often benefits more from fast iterative verification than token consumption.

3. **Document "non-Opus 4.7 falls back to `high`" in docs**
   Reason: Users easily misunderstand "I wrote `xhigh` but it's not working."

4. **Do not set all skills / all agents uniformly to `xhigh`**
   Reason: Cost and latency increase unnecessarily. Use different levels by role.

5. **Use `${CLAUDE_EFFORT}` as read-only**
   Reason: Since Claude Code 2.1.120+, skill body can reference the current effort level. However, this is for reading the effort chosen by the caller; it is not a mechanism for skills to override effort on their own.

### `${CLAUDE_EFFORT}` guidance

`CLAUDE_EFFORT` is a variable for referencing the effective effort level of the current session / invocation from within the skill body.

Acceptable use:

```md
Current effort: `${CLAUDE_EFFORT}`.
If effort is low, report only confirmed blockers.
If effort is xhigh, include adversarial checks and edge cases.
```

Avoid:

- Requiring "always change to xhigh" in skill body
- Treating environments where `CLAUDE_EFFORT` is empty as failures
- Ignoring effort specified by the user / parent workflow

Harness policy:

- Leave the choice of effort to the caller.
- Skills use `CLAUDE_EFFORT` only for explanation, branching, and output granularity adjustment.
- For internally-invoked skills like media / announcement, prioritize clarifying the invocation contract (`user-invocable` / `disable-model-invocation`) over effort.

## Not adopted (with rationale)

The following are not adopted. Reasons are documented.

| Item | Reason not adopted |
|------|-------------------|
| Setting Worker agent to `xhigh` | Implementation loops benefit more from fast iteration than deep thinking; quality improvement does not justify xhigh cost increase |
| Setting Setup / Release skills to `xhigh` | Procedure compliance is central; recall matters more than judgment in most cases |
| Restoring `max` | Deprecated in CC v2.1.72; `xhigh` is its successor |

## Notes

- `xhigh` is not a "magic that makes it smarter" — it is room to think more deeply
- With vague instructions, deep thinking just refines in the wrong direction
- On non-Opus 4.7 models, `xhigh` falls back to `high` equivalent, so the expected effect may not appear
- Condition 5 of `opus-4-7-prompt-audit.md`: `xhigh` is "the reasoning intensity chosen by the caller"; it is not something the agent prompt infers from free-text markers

## Related files

- `docs/CLAUDE-feature-table.md` — v2.1.111 / Opus 4.7 feature list
- `docs/cc-2.1.99-2.1.111-impact.md` — details of xhigh addition
- `docs/claude-code-setup-mcp-telemetry-provider.md` — `${CLAUDE_EFFORT}` and setup guidance
- `.claude/rules/opus-4-7-prompt-audit.md` — xhigh operational knob definition
- `agents/reviewer.md` — Reviewer effort setting
- `agents/advisor.md` — Advisor effort setting
