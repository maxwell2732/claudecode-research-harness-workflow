# cross-project-group.v1 Schema

Phase 65.3 (Cross-Project Group + 3-Layer Redaction) で導入。
`.claude/rules/cross-project-groups.yaml` のスキーマ仕様。

## 目的

Plan Brief / Acceptance Demo / Progress Tracker などの client 側 skill が、
**横断プロジェクト検索**を opt-in で有効化するためのグループ定義 SSOT。

横断検索は default 無効。`--cross-project-group <name>` flag で
明示的に group 名を指定した場合のみ、その group の member projects に
対して `mcp__harness__harness_mem_search` を発行する。

## スキーマ

```yaml
schema_version: cross-project-group.v1

groups:
  - name: <string>            # group 識別子
    description: <string?>    # 任意 (group の用途説明)
    members:                  # 配列、要素 unique、空 OK
      - <string>              # member project 名
      - <string>
```

## 制約

| フィールド | 型 | 必須 | 制約 |
|---|---|---|---|
| `schema_version` | string | ✓ | `cross-project-group.v1` 固定 |
| `groups` | array | ✓ | 空配列 `[]` 可 |
| `groups[].name` | string | ✓ | `groups` 内で unique、空文字不可 |
| `groups[].description` | string | optional | 任意 |
| `groups[].members` | array | ✓ | 配列、要素 unique、空 OK |
| `groups[].members[]` | string | - | 空文字不可、重複不可 |

## バリデーション

`scripts/load-cross-project-groups.sh` が yaml をパースし、
不正な schema を検出した場合は **exit 1** で停止する。

検出する不正:

1. `schema_version` 不一致 (`cross-project-group.v1` 以外)
2. `groups` が array でない
3. `groups[].name` 欠損 / 空文字 / 重複
4. `groups[].members` が array でない / 要素重複 / 空文字
5. `groups[].members[]` が string でない

## 利用例

### CLI (loader script 直接呼び出し)

```bash
# 全 groups を JSON で出力
bash scripts/load-cross-project-groups.sh

# 特定 group の members を JSON array で出力
bash scripts/load-cross-project-groups.sh --group "Personal Tools"
# → ["my-cli","my-dotfiles","my-scripts"]

# 存在しない group は exit 1
bash scripts/load-cross-project-groups.sh --group "Unknown"
# → stderr: "group not found: Unknown" / exit 1
```

### Skill 経由 (Phase 65.3.5 で実装予定)

```bash
# 横断検索なし (default、現プロジェクトのみ)
/harness-plan-brief "新しい CI を導入したい"

# 横断検索 opt-in (Personal Tools group の全 members を検索)
/harness-plan-brief "新しい CI を導入したい" --cross-project-group "Personal Tools"
```

## Cross-Project Search の実装 (D43 Option α)

```
client skill (Plan Brief / Accept / Progress)
   │
   │ --cross-project-group <name>
   ▼
load-cross-project-groups.sh --group <name>
   │
   │ JSON array of member projects
   ▼
For each member in members:
   mcp__harness__harness_mem_search(project=member, ...)
   │
   ▼
client 側でマージ・dedupe (relevance_score 順)
   │
   ▼
Layer 2 (dict + NER) で固有名詞 redact
   │
   ▼
Layer 3 (final scan) で残骸検出 → 0 件なら HTML 生成、検出なら exit 1
```

詳細な責任境界は [.claude/rules/cross-repo-handoff.md](../.claude/rules/cross-repo-handoff.md) の
「3 層 Redaction の責任境界」と「Phase 65.3 実装決定事項 (D43)」を参照。

## 関連

- `.claude/rules/cross-project-groups.yaml` — 本 schema の SSOT (default `groups: []`)
- `scripts/load-cross-project-groups.sh` — yaml → JSON parser + validator
- `tests/test-cross-project-groups-schema.sh` — 4 ケース機械検証
- `.claude/rules/cross-repo-handoff.md` — Phase 65.3 実装決定事項 (D43)
- `.claude/rules/client-redaction.yaml` — Layer 2a 辞書 (Phase 65.3.2 で導入予定)
- Plans.md §65.3.1-65.3.7 — Phase C 全タスク
