# 3-Layer Defense for Cross-Project Search (Phase 65.3)

You want to draw on past decisions and insights from other projects, but **you don't want proper nouns mixed in** — client names, personal names, company names, etc.
This is a 3-layer system to redact (black out) proper nouns.

## Goal

By default, Claude Harness searches are **limited to the current project only** (safe by default).

However, when you want to pool insights from similar projects, you can enable cross-project search by specifying the `--cross-project-group <name>` flag.
At that point, the 3-layer system defends against **proper nouns from other projects leaking into the current project's HTML**.

## How to use

### Group definition (prerequisite)

List member projects in `.claude/rules/cross-project-groups.yaml`:

```yaml
schema_version: cross-project-group.v1
groups:
  - name: PersonalTools
    members:
      - my-cli
      - my-dotfiles
      - my-scripts
```

Details: [cross-project-groups-schema.md](cross-project-groups-schema.md)

### Enabling cross-project search

```bash
# Use cross-project search in Plan Brief
/harness-plan-brief --cross-project-group "PersonalTools"
```

Or the MCP N-call flow described in Step 2 (alt) of the skill's SKILL.md is applied automatically.

### How the 3-layer redaction works

When cross-project search is enabled, the following run automatically during HTML generation:

#### Layer 1: harness-mem server side (Cross-Contract, separate repo)

- Strip `<private>` blocks (always runs at server exit; cannot opt out)
- `strict_project: true` is the default (currently immutable via MCP; N-call support in Phase 65.3.5)
- Implementation: `harness-mem/memory-server/src/core/privacy-tags.ts`

#### Layer 2a: Dictionary-based proper noun redaction (client side)

- Literal string matching from the dict in `.claude/rules/client-redaction.yaml`
- Example: `ClientCorp` → `[Client_A]`, `Jane Doe` → `[Person_A]`
- Implementation: `scripts/redact-by-dictionary.sh` (PiiRule-compatible schema)

#### Layer 2b: NER (Named Entity Recognition) redaction (client side)

- Morphological analysis using Japanese tokenizer (fugashi + UniDic-lite)
- Tokens with pos2 == "proper noun" are replaced with `[Entity]`
- Consecutive proper noun tokens are merged into one `[Entity]`
- When tokenizer is absent: **fail-open** (original text + stderr warning)
- Implementation: `scripts/redact-by-ner.sh`

#### Layer 3: Final sanity scan (client side)

- Scans immediately before HTML generation, excluding template chrome (CSS/HTML comments)
- Detects runs of 5+ consecutive katakana characters as "residue"
- On detection: **HTML is not generated; exit 1** (fail-safe)
- Implementation: `scripts/render-html.sh --with-redaction` + `scripts/final-scan-redaction.py`

### Audit log

One line is appended to `.claude/state/audit/cross-project-search.jsonl` each time a cross-project search runs:

```json
{
  "schema_version": "cross-project-audit.v1",
  "timestamp": "2026-05-09T12:00:00Z",
  "group_name": "PersonalTools",
  "member_projects": ["my-cli", "my-dotfiles"],
  "query_hash": "<sha256 64 chars>",
  "redaction_count": {"dict": 2, "ner": 1},
  "output_passed_final_scan": true
}
```

The actual query string is **not recorded** (privacy); only the sha256 hash is stored.

Generated HTML shows "redacted: dict X items + NER Y items" at the bottom.

## Notes

### 1. Layer 1 is on the server side (separate repo); do not touch from claude-code-harness

As the boundary of the cross-repo handoff workflow (D42), Layer 1 is self-contained in harness-mem.
Even if you create new fixtures on the client side that include `<private>`, they will always be stripped when going through the server (cannot opt out).

### 2. NER tokenizer depends on opt-in installation

`scripts/redact-by-ner.sh` uses fugashi (Python tokenizer).
Installation status:
- Used automatically if present in the environment (check: `python3 -c "from fugashi import Tagger"`)
- If absent: fail-open (Layer 2a + Layer 3 only)

For complete NER coverage, run `pip install fugashi unidic-lite`.

### 3. Layer 3 final scan is fail-safe

If 5+ consecutive katakana characters are detected, **HTML is not generated; exit 1**.
Not generating is considered safer than "a leaked HTML being published."

Intentional branding by template authors (e.g., Japanese product name in CSS comment) is excluded from the scan (template chrome strip excludes `<!-- -->`, `/* */`, `<style>`, `<script>` from scan targets).

### 4. Double-replacement guard for existing server-side sentinel `[REDACTED_*]`

`[REDACTED_EMAIL]`, `[REDACTED_KEY]`, `[REDACTED_SECRET]`, `[REDACTED_HEX]` output by `event-recorder.ts:redactContent` on the mem side are handled in 3 steps (sentinel escape → redact → restore) so that client Layer 2 does not re-redact them.
Regex `[A-Za-z0-9_]+` handles both upper and lower case.

### 5. Cross-project default is OFF

Unless the `--cross-project-group` flag is specified, search is limited to the current project only (Phase 65.1.x behavior).
Cross-project search does not run without explicit opt-in.

### 6. Do not keep raw queries in audit log

Only `query_hash` (sha256, 64 chars hex) is recorded.
Since it is irreversible, actual query content is protected even in case of leakage.

## Related

- [cross-project-groups-schema.md](cross-project-groups-schema.md) — how to configure groups
- [cognitive-load-surfaces.md](cognitive-load-surfaces.md) — role of the 3 surfaces
- `.claude/rules/cross-repo-handoff.md` — D42 (claude-code-harness ↔ harness-mem boundary)
- `.claude/memory/decisions.md` D43 (design decisions for this feature, 4-decision package)

## Related scripts

| Script | Role |
|--------|------|
| `scripts/load-cross-project-groups.sh` | Reads yaml SSOT and resolves member projects |
| `scripts/redact-by-dictionary.sh` | Layer 2a dictionary redaction |
| `scripts/redact-by-ner.sh` | Layer 2b NER redaction |
| `scripts/final-scan-redaction.py` | Layer 3 final scan |
| `scripts/render-html.sh --with-redaction` | Applies 3 layers sequentially and generates HTML |
| `scripts/cross-project-audit-log.sh` | Appends to audit log |
