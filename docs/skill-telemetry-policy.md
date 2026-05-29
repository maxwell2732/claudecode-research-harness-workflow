# Skill Telemetry Policy (Phase 62.2.3)

> **Status**: Active (2026-05-07)
> **対象**: Claude Code `2.1.126+` で発火する `claude_code.skill_activated` OTel event
> の `invocation_trigger` field を local ledger に記録する場合の運用ルール。

## ひとことで

Skill 発動の trigger 種別 (人間 / モデル / skill 連鎖) を **local ledger** に記録し、
無駄に発動している skill を特定する材料にする。
record する場合は **privacy / retention / opt-out** を必ず守る。

## たとえると

「読んだ本のタイトルだけ家計簿に書く」のと似ている。
中身 (本文 = skill 入力 / 出力) は書かず、いつ・どの種別で・どの本を読んだか (skill_activated event)
だけを記録する。

## telemetry sink 設計の前提

Phase 58.2.3 で「telemetry sink 設計が先」と判断済み。本 doc はその sink 仕様を定める。

| 項目 | 仕様 |
|------|------|
| sink 種別 | **local-only JSON Lines ledger** (外部送信なし) |
| ledger path | `.claude/state/skill-trigger-stats.jsonl` |
| append 方式 | **append-only** (追記のみ。compaction も deletion もしない) |
| 取得経路 | Claude Code の OTel event を `scripts/skill-trigger-telemetry.sh` で受け取り |
| 出力形式 | 1 行 1 JSON object |

## 記録フィールド

各 record は以下の field のみを含む。**個人を特定できる情報は記録しない**。

```json
{
  "timestamp": "2026-05-07T00:00:00Z",
  "skill_name": "harness-work",
  "invocation_trigger": "human|model|skill-chain",
  "session_id": "session-abc123",
  "duration_ms": 0
}
```

| field | 必須 | 説明 |
|-------|------|------|
| `timestamp` | yes | RFC3339 UTC |
| `skill_name` | yes | 発動した skill 名 (`harness-work`, `harness-review` 等) |
| `invocation_trigger` | yes | `human` / `model` / `skill-chain` のいずれか |
| `session_id` | yes | CC session ID (12 文字以上ある場合は前 12 文字に truncate) |
| `duration_ms` | no | skill 実行時間。CC が提供する場合のみ記録 |

**記録しない field**:
- skill の入力 prompt
- skill の出力本文
- ユーザー名 / メールアドレス
- API token / 認証情報
- 個別ファイルパス (skill 名以上の粒度では記録しない)

## privacy 原則

1. **local-only**: ledger は `.claude/state/` に置き、外部送信しない
2. **identifier minimization**: session_id は 12 文字以下の prefix に truncate
3. **content opacity**: skill の入出力本文は記録しない
4. **opt-out 可能**: 環境変数 `HARNESS_SKILL_TELEMETRY_DISABLE=1` で無効化

## retention

| Trigger | 保持期間 | 削除タイミング |
|---------|---------|--------------|
| 既定 | **30 日** | `scripts/maintenance/prune-skill-telemetry.sh` (manual or cron) |
| user 削除要求 | 即時 | `rm .claude/state/skill-trigger-stats.jsonl` |
| repo clone / share 時 | 共有しない | `.gitignore` に追加 (state path 一括除外で既存 .gitignore がカバー) |

30 日後の record は手動削除を **推奨** するが、自動削除はしない (audit 用途で長期保持したいケースを想定)。
削除を実装する場合は append-only 性質を保つために rotation 方式 (`stats.jsonl.{date}` への移動) にする。

## opt-out

### 完全無効化

`.claude/settings.json` または環境変数で無効化:

```bash
export HARNESS_SKILL_TELEMETRY_DISABLE=1
```

または:

```json
{
  "env": {
    "HARNESS_SKILL_TELEMETRY_DISABLE": "1"
  }
}
```

### 部分無効化 (skill 単位)

`.claude/settings.local.json` に exclude list を書く:

```json
{
  "harness": {
    "skill_telemetry_exclude": ["harness-work", "harness-loop"]
  }
}
```

## 関連 doc

- Phase 58.2.3 (`docs/upstream-followups-phase58-2026-05-03.md`) — telemetry sink 設計判断
- Phase 61 (`docs/sandbagging-aware-weak-supervision.md`) — `.claude/state/elicitation/events.jsonl` ledger と同じ append-only 設計を踏襲
- Claude Code OTel reference (Anthropic docs)

## Acceptance 条件 (Phase 62.2.3 DoD)

- [x] `docs/skill-telemetry-policy.md` がある (本 doc)
- [x] privacy / retention / opt-out が記載
- [x] Phase 58.2.3 の判断と矛盾しない (sink 設計を local-only 限定で固定)
- [x] sink path: `.claude/state/skill-trigger-stats.jsonl`
- [x] schema: timestamp / skill_name / invocation_trigger / session_id / duration_ms

## 参考

- Claude Code 2.1.126 CHANGELOG: `claude_code.skill_activated` OTel event includes `invocation_trigger`
- Phase 61 의 sandbagging-aware weak-supervision ledger 設計 (privacy-first, append-only)
