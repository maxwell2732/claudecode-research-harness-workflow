# TeamAgent Debate

## In a nutshell

TeamAgent Debate is a read-only review pass that reads the same changes from separate viewpoints to reduce oversights.

## When required

Run when any of the following apply:

- Changes span multiple modules
- Touches security / auth / release / distribution / mirror
- Correspondence with spec source of truth or `Plans.md` is ambiguous
- Regression risk is high
- Claude and Codex verdicts diverge
- Perspective-based evaluations diverge within the reviewer
- The same issue failed twice in a row during post-fix re-review

## Agents

| Agent | Primary question |
|-------|----------------|
| Spec Agent | Find conflicts between spec source of truth and implementation diff |
| Plans Agent | Verify correspondence between `Plans.md` task / DoD / Depends and diff |
| Regression Agent | Find regressions in existing behavior, tests, distribution mirrors, CLI/skill UX |
| Skeptic Agent | Find major risks being overlooked under the assumption of wanting to pass |

Minimum 2 perspectives; up to 4 when needed.
All read-only.

## Codex fallback

Even when native TeamAgent is unavailable in Codex environments, do not skip.

Available fallbacks:

- `codex-companion.sh review`
- Reviewer subagent
- Explicitly separated manual-pass

Record one of the following in `team_agent_mode`:

- `native`
- `codex-companion`
- `manual-pass`
- `unavailable`

When `unavailable` and manual-pass is also impossible, stop as `decision_needed`.

## Output

```json
{
  "team_debate": {
    "required": true,
    "mode": "manual-pass",
    "team_agent_mode": "manual-pass",
    "agents": ["Spec Agent", "Plans Agent", "Regression Agent"],
    "disagreements": [],
    "acceptance_bar": {
      "spec_alignment": "pass",
      "plans_alignment": "pass",
      "regression_safety": "pass"
    }
  }
}
```

## Pass threshold

If TeamAgent Debate disagreements are critical / major equivalent → `REQUEST_CHANGES`.
When downgrading to minor / recommendation, write the reason with evidence.
