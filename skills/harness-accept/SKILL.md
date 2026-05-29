---
name: harness-accept
description: "Generate an Acceptance Demo HTML for non-engineer vibecoders right before ship/wait/reject decision. Reads back the acceptance_criteria that were stored as personal-preference.v1 by harness-plan-brief (joined by user_request_hash), then renders a single-file HTML showing each criterion as verified or unverified along with a ship/wait/reject recommendation. Use when the user asks for an acceptance review, wants to decide whether to ship a delivered task, or says: acceptance demo, accept demo, acceptance decision, acceptance review, ship/wait/reject decision, acceptance inspection. Do NOT load for: implementation, code review, release work."
description-en: "Generate an Acceptance Demo HTML for non-engineer vibecoders right before ship/wait/reject decision. Reads back the acceptance_criteria that were stored as personal-preference.v1 by harness-plan-brief (joined by user_request_hash), then renders a single-file HTML showing each criterion as verified or unverified along with a ship/wait/reject recommendation. Use when the user asks for an acceptance review, wants to decide whether to ship a delivered task, or says: acceptance demo, accept demo, acceptance decision, acceptance review, ship/wait/reject decision, acceptance inspection. Do NOT load for: implementation, code review, release work."
allowed-tools: ["Read", "Write", "Edit", "Bash"]
argument-hint: "[task-description]"
user-invocable: true
---

# harness-accept

A skill for non-engineer clients and producers that presents the acceptance decision (ship / wait / reject) for a completed implementation task as a **single HTML page**.
Used at cognitive load peak (3): the acceptance decision stage.

Operates as the counterpart structure to Phase 65.1.x (`harness-plan-brief`), reading back the `acceptance_criteria` approved in the Plan Brief for evaluation.

## Quick Reference

- "**Create an Acceptance Demo**" → this skill
- "**I want to make an acceptance decision**" → this skill
- "**ship/wait/reject decision**" → this skill

## Responsibility Boundaries

| Scope | This skill's responsibility |
|------|-----------------|
| Search | **Current project only** (always specify `project: <current>`, `strict_project: true`) |
| Cross-project | **Not performed** (opt-in via `--cross-project-group <name>` flag from Phase 65.3 onward) |
| Plan Brief integration | Read `personal-preference.v1` (Phase 65.1.4) using `user_request_hash` as join key |
| Write | Not performed (memory write after acceptance approval is the responsibility of `accept-record-decision.sh`) |
| Recommendation calculation | Threshold judgment at 0.8 / 0.5 based on verified / total criteria ratio. Logic calculated just before `scripts/render-html.sh` |

## Input

Pass the user's request as the `[task-description]` argument (use the same text as during Plan Brief).
If no argument is provided, accept interactively.

## Output

| Output | Path | Format |
|------|------|------|
| Acceptance Demo HTML | `.claude/state/views/accept-<timestamp>.html` | Self-contained HTML (no server, no JS framework) |
| Acceptance context JSON | `.claude/state/views/accept-<timestamp>.context.json` | `acceptance-context.v1` schema |

## Schema: `acceptance-context.v1`

```json
{
  "schema": "acceptance-context.v1",
  "user_request": "string",
  "user_request_hash": "sha256 hex (join key with personal-preference.v1 on the Plan Brief side)",
  "demo_artifacts": [
    { "kind": "video|screenshot|text", "path": "string" }
  ],
  "verified_criteria": [
    { "name": "string", "passed": true, "evidence": "string" }
  ],
  "tdd_verified": "yes|no|not-required|skip:<reason>",
  "unverified_caveats": ["string"],
  "past_issue_patterns": [
    { "pattern_id": "P5", "title": "string", "verified_in_current_task": true }
  ],
  "recommendation": "ship|wait|reject",
  "recommendation_evidence": ["string"],
  "project": "string",
  "generated_at": "ISO8601"
}
```

Full schema: see [`schemas/acceptance-context.v1.schema.json`](${CLAUDE_SKILL_DIR}/schemas/acceptance-context.v1.schema.json).

## Recommendation Calculation Logic

```
verified_count    = count of verified_criteria where passed=true
total_criteria    = count of verified_criteria
ratio             = verified_count / total_criteria  (0 when total=0)

  ratio >= 0.8 → "ship"
  ratio >= 0.5 → "wait"
  ratio <  0.5 → "reject"
  total = 0    → "reject" (0 criteria means unable to judge; default to safe side reject)
```

Record the evaluation basis with literal numbers in `recommendation_evidence`.
Example: `"verified 4 / total 5 (80%) → above ship threshold"`

## Execution Flow

When the skill is invoked, Claude operates in the following steps.

### Step 1: Resolve project name and user_request_hash

```bash
PROJECT_NAME="$(basename "$(git rev-parse --show-toplevel)")"
USER_REQUEST_HASH="$(printf '%s' "$USER_REQUEST" | sha256sum | awk '{print $1}')"
```

Use `current` as the default if `PROJECT_NAME` is empty (outside git).

### Step 2: Search harness-mem **project-only** and retrieve Plan Brief record (default)

When the `--cross-project-group <name>` flag is **absent** (default behavior):

Call `mcp__harness__harness_mem_search` with the following parameters:

```
project: <PROJECT_NAME>
strict_project: true
tags: ["personal-preference", "plan-brief-approval"]
limit: 10
```

> **Important**: The `project` parameter is **required**. Specify `strict_project: true` and **never** perform cross-project searches.

Filter the retrieved records by `data.user_request_hash == <USER_REQUEST_HASH>` and select the most recent one.
This record holds the approval content from Plan Brief time (chosen_option / acceptance_criteria, etc.).

### Step 2 (alt): cross-project search (Phase 65.3.5 opt-in)

Only when the `--cross-project-group <name>` flag is **present**, retrieve similar plan-brief-approval / acceptance-decision history from other projects within the cross-project group (D43 Option α):

```bash
MEMBERS_JSON="$(bash scripts/load-cross-project-groups.sh --group "<name>" 2>/dev/null)" || {
  echo "ERROR: cross-project group not found: <name>" >&2
  exit 1
}
```

If `MEMBERS_JSON` is `[]`, fall back to default single project search.

If `MEMBERS_JSON` is non-empty, issue one MCP search per member project:

```
for each project in MEMBERS_JSON:
  mcp__harness__harness_mem_search(
    project: <member>,
    strict_project: true,
    tags: ["personal-preference", "plan-brief-approval"],
    limit: 10
  )
```

Merge results on the client side, filter by `data.user_request_hash == <USER_REQUEST_HASH>`.
Hash matches are generally from the same user request so duplicates across projects are rare, but dedupe by id to be safe.

When adopting a cross-project record, chosen_option / acceptance_criteria from other past projects may be mixed in, so **always use the `--with-redaction` flag** when generating HTML output:

```bash
bash scripts/render-html.sh --template accept ... --with-redaction
```

For details, see "Phase 65.3 Implementation Decisions (D43)" in `.claude/rules/cross-repo-handoff.md`.

### Step 3: Retrieve past issue patterns (delegated to Phase 65.2.2)

```bash
bash scripts/accept-past-issues.sh --project "$PROJECT_NAME" --task "$USER_REQUEST" > "$PAST_ISSUES_JSON"
```

This script semantically searches patterns.md (P1-P33) and past `acceptance-context.v1` records, returning up to 3 `past-issue.v1` entries, each with `verified_in_current_task: bool`.

### Step 4: Build verified_criteria

For each item in the acceptance_criteria from Plan Brief time, evaluate the current task's state.
The user (or Claude) presents "verified evidence" and fills in the `evidence` string.

If `evidence` is an empty string, a warning is shown in the HTML (DoD c).

For tasks where TDD is required, the Acceptance Demo must include a `TDD verified: yes|no` line.
For cases where TDD is not required or is skipped, display `TDD verified: not-required` or `TDD verified: skip:<reason>`.
`yes` can only be set when Red evidence in `.claude/state/tdd-red-log/<task-id>.jsonl` or literal failing test output can be confirmed.

### Step 5: Calculate recommendation

Determine ship / wait / reject according to the "Recommendation Calculation Logic" above.

### Step 6: Generate HTML

Call `scripts/render-html.sh` (Phase 65.1.1) with `templates/html/accept.html.template`:

```bash
bash scripts/render-html.sh \
  --template accept \
  --data "$CONTEXT_JSON" \
  --out "$HTML_OUT"
```

### Step 7: Auto-open in browser

Reuse `scripts/plan-brief-open.sh` (the **general-purpose OS dispatcher** introduced in Phase 65.1.2):

```bash
bash scripts/plan-brief-open.sh "$HTML_OUT"
```

> **Note**: The script name contains "plan-brief", but it is actually a kind-neutral OS browser open dispatcher.
> It was named this because it was introduced first in Phase 65.1.2. It is also reused for other purposes such as Layer 3 (final HTML pre-scan).
> When the `BROWSER=true` env is set (CI environment), opening is **skipped** and only the path is output via `printf`.

### Step 8: Wait for user decision

Confirm whether to accept the ship / wait / reject recommendation or override it.
Memory write after the decision is the responsibility of a separate skill (`accept-record-decision.sh`, Phase 65.2.3).

## Failure Behavior

| Failure | Behavior |
|------|------|
| `mcp__harness__harness_mem_search` unreachable | Show warning and continue with `verified_criteria` as empty array (recommendation = reject) |
| Plan Brief record not found | Show warning and continue with `verified_criteria` as empty array |
| `git rev-parse --show-toplevel` fails | Continue with `PROJECT_NAME=current` |
| `accept-past-issues.sh` fails | Continue with `past_issue_patterns: []` (best-effort) |
| `render-html.sh` fails | Output error to stderr and exit 1 |

## Related

- `harness-plan-brief` (Phase 65.1.2) — Counterpart skill for the planning stage. This skill reads back `personal-preference.v1` from Plan Brief time, joining via `user_request_hash`
- `scripts/accept-past-issues.sh` (Phase 65.2.2) — Past issue pattern retrieval (read side)
- `scripts/accept-record-decision.sh` (Phase 65.2.3) — Approval memory write (`acceptance-decision.v1`)
- `scripts/render-html.sh` (Phase 65.1.1) — HTML template engine
- `scripts/plan-brief-open.sh` (Phase 65.1.2) — General-purpose OS browser dispatcher
- `harness-progress` skill (Phase 65.4.1) — Progress management skill (middle of the 3 surfaces)
