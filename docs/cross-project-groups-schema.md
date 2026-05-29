# cross-project-group.v1 Schema

Introduced in Phase 65.3 (Cross-Project Group + 3-Layer Redaction).
Schema specification for `.claude/rules/cross-project-groups.yaml`.

## Purpose

The SSOT group definition that allows client-side skills such as Plan Brief / Acceptance Demo / Progress Tracker to opt-in to **cross-project search**.

Cross-project search is disabled by default. Only when a group name is explicitly specified with the `--cross-project-group <name>` flag are `mcp__harness__harness_mem_search` calls issued to the member projects of that group.

## Schema

```yaml
schema_version: cross-project-group.v1

groups:
  - name: <string>            # group identifier
    description: <string?>    # optional (description of group purpose)
    members:                  # array, elements unique, empty OK
      - <string>              # member project name
      - <string>
```

## Constraints

| Field | Type | Required | Constraint |
|-------|------|----------|-----------|
| `schema_version` | string | ✓ | Fixed as `cross-project-group.v1` |
| `groups` | array | ✓ | Empty array `[]` is allowed |
| `groups[].name` | string | ✓ | Unique within `groups`; empty string not allowed |
| `groups[].description` | string | optional | Optional |
| `groups[].members` | array | ✓ | Array, elements unique, empty OK |
| `groups[].members[]` | string | - | Empty string not allowed; no duplicates |

## Validation

`scripts/load-cross-project-groups.sh` parses the yaml and stops with **exit 1** if an invalid schema is detected.

Detected errors:

1. `schema_version` mismatch (anything other than `cross-project-group.v1`)
2. `groups` is not an array
3. `groups[].name` missing / empty string / duplicate
4. `groups[].members` is not an array / duplicate elements / empty string
5. `groups[].members[]` is not a string

## Usage examples

### CLI (direct loader script call)

```bash
# Output all groups as JSON
bash scripts/load-cross-project-groups.sh

# Output members of a specific group as JSON array
bash scripts/load-cross-project-groups.sh --group "Personal Tools"
# → ["my-cli","my-dotfiles","my-scripts"]

# Non-existent group → exit 1
bash scripts/load-cross-project-groups.sh --group "Unknown"
# → stderr: "group not found: Unknown" / exit 1
```

### Via skill (planned for Phase 65.3.5)

```bash
# No cross-project search (default; current project only)
/harness-plan-brief "I want to introduce a new CI"

# Cross-project search opt-in (search all members of Personal Tools group)
/harness-plan-brief "I want to introduce a new CI" --cross-project-group "Personal Tools"
```

## Cross-Project Search Implementation (D43 Option α)

```
client skill (Plan Brief / Accept / Progress)
   │
   │ --cross-project-group <name>
   ▼
load-cross-project-groups.sh --group <name>
   │
   │ JSON array of member projects
   ▼
For each member in members:
   mcp__harness__harness_mem_search(project=member, ...)
   │
   ▼
Merge and dedupe on client side (by relevance_score)
   │
   ▼
Layer 2 (dict + NER) redact proper nouns
   │
   ▼
Layer 3 (final scan) check for residue → generate HTML if 0 found; exit 1 if found
```

For detailed responsibility boundaries, see "3-Layer Redaction Responsibility Boundary" and "Phase 65.3 Implementation Decisions (D43)" in [.claude/rules/cross-repo-handoff.md](../.claude/rules/cross-repo-handoff.md).

## Related

- `.claude/rules/cross-project-groups.yaml` — SSOT for this schema (default `groups: []`)
- `scripts/load-cross-project-groups.sh` — yaml → JSON parser + validator
- `tests/test-cross-project-groups-schema.sh` — 4-case automated verification
- `.claude/rules/cross-repo-handoff.md` — Phase 65.3 implementation decisions (D43)
- `.claude/rules/client-redaction.yaml` — Layer 2a dictionary (planned for Phase 65.3.2)
- Plans.md §65.3.1-65.3.7 — All Phase C tasks
