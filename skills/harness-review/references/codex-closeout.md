# Quick / Codex Closeout

## In a nutshell

For small changes: fix the target, verify Codex advice with actual code, and stop there if clean.

## Target selection decision tree

1. Working tree is dirty
   - Recommended: uncommitted changes only
   - Base: `HEAD`
   - Include untracked
2. PR branch / feature branch has commits
   - Recommended: `upstream..HEAD` or `origin/main..HEAD`
   - If working tree is also dirty, use AskUserQuestion to choose "uncommitted only / everything / commits only"
3. Clean tree with no branch diff
   - Recommended: most recent 1 commit
   - Most recent 5 commits if needed
4. User specified `--base` / `--commit`
   - Explicit specification takes priority

## Advisory rule

Codex findings are advisory — "reference opinions," not facts.

Always do the following:

- Read the flagged location in actual code
- Verify reproducibility with diff and tests
- Separate into accepted findings / rejected findings
- Write "why not adopted" for rejected findings

## Stop-on-clean

Stop-on-clean:
Do not run additional reviews just for appearance after a clean result.

Example:

- Codex review: no major issues
- Focused tests: pass
- Manual spot check: pass

Stop here.
Run additional heavy review only before release, for security-sensitive changes, spec source of truth changes, or when the user explicitly requests it.

## Helper contract

`scripts/harness-review-closeout.sh` is a helper that fixes the execution plan for lightweight closeout.

Supported inputs:

- `--dry-run`
- `--parallel-tests`
- `--base REF`
- `--commit REF`
- `--uncommitted`
- `--test CMD`
- `--json`

Examples:

```bash
bash scripts/harness-review-closeout.sh --dry-run --uncommitted
bash scripts/harness-review-closeout.sh --base origin/main --parallel-tests --test "bash tests/test-harness-review-governance.sh"
bash scripts/harness-review-closeout.sh --commit HEAD --json
```

When Codex is unavailable:

- Fall back to full manual pass
- Do not treat failure as success
- Leave `codex_available: false` in the final report

## Final report

Required items:

- Review command
- Tests
- Accepted findings
- Rejected findings
- Clean result
- Fallback reason

Minimum JSON format:

```json
{
  "schema_version": "harness-review-closeout.v1",
  "target": "working_tree | branch_range | commit",
  "base_ref": "HEAD",
  "review_command": "bash scripts/codex-companion.sh review --base HEAD --json",
  "tests": [],
  "accepted_findings": [],
  "rejected_findings": [],
  "clean_result": true,
  "codex_available": true,
  "fallback": ""
}
```
