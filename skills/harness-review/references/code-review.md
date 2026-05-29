# Code Review Flow

## In a nutshell

Collect the diff, check implementation / spec / plans / regression / tests, and block only problems that need to be blocked.

## Step 1: collect diff

Check:

```bash
git status --short
git diff --stat "${BASE_REF:-HEAD}"
git diff "${BASE_REF:-HEAD}"
git ls-files --others --exclude-standard
```

Untracked files do not appear in `git diff`.
Always include them in scope.

## Step 2: static scans

AI Residuals:

```bash
bash scripts/review-ai-residuals.sh --base "${BASE_REF:-HEAD}"
bash scripts/review-weak-supervision-report.sh
```

Candidates:

- `mockData`
- `dummy`
- `fake`
- `localhost`
- `TODO`
- `FIXME`
- `it.skip`
- `describe.skip`
- `test.skip`
- `expect(true).toBe(true)`

Finding a candidate alone does not make it major.
Determine from diff context whether it "directly leads to a shipping incident or misconfiguration."

## Step 3: eight review lenses

| Lens | What to check |
|------|--------------|
| Security | SQL injection, cross-site scripting, secret leak, permission bypass |
| Performance | N+1, needless heavy IO, blocking work |
| Quality | Duplicate logic, unclear boundary, fragile parsing |
| Accessibility | Labels, focus, contrast, keyboard path |
| AI Residuals | Fake success, skipped tests, mock-only implementation |
| Spec Alignment | Conflicts with spec source of truth |
| Plans Alignment | Matches `Plans.md` task / DoD / Depends |
| Regression Safety | Regressions in existing behavior, mirrors, CLI/skill UX |

## TDD compliance

For tasks requiring TDD, check evidence that a failing test was confirmed before implementation.
However, for cases where TDD is excessive such as docs-only or refactor-only, recording the skip reason is sufficient.

## Verdict

1. critical / major exists → `REQUEST_CHANGES`
2. Spec source of truth / `Plans.md` / regression gate fails → `REQUEST_CHANGES`
3. Decision required → `decision_needed`
4. Only minor / recommendation → `APPROVE`
5. Insufficient evidence → `REQUEST_CHANGES` or `decision_needed`

## Post-fix re-review

Always perform re-review after `REQUEST_CHANGES`.
When the same issue fails twice in a row, force TeamAgent Debate.
