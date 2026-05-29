# Planning Quality Contract — harness-plan Standard Flow

`harness-plan` does not convert user-provided information directly into a work plan.
For plan creation and significant task additions, it filters through the latest information, existing specifications, memory, and TeamAgent / sub-agent multi-perspective discussions,
and only converts elements worth incorporating into this product into Plans.md task contracts.

This is not an independent subcommand. It is the standard quality gate for `create` and high-impact `add` operations.

## Step 0: Applicability determination

Use this quality contract in the following cases.

- Creating a new plan with `create`
- Adding tasks with `add` that affect product behavior / API / data model / permissions / billing / external integrations / distribution surfaces
- User has provided external products, competitors, specification proposals, improvement ideas, or comparison materials
- There is a risk of conflict with existing specifications, Plans.md, memory, or past decisions
- User requests "full power", "thorough comparison", "neutral scoring", "regression prevention", etc.
- Not single-instance or lightweight, but affects multiple tasks / multiple files / multiple sessions / product behavior / API / data model / permissions / billing / external integrations / distribution surfaces / security

For `create` and product-impacting `add`, read root `spec.md` every time.
Fall back to existing project spec / `docs/spec/00-project-spec.md` only for consumer repos without root `spec.md`.
Output must always include `Spec delta` or `Spec skip reason`.
This is a co-required planning output contract, and precedence remains `spec.md > sub-spec > Plans.md`.

Non-trivial planning requires TeamAgent or sub-agent verification as a prerequisite.
If the Task tool is available, always run independent perspectives.
If unavailable, explicitly state "sub-agent not used" and evaluate the same perspectives separately.
Always include `team_validation_mode` in the output.

| mode | When to use |
|------|----------|
| `not_required_lightweight` | Lightweight tasks such as typo / format / README / CHANGELOG / marker updates / status sync |
| `native` | Used runtime native multi-perspective verification such as TeamAgent |
| `subagent` | Used Task sub-agents per perspective |
| `manual-pass` | In a runtime where Task is unavailable like OpenCode; evaluated the same perspectives separately |
| `unavailable` | Verification not possible. Must not make non-trivial work Required |

The following can be treated lightly.

- `update` with only marker updates
- `sync` with only status reconciliation
- typo / format / README / CHANGELOG only
- Narrow changes where the correct answer is fixed by existing spec and tests

## Step 1: Input decomposition

Break user-provided information into the following 4 categories.

| Category | Examples |
|------|----|
| Evaluation targets | External products, competitor features, specification proposals, design policies, operational plans |
| User's intent | What they want to improve, what they want to avoid |
| Uncertain facts | Recency, pricing, APIs, constraints, competitive situation, existing repo state |
| Evidence needed for adoption decision | Official docs, measurements, existing specs, memory, test results |

Do not stop to ask questions even when unclear. First evaluate what the intent reasonably appears to be, and only present "decision branches" when judgment is truly contested.

## Step 2: Get latest information

Use WebSearch when external facts are involved. Priority order:

1. Official documentation, official blogs, release notes, GitHub repos
2. Standard specs, papers, technical sources close to primary information
3. Reliable comparison articles, case studies, issues / discussions

Verify important facts against at least 2 sources when possible.
If contradictions arise, organize what is contradicted and explicitly state the impact on the adoption decision.

When WebSearch is unavailable or network fails, handle as follows.

- `Latest information: unverified`
- Evaluate provisionally based only on local evidence
- Explicitly state "web verification still pending" in the final output

## Step 3: Verify local source of truth

Any proposal to incorporate into the product must be cross-referenced with the existing source of truth.

Minimum checks:

```bash
cat Plans.md
rg -n "related keywords" README.md README_ja.md CLAUDE.md docs skills scripts tests
rg -n "\"(lint|format)\"|eslint|prettier|biome|oxlint|dprint|ruff|black|isort|gofmt|go vet|cargo fmt|cargo clippy" package.json pyproject.toml go.mod Cargo.toml Makefile .github/workflows scripts docs 2>/dev/null
find docs -maxdepth 3 -type f | sort
git status --short --branch
```

Perspectives to check:

- Does it conflict with existing product promises?
- Does it conflict with existing skill role / trigger / allowed-tools?
- Does it conflict with incomplete tasks in Plans.md?
- Does it affect distribution mirrors, Codex mirrors, OpenCode mirrors, or i18n?
- If a specification source of truth exists, should root `spec.md` be updated before Plans.md?
- Are the root `spec.md` product contract and Plans.md task contract separated?
- For plans with source code changes, is there a lint / formatter baseline? If not, is a setup task needed before implementation?

## Step 4: Memory check

If harness-mem, harness-recall, or local memory files are available, check past decisions with relevant keywords.
When search is available, limit to the current project / repo. Use cross-project search only when the user explicitly requests it.
This step is a reinvention-prevention check and must not be omitted in non-trivial planning.

Examples of what to check:

- harness-mem / harness-recall search results
- `.claude/agent-memory/`
- `.claude/state/memory-bridge-events.jsonl`
- Check for existence of `.harness-mem/`
- Prior decisions recorded in repo docs / Plans.md

Notes:

- Do not assume direct reading of the harness-mem DB
- If harness-mem is not set up, unhealthy, or unsearchable, explicitly state "memory unverified"
- Memory is weaker than the current repo state. If old memory and git / docs conflict, prioritize the current repo state
- Do not assert something is absent just because memory or search cannot see it. `not_observed != absent`

## Step 5: Sub-agent discussion

Non-trivial planning requires TeamAgent or Task sub-agents as a prerequisite.
If the Task tool is available, run at least 3 independent perspectives. Specify "read-only", "evidence-backed", "conclusion first" for each agent.
Only explicitly skip this step for single-instance or lightweight tasks.
Product / Strategy, Architecture / Implementation, Security / Abuse, QA / Regression, Skeptic are perspective names, not agent_type names.
Pass them as perspectives to available TeamAgent / Task sub-agents.
Do not require arbitrary agent spawning.

Standard roles:

| Role | Purpose |
|------|------|
| Product / Strategy | Evaluate adoption value, differentiation, user value, opportunity cost |
| Architecture / Implementation | Evaluate implementation feasibility, alignment with existing design, maintenance burden |
| Security / Abuse | Evaluate permissions, secrets, prompt injection, supply chain, external transmission risks |
| QA / Regression | Evaluate regressions, tests, distribution mirrors, compatibility, whether it works in practice |
| Skeptic | Attack reasons not to adopt, over-investment, and vague assumptions |

What to require from each agent's output:

- Adopt / conditional adopt / reject
- Evidence
- Largest risk
- Additional items to verify
- Conflicts with existing specifications or memory
- DoD to incorporate into test / smoke / CI / review / release gate

How to summarize the discussion:

1. Extract points of agreement
2. Retain points of disagreement
3. Present your own judgment
4. Classify as Required / Recommended / Optional / Reject

If sub-agents are unavailable, explicitly evaluate the same 5 perspectives separately on your own and write "sub-agent not used".

## Step 5.5: Implementation plan verification gate

Do not mark an implementation plan Required until all of the following 5 are satisfied.

| Gate | What to check | If failed |
|------|----------|------------|
| Spec / Plans Fit | No conflict with order of root `spec.md`, sub-spec, `Plans.md` | Output `Spec delta` first or Reject |
| Memory / Wheel Check | No similar decisions or existing tasks in harness-mem / harness-recall / repo memory | Reuse existing proposal, task only the diff |
| Product Fit | Directly tied to product purpose and primary user workflow? | Defer to docs / external workflow / Optional |
| Security Fit | Does not weaken permissions, secrets, external transmission, dependencies, or branch/release gates? | spike / security task / Reject |
| Quality Baseline Fit | Can quality be determined Yes/No with lint / formatter / CI commands for source code changes? | Add setup task first, or leave formatter_baseline skip reason |
| Works In Practice | Can it be determined Yes/No with test / smoke / CI / review / release closeout? | Redo the DoD |

This gate is "pre-work to reduce rework" and is not a feelings-based review.
Any gate that fails must be reflected in the DoD, Depends, or `[needs-spike]` in Plans.md.
Quality Baseline Fit is not an excuse to carelessly add formatters or linters.
For plans with source code changes where it is not configured, place a setup task before implementation tasks.
The setup task's DoD must include config, package script / CI command, and validation command (3 items).
Do not install packages during planning. Installation is done by harness-work as a setup task.
Broad-scope batch reformatting is only executed when the user explicitly requests it or it is within that setup task's scope.
Security Fit does not require actual reading of secrets.
Stop at a Risk Gate if reading `.env`, tokens, private keys, customer data, etc., becomes necessary.
Verify using surfaces that do not read secret values: existing guardrails, config shapes, audit evidence, tests, GitHub / CI metadata, etc.

## Step 6: Neutral scoring review

Score on a 5-point scale. 5 is a good state; 1 is a weak state.

| Axis | 5 | 3 | 1 |
|----|-----|-----|-----|
| Product Fit | Directly tied to the core of the deployment product | Useful but peripheral | Could be handled by a different product or operations |
| Evidence Strength | Primary info + measurements + existing evidence | Only one side verified | Mostly speculation |
| User Value | Significantly improves decision quality or execution speed | Effective in some workflows | Thin perceived value |
| Implementation Feasibility | Small and localized | Medium-scale but manageable | Large-scale with high maintenance burden |
| Regression Safety | Low risk and testable | Some impact scope | Likely to break existing flows |
| Strategic Leverage | Leads to long-term differentiation | Stops at a convenience feature | Temporary |
| Security Safety | Does not weaken permissions or secrets, and is verifiable | Some concerns | Dangerous permission loosening or unverified external transmission |
| Works In Practice | Can be proven with smoke / CI / review | Mainly manual confirmation | Behavior confirmation is vague |

Correction rules:

- Evidence Strength 2 or below: Required prohibited
- Regression Safety 2 or below: Place spike / spec / test first
- Security Safety 2 or below: Required prohibited
- Works In Practice 2 or below: Redo DoD or demote to spike
- Quality Baseline Fit 2 or below with source code changes: Make formatter_baseline setup task a Required dependency
- Implementation Feasibility 2 or below and User Value 3 or below: Lean toward Reject
- Product Fit 2 or below: Do not incorporate into this product; defer to docs / external workflow

## Step 7: `$easy` report

Transform difficult evaluations into a form where decisions can be made, rather than presenting them as-is in the final output.

Required structure:

```markdown
In a word:
{{adoption decision in 1 sentence}}

Scoring review:
| Proposal | Score | Verdict | Evidence | Unverified |
|----|------|------|------|--------|

Proposals to incorporate:
| Priority | Proposal content | Reason | What changes |
|------|----------|------|--------------|

Regression check:
- team_validation_mode:
- Specification:
- Plans.md:
- harness-mem / memory:
- TeamAgent / sub-agent:
- product fit:
- security:
- works in practice:
- formatter_baseline:
- mirror / distribution:
- test:

Next steps:
1. ...
2. ...
3. ...
```

Writing style rules:

- Lead with the conclusion
- Immediately translate technical terms briefly
- Do not judge based on vague impressions like "amazing" or "innovative"
- Narrow proposals to 1-3. Do not list too many candidates.
- Separate facts, speculation, and unverified items

## Step 8: When converting to Plans.md / spec

Convert only adopted proposals into task contracts.

Order:

1. Read root `spec.md` and if needed, first update the product contract as `Spec delta`
2. If source code changes have unset lint / formatter baseline, place formatter_baseline setup task as a Required dependency first
3. Add only Required tasks to Plans.md
4. Attach `[needs-spike]` to high-risk proposals
5. Place a verifiable DoD with each task
6. Attach `[tdd:required]` to tasks that require TDD
7. For cases affecting mirror / i18n / package surfaces, add a separate verification task
8. If no spec update is needed, leave `Spec skip reason` in task context / sprint contract
9. For non-trivial planning, leave TeamAgent / sub-agent verification results or `sub-agent not used` fallback and 5 gate results in the task context
10. Do not make plans with `team_validation_mode: unavailable` Required. Only allow `not_required_lightweight` for lightweight tasks

The agent drafts `Spec delta`. Do not expect the user to write the spec from scratch.
Harness generates `Spec delta` / `Spec skip reason`; the consumer only approves or revises.

Prohibited:

- Creating only implementation tasks while the correct specification conditions are still in flux
- Settling regression checks with "please be careful" without making them a task
- Creating only implementation tasks while ignoring the absence of lint / formatter baseline for plans with source code changes
- Omitting `Spec skip reason` for docs-only / mechanical tasks
