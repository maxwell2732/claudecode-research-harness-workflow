# harness-review Operating Model

## In a nutshell

`harness-review` handles everything from lightweight closeout to heavy quality gates through a single entry point.
No separate lightweight skill is created.

## Analogy

Rather than adding a second reception desk at a hospital, use the same desk to route patients to "routine checkup," "detailed exam," or "emergency."
More entry points create confusion.
One entry point; choose the right examination depth inside.

## Why single entrypoint

| Decision | Reason |
|----------|--------|
| No separate skill | More discovery noise; both users and agents struggle to decide which to call |
| Make `harness-review` a dispatcher | Avoids contract drift; `APPROVE` meaning stays consistent across skills |
| Move governance to references | Reduces the burden of reading a long SKILL.md every time while preserving the quality gate |
| Read-only by default | If review proceeds all the way to commit/push, the responsibilities of the release/work flow break down |

## Mode table

| mode | When to use | Weight | Primary output |
|------|-------------|--------|----------------|
| `quick` | Closing a small uncommitted change | Light | accepted/rejected findings and focused tests |
| `codex-closeout` | Using Codex review as advice and verifying with actual code | Light | review command / tests / clean result |
| `code` | Normal implementation diff review | Medium | `APPROVE` / `REQUEST_CHANGES` |
| `plan` | Checking DoD / Depends / Status in `Plans.md` | Medium | Plan fix points |
| `scope` | Checking for over-scope, gaps, or unnecessary changes | Medium | Scope verdict |
| `security` | Checking risks around permissions, input, secrets, etc. | Heavy | OWASP Top 10 findings |
| `ui-rubric` | Scoring appearance, usability, and completeness | Medium | Design quality score |
| `full` | Final gate before release or for significant changes | Heavy | TeamAgent Debate + governance gate |

## Adopted from external codex-review

| Adopted item | Handling in harness-review |
|--------------|---------------------------|
| `advisory` | Codex findings are advisory. Adopt only after verifying with actual code, diff, and tests |
| `accepted/rejected` | Findings are split into accepted findings / rejected findings with reasons |
| `stop-on-clean` | No additional review just for appearance after a clean result |
| `target selection` | Fix the target (dirty / PR branch / branch range / single commit) at the start |
| `no push just to review` | Do not push just to review |
| `dirty tree handling` | Include uncommitted changes (including untracked) in review scope |

## Not adopted

| Not adopted | Reason |
|-------------|--------|
| Default auto-commit in review skill | Mixes review and work/release responsibilities |
| Separate skill for lightweight use | Increases discovery noise and contract drift |
| Auto-adoption of AI findings | Without code verification, false positives/negatives mix in |
| Additional review loop after clean | Uses time without improving quality |

## Side-effect boundary

`harness-review` is read-only by default.
`APPROVE` is a verdict that "the quality gate was passed," not an operational instruction to "commit."

Responsibility for commit / push / release:

| Operation | Owner |
|-----------|-------|
| Fix commit | `harness-work` or explicit user request |
| Release commit / tag / publish | `harness-release` |
| Review verdict | `harness-review` |
| Push | Explicit user request or release flow |

## Concrete example

Reviewing a small docs fix:

```bash
/harness-review --quick
bash scripts/harness-review-closeout.sh --dry-run --uncommitted
```

Running a heavy gate before release:

```bash
/harness-review full --team-debate --dual
```

## Why this approach

The current problem is not that quality standards are weak.
It is that the entry-point `SKILL.md` is too heavy — even for a lightweight closeout, it reads the full detailed-exam instructions every time.

So: don't cut the quality standards; just make the entry point lighter.
This allows fast handling in normal cases and deep inspection when it matters.
