# Benchmark Rubric

Last updated: 2026-03-06

This document is a rerunnable rubric for comparing `claude-code-harness` with other tools.
It scores based on static evidence and executed evidence separately, not on README impressions.

## Evidence Classes

| Class | Examples | Use case |
|------|----|-----------|
| Static evidence | README, repo tree, hooks definitions, tests, docs, package metadata | Presence of mechanisms, clarity of design, comparison of distribution pathways |
| Executed evidence | test run, smoke run, benchmark logs, evidence pack, CI artifact | Whether claims are reproducible, whether guardrails actually work in practice |

## Scoring Axes

| Axis | Weight | What to inspect |
|------|--------|-----------------|
| Runtime enforcement | 25 | Hooks, guardrails, deny/warn behavior, lifecycle automation |
| Verification and test credibility | 25 | Unit/integration tests, consistency checks, evidence pack, CI coverage |
| Onboarding and operator clarity | 20 | install flow, docs completeness, claim consistency, quickstart quality |
| Scope discipline and maintainability | 15 | distribution boundary, compatibility story, residue management |
| Positioning and adoption proof | 15 | public narrative, stars/users, reproducible showcase, differentiation |

Total: 100 points

## Review Flow

1. Gather static evidence
2. List claims that require executed evidence
3. Separate claims that were executed from those still pending execution
4. Score each axis and specify the type of evidence used
5. Write strengths and weaknesses separately — e.g., "strong design but unproven" or "strong market position but thin runtime enforcement"

## Required Output Format

Comparison reports must include at minimum:

- Comparison date and time
- Target repositories / versions / commit or default branch snapshot
- List of commands executed
- Distinction between static evidence and executed evidence
- Score per axis
- Items that could not be reproduced

## Reusable Template

```md
# Benchmark Report

- Compared at:
- Repositories / versions:
- Commands executed:

## Static evidence

- Repo structure:
- Docs and claims:
- Guardrails / hooks / tests:

## Executed evidence

- Validation commands:
- Benchmark or smoke runs:
- Evidence artifacts:

## Scores

| Axis | Score | Evidence type | Notes |
|------|-------|---------------|-------|
| Runtime enforcement |  | Static / Executed |  |
| Verification and test credibility |  | Static / Executed |  |
| Onboarding and operator clarity |  | Static / Executed |  |
| Scope discipline and maintainability |  | Static / Executed |  |
| Positioning and adoption proof |  | Static / Executed |  |

## Unverified or blocked items

- None

## Harness-specific Notes

- Strong claims like `/harness-work all` should only receive high scores once execution evidence in `docs/evidence/work-all.md` is complete
- Residual artifacts like `commands/` or `mcp-server/` are not penalized by default — **only penalized when their purpose is ambiguous**
- When README claims and tests/CI/distribution boundaries are misaligned, lower `Onboarding and operator clarity`
```
