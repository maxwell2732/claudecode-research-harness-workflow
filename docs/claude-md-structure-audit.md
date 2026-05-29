# CLAUDE.md Structure Audit — Phase 47.1.1 Investigation Report

Investigation date: 2026-04-20
Target: `CLAUDE.md` v2026-04-19 (142 lines, after Phase 50.1.1 pointer addition)
Phase 47 goal: Measure session-start load cost → decide whether to split into `.claude/rules/`

## (a) Line count per section

Result of counting lines per `## H2` boundary using `awk`:

| # | Section | Line range | Lines |
|---|---------|-----------|-------|
| 1 | Project Overview | 5-10 | 6 |
| 2 | Claude Code Feature Utilization | 11-18 | 8 |
| 3 | Development Rules | 19-44 | **26** |
| 4 | Repository Structure | 45-48 | 4 |
| 5 | Using Skills (Important) | 49-66 | **18** |
| 6 | Development Flow | 67-74 | 8 |
| 7 | Testing | 75-83 | 9 |
| 8 | Notes | 84-90 | 7 |
| 9 | MCP Trust Policy | 91-98 | 8 |
| 10 | Permission Boundaries | 99-114 | **16** |
| 11 | Key Commands (for development) | 115-127 | 13 |
| 12 | SSOT (Single Source of Truth) | 128-132 | 5 |
| 13 | Test Tampering Prevention | 133-142 | 10 |
|   | (Header + blank lines) | 1-4 | 4 |
|   | **Total** | | **142** |

### Top 3 heaviest sections

1. **Development Rules (26 lines)**: 5 sub-sections (Commit / Version / CHANGELOG / Language / Code Style)
2. **Using Skills (18 lines)**: Top Skill Categories table (5 lines) + trigger description
3. **Permission Boundaries (16 lines)**: guardrail 7-line table + description

No section exceeds 30 lines. 142 lines total is ~3.5KB (~1–2% of entire session-start context).

## (b) Enumeration of split candidates

Candidates for moving to `.claude/rules/`:

| Candidate | Current location | Proposed split target | Benefit | Concern |
|-----------|-----------------|----------------------|---------|---------|
| **MCP Trust Policy** | CLAUDE.md 91-98 (8 lines) | `.claude/rules/mcp-trust-policy.md` | Consistent with existing `codex-cli-only.md`; external MCP addition procedures managed independently | 8 lines; limited split value |
| **Permission Boundaries** | CLAUDE.md 99-114 (16 lines) | `.claude/rules/permission-boundaries.md` | Linked with settings.json deny; table easily extensible | Important info that should be read at every session-start |
| **Development Rules** | CLAUDE.md 19-44 (26 lines) | Bulk to `.claude/rules/development-rules.md` or distributed per sub-section | Reduces the heaviest section | CHANGELOG is already split to `github-release.md`; remainder is short |
| **Notes** | CLAUDE.md 84-90 (7 lines) | Delete or merge into Repository Structure | Section header + 4 items = high overhead | Too small to justify standalone split |

DoD (b) of listing 2+ candidates is met. However, the split decision is made in (d).

## (c) Investigation of `@` notation availability

### Investigation method

Checked existing use of `@path/to/file.md` pattern in repo using grep:

```bash
grep -rE '@[a-zA-Z0-9_/.-]+\.md' CLAUDE.md .claude/rules/*.md
# → 0 matches
```

Other uses:
- `.claude/worktrees/flamboyant-shannon/templates/*/commands/review-cc-work.md:83`: Used inside **prompt body** as `@Plans.md from...`
- `docs/constitution.md:99`: Self-reference in prose (not auto-include)

### Verdict

1. **Official spec for `@file.md` notation in CC 2.1.111+**: Claude Code CLAUDE.md is auto-included, but **no confirmed stable documented feature exists** for additional import via `@path/to/file.md` notation. It can be used as reference guidance inside prompt body, but with CLAUDE.md being auto-loaded in the current setup there is also a double-load risk.
2. **Existing operational record**: Not used inside CLAUDE.md. Pointers are always in markdown link format `[.claude/rules/xxx.md](path)`.
3. **Smoke test existence**: `tests/test-claude-md-auto-include.sh` does not exist. This is a CC version compatibility issue, not a target for feature smoke testing.

**Conclusion**: `@` notation has **no guarantee of stable behavior**. The current pointer approach (standard markdown links + assistant reads via `Read` when needed at session-start) is safest.

## (d) Final verdict and rationale

### Verdict: **Maintain current state (do not split)**

### Rationale

1. **Quantitative data**: 142 lines / max 26-line section is lightweight from CC's session-start context perspective. No token pressure without splitting.
2. **Safety of pointer approach**: Current CLAUDE.md is already designed with a "concise overview + detailed pointer" pattern (CHANGELOG → `github-release.md`, skill catalog → `docs/CLAUDE-skill-catalog.md`, feature table → `docs/CLAUDE-feature-table.md`). Detailed information is already externalized; what remains in CLAUDE.md is the "overview and index that must always be referenced at session-start."
3. **Uncertainty of `@` notation**: No guarantee that `@` notation will be promoted to auto-include in CC 2.1.111+. Current pointers (regular links) work by letting the assistant follow them via Read when needed. Migration to `@` has more divergence risk than gain.
4. **Subjective cost of splitting**: Moving sections to `.claude/rules/` distributes the source-of-truth to 2 locations. Loses the benefit of being able to see the entire Harness-specific operational overview in one CLAUDE.md read.
5. **Hook warning handling**: A warning mechanism for PostToolUse hooks triggering at 130+ lines has been in place since around v4.3.1, but this means "reconsider when approaching 150 lines," not "split immediately." The +1 line added in Phase 50.1.1 was a minimal necessary pointer addition — intentional.

### Future split triggers (future action rules)

- **Trigger A**: If any single section exceeds 30 lines, consider splitting only that section
- **Trigger B**: If CLAUDE.md total exceeds 180 lines, consider full restructuring
- **Trigger C**: If CC official documentation explicitly specifies `@` notation auto-include behavior, consider section rearrangement + bulk import via `@` notation

At the current point (142 lines, max 26 lines), none of Triggers A/B/C are met, so maintaining the current state is optimal.

## (e) Outcome of this Phase

This Phase is investigation only; **the structure of the main `CLAUDE.md` was not changed**.
The 1-line pointer addition by Phase 50.1.1 was executed as a separate task.

## Related files

- `CLAUDE.md` (investigation target, unchanged)
- 17 files under `.claude/rules/` (split destination candidates)
- `docs/CLAUDE-feature-table.md` (example already externalized)
- `docs/CLAUDE-skill-catalog.md` (example already externalized)
- `docs/CLAUDE-commands.md` (example already externalized)
