# Weak-Supervision Elicitation Snapshot - 2026-05-06

## Summary

Claude Harness adopts weak-supervision ideas as an operational quality loop, not as model training.

The practical goal is simple: when a run says "tests passed", Harness should still ask whether the result is real, evidenced, reproducible, and safe to remember.

## Primary Sources

| Source | Date / version seen | Relevant finding | Harness decision |
|---|---:|---|---|
| [Removing Sandbagging in LLMs by Training with Weak Supervision](https://arxiv.org/abs/2604.22082) | submitted 2026-04-23, v2 2026-05-01 | Weak supervision can elicit sandbagging models when supervised fine-tuning and reinforcement learning are combined; reinforcement learning alone can become reward hacking; train/deploy distinguishability matters. | Adopt the audit lesson. Do not add real SFT/RL. Record weak labels and reviewer evidence instead. |
| [Auditing Games for Sandbagging](https://arxiv.org/abs/2512.07810) | submitted 2025-12-08 | Blue-team detection was not reliably able to distinguish sandbaggers; training-based elicitation helped, but detection can false-positive benign models. | Treat detections as review signals, not final proof. Reviewer keeps final verdict. |
| [Weak-to-Strong Generalization](https://arxiv.org/abs/2312.09390) | submitted 2023-12-14 | Weak supervision can elicit stronger behavior than the weak supervisor, but naive fine-tuning does not recover full capability. | Use weak labels to guide review and advisor context, not to claim full capability recovery. |
| [When Can LLMs Learn to Reason with Weak Supervision?](https://arxiv.org/abs/2604.18574) | submitted 2026-04-20 | Weak supervision behaves differently under scarce data, noisy rewards, and proxy rewards; reward saturation and reasoning faithfulness predict generalization. | Store reward scores and evidence refs so plateau and noisy reward patterns can be inspected later. |
| [OpenAI Codex: Iterate on difficult problems](https://developers.openai.com/codex/use-cases/iterate-on-difficult-problems) | checked 2026-05-06 | Codex works best with machine-readable evals, reviewable artifacts, explicit stopping rules, and a running log. | Implement a machine-readable weak-supervision report plus local event ledger. |
| [Claude Code hooks](https://code.claude.com/docs/en/hooks) | checked 2026-05-06 | Command hooks receive JSON via stdin and can return structured JSON on stdout. | Keep `Elicitation` and `ElicitationResult` as hook-driven capture points. |
| [Claude Code subagents](https://code.claude.com/docs/en/sub-agents) | checked 2026-05-06 | Subagents isolate context and can be used for specialized review or exploration. | Keep Advisor and Reviewer separated. Advisor gives cues; Reviewer owns approve/request-changes. |

## Adopted

- `weak-supervision-report.v1` records the score, verdict, rubric, privacy tags, and concrete evidence refs for "looks good" claims.
- `elicitation-event.v1` records the small observations that feed the next run: `capability_probe`, `weak_label`, `judge_verdict`, `eval_result`, and `counterexample`.
- The local ledger lives at `.claude/state/elicitation/events.jsonl` and is append-only.
- harness-mem receives events only through public CLI/HTTP/MCP style contracts. Claude Harness does not read harness-mem databases.
- Advisor can receive compact weak-supervision cues on high-risk, repeated-failure, and plateau-style requests.
- Reviewer checks for reward-hacking smells: hollow assertions, skipped tests, evidence-free approvals, and bugfixes without reproduction.

## Not Adopted

- No supervised fine-tuning pipeline.
- No reinforcement learning trainer.
- No hidden evaluation or deployment deception harness.
- No direct harness-mem SQLite reads.
- No automatic final approval from Advisor output.

## Boundary

SFT-like behavior means "inject good review examples and prior weak labels into the next prompt".

RL-like behavior means "run scored review loops and compare machine-readable reports".

Both are analogies. They are not model weight updates.

## Operational Flow

1. A hook or review script writes `elicitation-event.v1` locally.
2. If harness-mem is reachable, the same event is sent to `/v1/events/record` as best effort.
3. If harness-mem is missing, down, or older than the contract, the local ledger remains the source of continuity.
4. Reviewer runs residual checks and weak-supervision report checks.
5. Advisor requests read recent ledger cues only when the request reason is high-risk, repeated failure, plateau, or explicit advisor-required.
6. Reviewer remains the final quality gate.

## Privacy

Allowed privacy tags:

- `may_train`
- `do_not_train`
- `synthetic_only`
- `legal_hold`

Default is `do_not_train`.

The default is deliberately conservative because local implementation traces can include customer code, logs, or proprietary workflow details.
