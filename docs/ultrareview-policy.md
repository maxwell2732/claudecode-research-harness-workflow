# `/ultrareview` and `/harness-review` Integration Policy

Policy document finalized in Phase 44.8.1.

---

## 1. `/ultrareview` behavior

`/ultrareview` is a **built-in slash command** added in Claude Code 2.1.111.
Since Claude Code 2.1.120, `claude ultrareview [target] --json` is also available for use from CI or scripts.

| Attribute | Details |
|-----------|---------|
| Session type | Single-turn dedicated review session |
| Executor | CC native (outside Harness agents) |
| Input | Current working tree diff (auto-collected) |
| Output | Inline natural-language review result |
| Output schema | Undefined (CC internal format) |
| CLI entry point | `claude ultrareview [target] --json` (for CI / ad-hoc second opinion) |
| Plans.md integration | None |
| sprint-contract verification | None |
| Codex adversarial review | None |
| Reviewer agent invocation | None |

`/ultrareview` is the entry point for "users requesting an ad-hoc review directly from CC."
It operates outside the Harness automation flow (Plan → Work → Review).
`claude ultrareview [target] --json` serves the same role — a CLI entry for supplementary CI calls — and is not a substitute for `/harness-review`.

---

## 2. Differences from `/harness-review`

| Aspect | `/ultrareview` | `/harness-review` |
|--------|----------------|-------------------|
| Executor | CC native | Harness skill (context: fork) |
| Session | Single-turn | Multi-step (Steps 0–4) |
| Plans.md integration | None | Yes (cc:WIP check, cc:done update) |
| sprint-contract verification | None | Yes (`.claude/state/contracts/<task>.sprint-contract.json`) |
| Codex adversarial review | None | Yes (with `--dual` flag) |
| Reviewer agent | None | Yes (`reviewer` agent, `review-result.v1` output) |
| Output schema | Undefined | `review-result.v1` (machine-readable JSON) |
| AI Residuals scan | None | Yes (`scripts/review-ai-residuals.sh`) |
| Fix loop | None | Yes (up to 3 iterations on REQUEST_CHANGES) |
| Security-only mode | None | Yes (`--security`, OWASP Top 10) |
| UI Rubric mode | None | Yes (`--ui-rubric`, 4-axis scoring) |
| Target user | Direct user invocation | Lead / breezing flow automation |

### 2.1 Role of `claude ultrareview [target] --json`

`claude ultrareview [target] --json` is a CLI entry point for calling CC-native ad-hoc reviews from non-interactive CI or local scripts.

Harness treats it as follows:

| Use case | Decision |
|----------|----------|
| Supplementary review in PR CI | Allowed. Treat as second opinion |
| Substitute for `/harness-review --dual` | Not allowed. Does not replace Codex adversarial review and `review-result.v1` |
| Verdict for REQUEST_CHANGES fix loop | Not allowed. Output schema is not the Harness contract |
| Quick scan of a large local diff | Allowed. Treat as ad-hoc review |

---

## 3. Confirmed policy: **(B) Prioritize `/harness-review` — do not call `/ultrareview` inside Harness flow**

### 3.1 Rationale

**Alignment with Rule 5**: `.claude/rules/opus-4-7-prompt-audit.md` states:
"`/ultrareview` is the review entry point for the caller. On the agent definition side, `review-result.v1` is the contract."
The Harness Reviewer agent and harness-review skill use `review-result.v1` as the output contract.
Calling `/ultrareview` internally would lose the machine-readable guarantee of `review-result.v1`.

**Schema mismatch**: `/ultrareview` output is in CC internal format and does not include the `verdict`, `critical_issues`, or `major_issues` fields of `review-result.v1`.
The Harness fix loop, commit guard, and sprint-contract verification all depend on `review-result.v1`; there is no benefit that justifies the schema-conversion overhead.

**Separation of concerns**: `/ultrareview` is the entry point for users requesting ad-hoc reviews directly from CC.
Automated reviews inside the Harness flow are covered by the `reviewer` agent (`review-result.v1`) and `codex-companion.sh review`. The two serve different purposes and can coexist.

**Fallback safety**: When `codex-companion.sh review` is unavailable, fall back to the `reviewer` agent (static / runtime / browser profile).
Adding `/ultrareview` as another fallback path increases debug complexity.

### 3.2 Usage guide

| Scenario | Recommended command |
|----------|---------------------|
| Pre-merge comprehensive check (outside Harness) | `/ultrareview` |
| Supplementary second opinion in CI | `claude ultrareview [target] --json` |
| Automated review after Harness Plan→Work | `/harness-review` (auto-called) |
| Review with Codex second opinion | `/harness-review --dual` |
| Security-focused audit | `/harness-review --security` |
| UI quality scoring | `/harness-review --ui-rubric` |

---

## 4. Future actions

- Re-evaluate `/ultrareview` as it matures as a CC built-in (next evaluation phase: 45+)
- Calling `/ultrareview` inside Harness is contingent on a schema-conversion layer to `review-result.v1` being implemented in `scripts/codex-companion.sh` (not yet implemented)
- Policy changes happen simultaneously with revisions to Rule 5 in `.claude/rules/opus-4-7-prompt-audit.md`

---

*Decision: Phase 44.8.1 / 2026-04-18*
