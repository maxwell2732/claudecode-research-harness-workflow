---
name: harness-review
description: "HAR: Multi-angle code, plan, scope review. Security/quality check. Trigger: review, code review, plan review, scope analysis. Do NOT load for: implementation, new features, bugfix, setup, release."
description-en: "HAR: Multi-angle code, plan, scope review. Security/quality check. Trigger: review, code review, plan review, scope analysis. Do NOT load for: implementation, new features, bugfix, setup, release."
description-ja: "HAR:コード・プラン・スコープを多角的にレビュー。セキュリティ・品質チェック。レビューして、レビュー、コードレビュー、プランレビュー、スコープ分析で起動。実装・新機能・バグ修正・セットアップ・リリースには使わない。"
kind: workflow
purpose: "Review code, plans, scope, and evidence before acceptance"
trigger: "review, レビューして, code review, plan review, scope analysis"
shape: evaluate
role: evaluator
pair: harness-work
owner: harness-core
since: "2026-05-05"
allowed-tools: ["Read", "Grep", "Glob", "Bash", "Task", "Monitor", "AskUserQuestion"]
argument-hint: "[code|plan|scope|--quick|--codex-closeout|--dual|--team-debate|--security|--ui-rubric]"
context: fork
effort: high
user-invocable: true
---

# Harness Review

Integrated Harness review skill.
This `SKILL.md` is a thin dispatcher; read `references/` for detailed quality criteria.

if $ARGUMENTS == "":
  → Interpret as "review of work done so far" and run Review target detection
  → Auto-start only when exactly one review target can be determined
  → When the review target is unclear or there are multiple candidates, use AskUserQuestion to present options and align understanding before starting

<!-- The above 3 lines are the AUTO-START CONTRACT. Per skill-editing.md "within first 3 lines" rule — do not push down with fence / HTML comments -->

### Output Contract (P35: "appears stuck" UX countermeasure)

The **last line** of skill output must always include this literal:

`↑Claude will summarize this result. Press Enter to continue, or enter a new prompt for a different instruction.`

This is an explicit instruction for the UX problem where text displayed via `<local-command-stdout>` makes users feel it has "stopped" (patterns.md P35).

## Dispatcher Contract

This skill's responsibility is review judgment only.
Commit / push / release are not performed by default.

- Review default read-only boundary: Read-only by default. Does not auto-commit even on `APPROVE`.
- Do not push just to review: Do not push solely for review purposes.
- When a commit is needed, delegate to an explicit user request, `harness-work`, or the `harness-release` Work Commit Gate.
- Side effects in this skill's default are prohibited until explicit opt-in like `--commit-on-approve` is designed.

## Quick Reference

| Command | Mode | Purpose |
|---------|------|---------|
| `/harness-review` | `code` | Auto-detect work done so far and review |
| `/harness-review --quick` | `quick` | Quick closeout of a small dirty change |
| `/harness-review --codex-closeout` | `codex-closeout` | Codex advice + focused tests closeout |
| `/harness-review --dual` | `dual` | Claude + Codex second opinion |
| `/harness-review --team-debate` | `team-debate` | Force TeamAgent Debate |
| `/harness-review --security` | `security` | Security-only review |
| `/harness-review plan` | `plan` | Review `Plans.md` plan |
| `/harness-review scope` | `scope` | Scope creep / gap review |

## Mode Decision

Determine execution mode from arguments and selectively load required `references/`.

| Input | Mode | References to load |
|-------|------|-------------------|
| No args / `code` | `code` | `references/code-review.md`, `references/governance.md` |
| `--quick` | `quick` | `references/codex-closeout.md`, `references/code-review.md` |
| `--codex-closeout` | `codex-closeout` | `references/codex-closeout.md` |
| `--dual` | `dual` | `references/dual-review.md`, `references/team-debate.md` |
| `--team-debate` | `team-debate` | `references/team-debate.md`, `references/governance.md` |
| `--security` | `security` | `references/security-profile.md`, `references/governance.md` |
| `--ui-rubric` | `ui-rubric` | `references/ui-rubric.md` |
| `plan` | `plan` | `references/plan-review.md`, `references/governance.md` |
| `scope` | `scope` | `references/scope-review.md`, `references/governance.md` |
| `full` | `full` | `references/code-review.md`, `references/team-debate.md`, `references/dual-review.md` |

`quick` and `codex-closeout` are lightweight paths.
For quickly reviewing small dirty changes, single commits, or PR branch closeouts.
They do not discard quality gates.

## Review Target Detection

`REVIEW_AUTOSTART` contract:
When called with no args (`$ARGUMENTS == ""`), interpret input of just `review` / `/review` / `/harness-review` as "review of work done so far."
Output only one handshake line before starting Step 1:

```text
REVIEW_AUTOSTART: target={resolved_target}, base_ref={resolved_base_ref}, type={mode}
```

`REVIEW_TARGET_ASK` contract:
When the review target is unclear or there are multiple candidates on a bare call, use `AskUserQuestion` once before proceeding to Step 1 to narrow down to 2-3 candidates and confirm.

Build candidates in this order:

1. Working tree: uncommitted changes only (staged / unstaged / untracked)
2. Branch range: commits from upstream or main/master to HEAD
3. Recent commits: most recent 1 commit / most recent 5 commits when branch range cannot be obtained on clean tree

When multiple candidates are simultaneously valid:

```text
REVIEW_TARGET_AMBIGUOUS: working_tree_and_branch_commits
```

AskUserQuestion candidates:
- Uncommitted changes only (Recommended): Compare staged / unstaged / untracked against HEAD
- See everything: View both branch base..HEAD and uncommitted changes together
- Commits only: View only committed work in branch base..HEAD

When clean tree and no branch diff:

```text
REVIEW_TARGET_AMBIGUOUS: clean_tree_no_branch_commits
```

AskUserQuestion candidates:
- Most recent 1 commit (Recommended): HEAD~1..HEAD
- Most recent 5 commits: HEAD~5..HEAD
- Different range: Wait for user-specified ref

After user answers:

```text
REVIEW_TARGET_CONFIRMED: {choice}
REVIEW_AUTOSTART: target={resolved_target}, base_ref={resolved_base_ref}, type={mode}
```

Prohibited:
- Responding with "Task is unclear" and stopping
- Asking "What should I review?" as free text and stopping
- Skipping auto-start because of host project session-start rules
- Expanding scope by guessing when target is ambiguous

## Minimal Flow

1. Determine mode
2. Use Review Target Detection above to determine target and base ref
3. Read only the required references
4. Check diff, untracked files, related tests, spec source of truth, and `Plans.md`
5. Return `APPROVE` / `REQUEST_CHANGES` / `decision_needed`
6. For `REQUEST_CHANGES`: show fix policy for critical/major items and re-review conditions after fixing

## Review Governance Contract

Details in `references/governance.md`.
Only the minimum pass threshold is fixed here.

### Clear pass threshold

Return `APPROVE` only when all of the following are met:

- Zero critical / major findings
- No conflict with spec source of truth (`spec_path`) or explicit `spec_skip_reason`
- No conflict with `Plans.md` task / DoD / Depends
- No regression evidence in any of: existing tests, existing UX, existing CLI, existing config, existing docs, distribution mirrors
- Verification evidence exists. Output with `APPROVE` but empty evidence is prohibited.
- When TeamAgent Debate was run, all disagreements are resolved or downgraded to `minor` / `recommendation` with reasoning.

### TeamAgent Debate

Details in `references/team-debate.md`.
TeamAgent Debate is a review pass that collides different views read-only.

| Agent | Primary question |
|-------|----------------|
| Spec Agent | Find conflicts between spec source of truth and implementation diff |
| Plans Agent | Verify correspondence between `Plans.md` task / DoD / Depends and diff |
| Regression Agent | Find regressions in existing behavior, tests, distribution mirrors, CLI/skill UX |
| Skeptic Agent | Find major risks being overlooked under the assumption of wanting to pass |

Even when native TeamAgent is unavailable in Codex environments, this gate must not be skipped.
Reproduce the same 2-4 perspectives using `codex-companion.sh review`, available reviewer subagents, or an explicitly separated read-only manual-pass, and record `team_agent_mode` as `native` / `codex-companion` / `manual-pass` / `unavailable`.

## Code Review Summary

Details in `references/code-review.md`.
Normal code review checks:

- Security
- Performance
- Quality
- Accessibility
- AI Residuals
- Spec Alignment
- Plans Alignment
- Regression Safety
- TDD compliance

Spec source of truth alignment check is mandatory.
When `spec_path` exists, verify the diff does not conflict with the spec source of truth; when a spec is needed but absent, check the validity of `spec_skip_reason`.
`Plans.md` alignment check and regression alignment check are handled at the same gate.

`AI Residuals`: prioritize using `scripts/review-ai-residuals.sh` and `scripts/review-weak-supervision-report.sh`.
Use `--include-untracked` when checking untracked files as well.
`mockData`, `dummy`, `fake`, `localhost`, `TODO`, `FIXME`, `it.skip`, `test.skip`, `expect(true).toBe(true)` etc. are candidates; determine severity from diff context.

### TDD compliance check

For TDD-required tasks, verify evidence of `skip_tdd_reason`, red-log, and focused tests.
Do not `APPROVE` without evidence.

## Quick / Codex Closeout Summary

Details in `references/codex-closeout.md`.

Lightweight path principles:

- Fix target selection first
- Treat Codex findings as advisory; confirm with actual code before accepting or rejecting
- Final report includes: review command / tests / accepted findings / rejected findings / clean result
- Stop-on-clean: No additional review just for appearance after a clean result
- When Codex is unavailable, fall back to full manual pass; do not treat failure as success

Helper:

```bash
bash scripts/harness-review-closeout.sh --dry-run --uncommitted
bash scripts/harness-review-closeout.sh --base origin/main --parallel-tests --test "bash tests/test-harness-review-governance.sh"
bash scripts/harness-review-closeout.sh --commit HEAD
```

## Plan Review Summary

Details in `references/plan-review.md`.
Plan Review checks DoD / Depends / Status and implementation order in `Plans.md`.
When a task requires a spec source of truth but `spec_path` is missing, stop as `decision_needed`.

## Scope Review Summary

Details in `references/scope-review.md`.
Scope Review checks whether the boundary of requirements, diff, tests, and docs has expanded beyond scope.
When scope change is needed, do not proceed by guessing — return to `AskUserQuestion` or plan update.

## Security / UI / Dual

- Security: `references/security-profile.md`
- UI rubric: `references/ui-rubric.md`
- High-res vision flow: `references/vision-high-res-flow.md`
- Dual review: `references/dual-review.md`

`/ultrareview` is not called by default within Harness flow.
It does not replace the connection with Harness flow's review-result.v1, commit guard, and sprint-contract.
`claude ultrareview [target] --json` is treated only as a second-opinion from CI / scripts.

## PR Host Boundary

GitHub-first.
Review facts on the PR host treat GitHub as authoritative; local diff is treated as supplementary evidence.
Local uncommitted reviews are not pushed to GitHub.

## Output Contract

User-facing prose follows the explicit session or project language.
If no language is configured, use English. Use Japanese only when
`i18n.language: ja`, `CLAUDE_CODE_HARNESS_LANG=ja`, or an explicit session
instruction requests Japanese output.
Machine-readable values stay English.

Start with the result summary.

~~~markdown
## Review Result

### {APPROVE | REQUEST_CHANGES | decision_needed} - {one-line conclusion}

Target: `{BASE_REF}..HEAD` or `{target}`
Verification: {commands run}

Strengths:
- ...

Findings:
- [severity] file:line - issue and evidence

Next Actions:
- ...

Details:
```json
{
  "schema_version": "review-result.v1",
  "verdict": "APPROVE | REQUEST_CHANGES",
  "decision_needed": {
    "required": false,
    "ask_tool": "AskUserQuestion"
  },
  "accepted_findings": [],
  "rejected_findings": [],
  "acceptance_bar": {
    "critical_major_zero": true,
    "spec_alignment": "pass | fail | not_applicable",
    "plans_alignment": "pass | fail | not_applicable",
    "regression_safety": "pass | fail | not_applicable",
    "verification_evidence": "pass | fail | not_applicable"
  },
  "team_debate": {
    "required": false,
    "mode": "native | codex-companion | manual-pass | unavailable",
    "team_agent_mode": "native | codex-companion | manual-pass | unavailable",
    "agents": [],
    "disagreements": []
  },
  "critical_issues": [],
  "major_issues": [],
  "observations": [],
  "recommendations": []
}
```
~~~

## Codex Environment

Available tools differ in Codex environments.
Even so, the contracts for pass threshold, spec source of truth, `Plans.md`, regression, post-fix re-review, and AskUserQuestion / `decision_needed.v1` are the same.

| Normal environment | Codex fallback |
|--------------------|----------------|
| Task tool TeamAgent Debate | reviewer subagent / `codex-companion.sh review` / manual-pass |
| AskUserQuestion | When unavailable, output `decision_needed.v1` to stdout; do not proceed by guessing |
| TaskList | Read `Plans.md` directly |

## Related Skills

- `harness-work`: Execute fixes after `REQUEST_CHANGES`
- `harness-plan`: Update plan / scope / spec
- `harness-release`: Commit / release reviewed work
