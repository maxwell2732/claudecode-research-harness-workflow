# Review Governance

## In a nutshell

Return `APPROVE` only when you can say with evidence that there are no critical problems.

## Clear pass threshold

Conditions for `APPROVE`:

- Zero critical / major findings
- No conflict with spec source of truth (`spec_path`) or `spec_skip_reason`
- No conflict with `Plans.md` task / DoD / Depends
- No regression evidence in existing behavior, existing tests, existing UX, existing CLI, existing config, existing docs, or distribution mirrors
- Evidence exists: verification commands, diff, file:line, test results, etc.
- No unresolved TeamAgent Debate disagreements

## Severity

| Severity | Meaning | Verdict |
|----------|---------|---------|
| critical | Secret exposure, data destruction, permission destruction, directly leads to release incidents | REQUEST_CHANGES |
| major | DoD not met, spec source of truth violation, clear regression, dangerous without tests | REQUEST_CHANGES |
| minor | Quality would improve but not severe enough to block shipping | APPROVE possible |
| recommendation | Optional improvement | APPROVE possible |

When only minor / recommendation, do not necessarily block.
If blocking, explain specifically why it is major.

## AskUserQuestion / decision_needed

Decisions that would break things if made by guessing should be `decision_needed`, not `REQUEST_CHANGES`.

Examples of `decision_needed`:

- Need to change the spec source of truth
- Need to change `Plans.md` DoD / Depends
- User needs to choose priority between security and UX
- Business decision needed on whether to keep or remove backward compatibility

Use AskUserQuestion when available.
When unavailable (e.g., in Codex environments), output `decision_needed.v1` to stdout and do not proceed by guessing.

## Side effects

Review default read-only boundary:

- Do not auto-commit even on `APPROVE`
- Do not push just to review
- commit / push / release are the responsibility of `harness-work` / `harness-release` / explicit user request

## Output evidence

Required:

- Target scope
- Review commands executed
- Tests executed
- Accepted findings
- Rejected findings
- Clean result or remaining issues
- Pass threshold for spec source of truth / Plans.md / regression

An `APPROVE` with empty evidence is invalid.
