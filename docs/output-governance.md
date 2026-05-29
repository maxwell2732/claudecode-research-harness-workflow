# Output Governance Policy

Last updated: 2026-05-05

This document defines the safety policy for when hooks and auto-formatting processes handle Claude Code tool output.

## In a nutshell

Do not use `PostToolUse.hookSpecificOutput.updatedToolOutput` by default.
When used, limit to opt-in redaction / compaction / normalization; do not erase audit trails or review / test evidence.

## Analogy

Tool output is like security camera footage from a job site.
It may be summarized for clarity, but the parts that serve as evidence of an incident must not be cut out without authorization.

## Policy

| Item | Decision |
|------|----------|
| Default behavior | Do not return `updatedToolOutput` |
| Permitted uses | Explicit opt-in redaction, compaction, normalization |
| Prohibited uses | Concealing test failures, review findings, security findings, command errors |
| Audit trail | Preserve the original output location, transformation reason, and transformation rules |
| Output contract | stdout is a single JSON object. Explanatory logs go to stderr |

## Permitted transforms

### Redaction

Transforms to mask sensitive information.

Examples:
- Replace API key with `<REDACTED:api-key>`
- Replace access token with `<REDACTED:token>`
- Replace personal information with `<REDACTED:personal-data>`

Prohibited:
- Deleting entire error lines
- Removing failing test names
- Removing file:line from review findings

### Compaction

Transforms to shorten large output.

Examples:
- Fold duplicate lines in success logs
- Summarize dependency install logs of 1000+ lines
- Save full text to file and leave `full_output_path` at the end

Prohibited:
- Omitting failure summaries
- Removing both the beginning and end of a stack trace
- Removing failure locations from `pytest`, `vitest`, `go test`, `npm test`

### Normalization

Transforms to standardize display variation.

Examples:
- Replace absolute temp paths with stable placeholders
- Replace timestamps with `<TIMESTAMP>`
- Remove control characters from progress spinners

Prohibited:
- Changing the meaning of exit codes
- Making stderr appear as a success
- Replacing verdict words in review / test output

## JSON stdout contract

When a hook returns structured output to Claude Code, stdout must contain only JSON.
Human-readable logs go to stderr.

Minimum form:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse"
  }
}
```

When using `updatedToolOutput`:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "updatedToolOutput": "redacted or compacted tool output",
    "additionalContext": "Output was redacted with policy output-governance.v1. Full output is stored at .claude/state/audit/tool-output/<id>.log."
  }
}
```

Requirements:
1. Do not mix non-JSON into stdout.
2. When returning `updatedToolOutput`, confirm opt-in setting.
3. Save the full output or a recoverable audit record.
4. Leave transformation reason and transformation type in `additionalContext` or audit record.
5. Do not delete review / test evidence.

## Harness default

Harness does not use `updatedToolOutput` by default.
The reason is that shortening review or test rationale without authorization makes it impossible to later verify "was it actually failing?" and "what was fixed?"

Use only when needed, with explicit opt-in per hook:

```json
{
  "outputTransform": {
    "enabled": true,
    "mode": "redact",
    "auditTrail": true
  }
}
```

This setting name is a policy example; implementations need only have an equivalent opt-in.
The 3 critical points are: "no modification by default," "if modified, it's traceable," and "don't erase quality evidence."
