# Dual Review (--dual)

Run Claude Reviewer and Codex Reviewer in parallel to improve review quality with different model perspectives.
`--dual` is not simply a double-check; it combines TeamAgent Debate when needed to eliminate gaps in spec source of truth / Plans.md / regression pass thresholds from multiple viewpoints.

## Prerequisites

- Codex CLI installed (verify with `scripts/codex-companion.sh setup --json`)
- When Codex is unavailable, fall back to Claude-only review

## Execution flow

1. Check Codex availability

   ```bash
   CODEX_AVAILABLE="$(bash scripts/codex-companion.sh setup --json 2>/dev/null | jq -r '.ready // false')"
   ```

2. Launch Claude Reviewer with Task tool (normal review flow)

3. If Codex is available, launch `scripts/codex-companion.sh review` in parallel

   ```bash
   # Specify --base when BASE_REF is provided. Use --json for structured output
   bash scripts/codex-companion.sh review --base "${BASE_REF:-HEAD~1}" --json
   ```

4. Wait for both results

5. Run TeamAgent Debate if any of the following apply:
   - Claude and Codex verdicts diverge
   - Mismatch or unconfirmed items in spec source of truth, Plans.md, or regression
   - One or more `critical` / `major` candidates
   - `--team-debate` is specified

6. Fix the pass threshold first, then merge verdicts

## TeamAgent Debate

TeamAgent Debate is treated as a read-only review pass that intentionally collides different viewpoints.

| Agent | Primary question |
|-------|----------------|
| Spec Agent | Is the spec source of truth in conflict with the implementation? |
| Plans Agent | Does the evidence match the `Plans.md` task / DoD / Depends? |
| Regression Agent | Are there regressions in existing behavior, existing tests, distribution mirrors, CLI/skill UX? |
| Skeptic Agent | Are there major risks being overlooked under the assumption of wanting to pass? |

Use Task tool in Claude Code.
When native TeamAgent is unavailable in Codex environments,
reproduce the same perspectives with Codex reviewer subagent, `codex-companion.sh review`, or explicitly separated manual-pass,
and record in `team_agent_mode`.

## Pass threshold

Final `APPROVE` requires all of:

- Zero `critical` / `major`
- No conflict with spec source of truth or `spec_skip_reason`
- No conflict with `Plans.md` task / DoD / Depends
- No regression evidence in existing behavior, existing tests, distribution mirrors, CLI/skill UX
- Claude / Codex / TeamAgent disagreements are resolved or downgraded to `minor` / `recommendation` with reasoning

## Verdict merge rules

Evaluate in this order:

   - Both APPROVE → `APPROVE`
   - Either is REQUEST_CHANGES → `REQUEST_CHANGES` (adopt the stricter)
   - TeamAgent Debate left `critical` / `major` equivalent disagreement → `REQUEST_CHANGES`
   - Spec source of truth / Plans.md / regression gate fails → `REQUEST_CHANGES`
   - `critical_issues`: merge both lists (no deduplication)
   - `major_issues`: merge both lists (no deduplication)
   - `recommendations`: merge with deduplication

## Output format

Add `dual_review` field to the normal `review-result.v1` schema:

```json
{
  "schema_version": "review-result.v1",
  "verdict": "APPROVE | REQUEST_CHANGES",
  "dual_review": {
    "claude_verdict": "APPROVE | REQUEST_CHANGES",
    "codex_verdict": "APPROVE | REQUEST_CHANGES | unavailable | timeout",
    "merged_verdict": "APPROVE | REQUEST_CHANGES",
    "divergence_notes": "Reason when verdicts diverge. Example: Claude detected major in Performance, Codex found no issue"
  },
  "acceptance_bar": {
    "critical_major_zero": true,
    "spec_alignment": "pass | fail | not_applicable",
    "plans_alignment": "pass | fail | not_applicable",
    "regression_safety": "pass | fail | not_applicable",
    "verification_evidence": "pass | fail | not_applicable"
  },
  "team_debate": {
    "required": true,
    "mode": "native | codex-companion | manual-pass | unavailable",
    "agents": ["Spec Agent", "Plans Agent", "Regression Agent"],
    "disagreements": []
  },
  "critical_issues": [],
  "major_issues": [],
  "observations": [],
  "recommendations": []
}
```

### Special values for `codex_verdict`

| Value | Meaning |
|-------|---------|
| `"unavailable"` | Codex CLI not installed or unavailable |
| `"timeout"` | Codex review timed out (no response within 120 seconds) |

## Fallback

- **Codex unavailable**: Run with Claude only and record `codex_verdict: "unavailable"`
- **Codex timeout**: Adopt Claude verdict as-is and record `codex_verdict: "timeout"`
- **Codex review output invalid**: Treat as parse failure and record `codex_verdict: "unavailable"`
- **TeamAgent unavailable**: Record `team_debate.mode: "unavailable"` with reason; perform at minimum Spec / Plans / Regression manual-pass

Even when Codex is unavailable/timeout, do not skip spec source of truth / Plans.md / regression pass thresholds.
When TeamAgent is unavailable and manual-pass is also impossible, stop as `decision_needed` rather than `REQUEST_CHANGES`.

## Writing divergence_notes

When verdicts match (`claude_verdict == codex_verdict`), set `divergence_notes` to empty string.

When verdicts diverge, record in this format:

```
Claude: REQUEST_CHANGES (Security - SQL injection risk)
Codex: APPROVE (No issue found at same location)
Adopted: REQUEST_CHANGES (Adopt the stricter)
```
