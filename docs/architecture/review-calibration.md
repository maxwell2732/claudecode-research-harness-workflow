# Review Calibration

レビューの drift を抑えるための保存形式と運用ルール。

## 保存先

- `.claude/state/review-result.json`
- `.claude/state/review-calibration.jsonl`
- `.claude/state/review-few-shot-bank.json`

## 記録ルール

`review-result.json` に `calibration` が付いている場合、`record-review-calibration.sh`
が `review-calibration.jsonl` に 1 行追記する。

`calibration.label` は次のいずれかに限定する。

- `false_positive`
- `false_negative`
- `missed_bug`
- `overstrict_rule`

Phase 61 の weak-supervision observations は `review-calibration.jsonl` に混ぜない。
`weak_label`, `judge_verdict`, `eval_result`, `counterexample` は
`.claude/state/elicitation/events.jsonl` に `elicitation-event.v1` として分離して記録する。
レビュー calibration は Reviewer の判定ドリフト補正、elicitation ledger は次回 Advisor/Reviewer への証拠 cue という役割分担にする。

## few-shot 更新

`build-review-few-shot-bank.sh` は calibration log から最新のサンプルを抽出し、
few-shot 用の JSON bank を再生成する。

## 品質姿勢

- 重大な不具合だけを `REQUEST_CHANGES` にする
- 証拠のない違和感は `minor` か `recommendation` に留める
- 指摘は後で few-shot に使える程度に短く具体的に書く
