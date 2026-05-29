# `/harness-work all` Evidence Pack

Last updated: 2026-03-06

This evidence pack is the minimum set for verifying the claims of `/harness-work all` by examining what is left after execution.
The current contract is: completion requires passing through a `sprint-contract` and an independent review artifact — not just the Worker's own self-check.

## What is included

| Scenario | Goal | Expected result |
|----------|------|-----------------|
| success | Complete a small TODO repo with `work all` | Tests turn green and additional commits remain |
| failure | Throw an impossible task to verify the quality gate | Tests remain failed, no additional commits are created |

## Fixtures

- `tests/fixtures/work-all-success/`
- `tests/fixtures/work-all-failure/`

Both fixtures are set up so that `npm test` fails at baseline.

## Smoke vs Full

| Mode | Command | What it does |
|------|---------|--------------|
| CI smoke | `./scripts/evidence/run-work-all-smoke.sh` | Verifies fixture integrity and baseline failure; leaves a Claude execution command preview |
| Local full | `./scripts/evidence/run-work-all-success.sh --full` | Runs the success scenario with Claude CLI; applies replay overlay to complete artifacts if rate-limited |
| Local full (strict) | `./scripts/evidence/run-work-all-success.sh --full --strict-live` | Proves success using only live Claude execution, no replay |
| Local full | `./scripts/evidence/run-work-all-failure.sh --full` | Runs the failure scenario with Claude CLI; verifies no new commits are created |

Artifacts are saved to `out/evidence/work-all/` by default.

## Prerequisites for full runs

- `claude --version` must pass (required for strict live)
- Must be authenticated with Claude Code
- Must run from the repo root

Full mode uses the following command internally:

```bash
claude --plugin-dir /path/to/claude-code-harness \
  --dangerously-skip-permissions \
  --output-format json \
  --no-session-persistence \
  -p "$(cat PROMPT.md)"
```

## Saved artifacts

- `baseline-test.log`
- `claude-stdout.json`
- `claude-stderr.log`
- `elapsed-seconds.txt`
- `git-status.txt`
- `git-diff-stat.txt`
- `git-diff.patch`
- `git-log.txt`
- `commit-count.txt`
- `result.txt`
- `execution-mode.txt`
- `sprint-contract.json` or contract generation log
- `review-result.json`
- `fallback-reason.txt`
- `rate-limit-detected.txt`
- `replay.log` (when rate limit fallback occurs)

## Interpretation

- In success: `post_test_status=0` and `final_commits > baseline_commits` proves "ran to completion and reached commit" for the minimal scenario
- Additionally, `review-result.json` being `APPROVE` proves "completed after passing independent review"
- In failure: `post_test_status!=0` and `final_commits == baseline_commits` proves at minimum "did not hide the failure and commit"
- Even if test tampering occurs in the failure fixture, it remains in the diff artifact, making it easy to review the quality gate behavior

## Live vs Replay

- `execution_mode=live`: the artifact where Claude CLI ran the success scenario to completion as-is
- `execution_mode=replay-after-rate-limit`: Claude execution stopped at rate limit; the replay overlay bundled with the fixture was applied to produce the happy-path artifact
- To claim "proven by live Claude run" in public wording, obtain a separate `--strict-live` success artifact
