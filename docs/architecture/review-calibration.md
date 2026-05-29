# Review Calibration

Storage format and operating rules for suppressing review drift.

## Storage Locations

- `.claude/state/review-result.json`
- `.claude/state/review-calibration.jsonl`
- `.claude/state/review-few-shot-bank.json`

## Recording Rules

When `review-result.json` includes a `calibration` entry, `record-review-calibration.sh`
appends one line to `review-calibration.jsonl`.

`calibration.label` must be one of the following:

- `false_positive`
- `false_negative`
- `missed_bug`
- `overstrict_rule`

Phase 61 weak-supervision observations must not be mixed into `review-calibration.jsonl`.
`weak_label`, `judge_verdict`, `eval_result`, and `counterexample` must be recorded separately
in `.claude/state/elicitation/events.jsonl` as `elicitation-event.v1`.
The division of responsibilities is: review calibration is for correcting Reviewer judgment drift,
and the elicitation ledger serves as evidence cues for the next Advisor/Reviewer.

## Few-shot Updates

`build-review-few-shot-bank.sh` extracts the latest samples from the calibration log
and regenerates the few-shot JSON bank.

## Quality Stance

- Only flag critical defects as `REQUEST_CHANGES`
- Leave unsubstantiated concerns as `minor` or `recommendation`
- Keep findings concise and specific enough to be usable as few-shot examples later
