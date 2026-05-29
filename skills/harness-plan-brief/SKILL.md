---
name: harness-plan-brief
description: "Generate a Plan Brief HTML for non-engineer vibecoders before implementation starts. Searches harness-mem (project-only) for relevant past decisions, patterns, and Plans archive entries, then renders a single-file HTML artifact summarizing understanding, options, risks, acceptance criteria, and confidence. Use when the user requests a planning preview, a non-engineer-friendly summary before approval, or says: plan brief, planning preview, planning overview, plan review. Do NOT load for: actual implementation, code review, release work."
description-en: "Generate a Plan Brief HTML for non-engineer vibecoders before implementation starts. Searches harness-mem (project-only) for relevant past decisions, patterns, and Plans archive entries, then renders a single-file HTML artifact summarizing understanding, options, risks, acceptance criteria, and confidence. Use when the user requests a planning preview, a non-engineer-friendly summary before approval, or says: plan brief, planning preview, planning overview, plan review. Do NOT load for: actual implementation, code review, release work."
allowed-tools: ["Read", "Write", "Edit", "Bash"]
argument-hint: "[task-description]"
user-invocable: true
---

# harness-plan-brief

A skill for non-engineer clients and producers that presents Claude's plan for an upcoming task as a **single HTML page**.
Used at cognitive load peak (1): the plan comprehension stage.

## Quick Reference

- "**Create a Plan Brief**" → this skill
- "**Give me a rough overview before implementation**" → this skill
- "**Show the plan in a non-engineer-friendly way**" → this skill

## Responsibility Boundaries

| Scope | This skill's responsibility |
|------|-----------------|
| Search | **Current project only** (always specify `project: <current>`, `strict_project: true`) |
| Cross-project | **Not performed** (opt-in via `--cross-project-group <name>` flag from Phase 65.3 onward) |
| Write | Not performed (memory write after Plan Brief approval is the responsibility of `plan-brief-record-decision.sh`) |
| Confidence calculation | Delegated to `scripts/plan-brief-compile.sh` implemented in 65.1.3 |

## Input

Pass the user's request as the `[task-description]` argument.
If no argument is provided, accept interactively.

## Output

| Output | Path | Format |
|------|------|------|
| Plan Brief HTML | `.claude/state/views/plan-brief-<timestamp>.html` | Self-contained HTML (no server, no JS framework) |
| Plan Brief context JSON | `.claude/state/views/plan-brief-<timestamp>.context.json` | `plan-brief-context.v1` schema |

## Schema: `plan-brief-context.v1`

```json
{
  "schema": "plan-brief-context.v1",
  "user_request": "string (original user request text)",
  "my_understanding": "string (Claude's understanding in 1-3 paragraphs)",
  "options": [
    { "name": "string", "summary": "string", "pros": ["string"], "cons": ["string"] }
  ],
  "risks": [
    { "kind": "string", "severity": "info|warn|critical", "description": "string", "mitigation": "string" }
  ],
  "acceptance_criteria": [
    { "id": "string", "description": "string", "verifiable_by": "string" }
  ],
  "tdd_required": "yes|no|skip:<reason>",
  "confidence": 0,
  "confidence_evidence": ["string"],
  "related_decisions": [
    { "id": "string", "title": "string", "relevance": "string" }
  ],
  "similar_past_plans": [
    { "archive_path": "string", "phase": "string", "outcome": "cc:done|cc:WIP|cc:TODO|skipped", "relevance": "string" }
  ],
  "project": "string",
  "generated_at": "ISO8601"
}
```

Full schema: see [`schemas/plan-brief-context.v1.schema.json`](${CLAUDE_SKILL_DIR}/schemas/plan-brief-context.v1.schema.json).

## Execution Flow

When the skill is invoked, Claude operates in the following steps.

### Step 1: Resolve project name

```bash
PROJECT_NAME="$(basename "$(git rev-parse --show-toplevel)")"
```

Use `current` as the default if `PROJECT_NAME` is empty (outside git).

### Step 2: Search harness-mem **project-only** (default)

When the `--cross-project-group <name>` flag is **absent** (default behavior):

Call `mcp__harness__harness_mem_search` with the following parameters:

```
project: <PROJECT_NAME>
strict_project: true
query: <user request>
expand_links: true
limit: 5
```

> **Important**: The `project` parameter is **required**. Never pass an empty string or `null`.
> Specify `strict_project: true` and **never** perform cross-project searches.
> You may filter by `tags` for `decision` / `pattern`, but `project` is fixed.

Retrieve up to 5 similar cases from past decisions (D1-D41) / patterns (P1-P33) / 28 Plans archive entries.

### Step 2 (alt): cross-project search (Phase 65.3.5 opt-in)

Only when the `--cross-project-group <name>` flag is **present**:

Follow D43 Option α (MCP N-call) to perform cross-project search:

```bash
# (a) Resolve group → member projects (yaml SSOT)
MEMBERS_JSON="$(bash scripts/load-cross-project-groups.sh --group "<name>" 2>/dev/null)" || {
  echo "ERROR: cross-project group not found: <name>" >&2
  exit 1
}
# MEMBERS_JSON is a JSON array in ["proj1","proj2",...] format
```

If `MEMBERS_JSON` is `[]` (empty array), show a warning and fall back to default single project search.

If `MEMBERS_JSON` is non-empty, **issue one MCP search per member project**:

```
for each project in MEMBERS_JSON:
  mcp__harness__harness_mem_search(
    project: <member>,
    strict_project: true,
    query: <user request>,
    expand_links: true,
    limit: 5
  )
```

**Merge, dedupe (by id), and sort by relevance_score descending** on the client side, then narrow to a maximum of 5 entries.
Note that the total number of calls increases (e.g., 5 calls if the group has 5 projects), so latency will increase.

> **Basis for D43 Decision 1**: The MCP tool schema does not expose `projects: [array]` or `strict_project: false`, so client-side N-calls are the only option for cross-project search.
> For details, see "Phase 65.3 Implementation Decisions (D43)" in `.claude/rules/cross-repo-handoff.md`.

Cross-project results must pass through Layer 2/3 (Phase 65.3.2-65.3.4) redaction:
- Use `bash scripts/render-html.sh ... --with-redaction` when rendering HTML
- This ensures proper nouns do not leak through dictionary + NER + final scan (3 stages)

### Step 3: Build the context JSON

Use `scripts/plan-brief-compile.sh` (implemented in Phase 65.1.3) to construct JSON conforming to the `plan-brief-context.v1` schema from the mem search results.

Until 65.1.3 is implemented, Claude builds it directly with jq:

```bash
jq -n \
  --arg req "$USER_REQUEST" \
  --arg proj "$PROJECT_NAME" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    schema: "plan-brief-context.v1",
    user_request: $req,
    my_understanding: "(not yet started)",
    options: [],
    risks: [],
    acceptance_criteria: [],
    confidence: 0,
    confidence_evidence: ["(stub) calculation logic to be implemented in 65.1.3"],
    tdd_required: "no",
    related_decisions: [],
    similar_past_plans: [],
    project: $proj,
    generated_at: $ts
  }' > "$CONTEXT_JSON"
```

### Step 4: Generate HTML

Call `scripts/render-html.sh` (Phase 65.1.1) with `templates/html/plan-brief.html.template`:

Display the TDD judgment as a single line in the HTML.
The format must be one of: `tdd_required: yes`, `tdd_required: no`, or `tdd_required: skip:<reason>`.

```bash
bash scripts/render-html.sh \
  --template plan-brief \
  --data "$CONTEXT_JSON" \
  --out "$HTML_OUT"
```

### Step 5: Auto-open in browser

OS-specific dispatch via `scripts/plan-brief-open.sh`:

```bash
bash scripts/plan-brief-open.sh "$HTML_OUT"
```

When the `BROWSER=true` env is set (CI environment), opening is **skipped** and only the path is output via `printf`.

### Step 6: Wait for user approval

Confirm "Is it okay to proceed with implementation based on this understanding?"
Memory write after approval is the responsibility of a separate skill (`plan-brief-record-decision.sh` in Phase 65.1.4).

## Failure Behavior

| Failure | Behavior |
|------|------|
| `mcp__harness__harness_mem_search` unreachable | Show warning and continue with `related_decisions` / `similar_past_plans` as empty arrays |
| `git rev-parse --show-toplevel` fails | Continue with `PROJECT_NAME=current` |
| `render-html.sh` fails | Output error to stderr and exit 1 |
| `plan-brief-open.sh` fails | Only output HTML path to stdout and exit 0 (browser open is best-effort) |

## Related

- `scripts/render-html.sh` (Phase 65.1.1) — HTML template engine
- `scripts/plan-brief-compile.sh` (Phase 65.1.3) — context compilation
- `scripts/plan-brief-record-decision.sh` (Phase 65.1.4) — approval memory write
- `harness-accept` skill (Phase 65.2.1) — acceptance decision skill (counterpart structure)
- `harness-progress` skill (Phase 65.4.1) — progress management skill (counterpart structure)
