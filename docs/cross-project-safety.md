# プロジェクトをまたいで検索するときの 3 層防御 (Phase 65.3)

別のプロジェクトの過去の判断や知見を引き出したいけれど、クライアント名・人名・会社名などの **固有名詞が混ざってほしくない**。
そのために 3 層に分けて固有名詞を黒塗り (=redact) する仕組み。

## やりたいこと

通常、Claude harness の検索は **現プロジェクトのみ** に限定される (default 安全)。

ただし類似案件の知見を持ち寄りたいときは、`--cross-project-group <name>` flag を指定して横断検索を有効化できる。
このとき、**他プロジェクトの固有名詞が現プロジェクトの HTML に漏れない** ように、3 層で防御する。

## やり方

### グループ定義 (前提準備)

`.claude/rules/cross-project-groups.yaml` に member project を列挙:

```yaml
schema_version: cross-project-group.v1
groups:
  - name: PersonalTools
    members:
      - my-cli
      - my-dotfiles
      - my-scripts
```

詳細: [cross-project-groups-schema.md](cross-project-groups-schema.md)

### 横断検索の有効化

```bash
# Plan Brief で横断検索を使う
/harness-plan-brief --cross-project-group "PersonalTools"
```

または skill 側 SKILL.md の Step 2 (alt) で記述された MCP N-call フローが自動適用。

### 3 層 redaction の働き

横断検索が有効化された場合、HTML 生成時に以下が自動実行:

#### Layer 1: harness-mem サーバー側 (Cross-Contract、別 repo)

- `<private>` ブロックの strip (server 出口で必ず実行、opt-out 不可)
- `strict_project: true` がデフォルト (ただし MCP 経由では現在不変、Phase 65.3.5 で N-call 対応)
- 実装: `harness-mem/memory-server/src/core/privacy-tags.ts`

#### Layer 2a: 辞書ベース固有名詞 redaction (client 側)

- `.claude/rules/client-redaction.yaml` の dict から literal string match
- 例: `NoraiCorp` → `[Client_A]`、`田中太郎` → `[Person_A]`
- 実装: `scripts/redact-by-dictionary.sh` (PiiRule 互換 schema)

#### Layer 2b: NER (Named Entity Recognition) redaction (client 側)

- Japanese tokenizer (fugashi + UniDic-lite) で形態素解析
- pos2 == "固有名詞" の token を `[Entity]` に置換
- 連続する固有名詞 token は 1 つの [Entity] にマージ
- tokenizer 不在時は **fail-open** (原文そのまま + stderr 警告)
- 実装: `scripts/redact-by-ner.sh`

#### Layer 3: 最終 sanity scan (client 側)

- HTML 生成直前に template chrome (CSS/HTML comment) を除外して scan
- カタカナ 5 文字以上連続を「残骸」として検出
- 検出時は **HTML を生成せず exit 1** (fail-safe)
- 実装: `scripts/render-html.sh --with-redaction` + `scripts/final-scan-redaction.py`

### 監査ログ

横断検索が走るたびに `.claude/state/audit/cross-project-search.jsonl` に 1 行追加:

```json
{
  "schema_version": "cross-project-audit.v1",
  "timestamp": "2026-05-09T12:00:00Z",
  "group_name": "PersonalTools",
  "member_projects": ["my-cli", "my-dotfiles"],
  "query_hash": "<sha256 64 chars>",
  "redaction_count": {"dict": 2, "ner": 1},
  "output_passed_final_scan": true
}
```

実際のクエリ文字列は **記録しない** (privacy)、sha256 hash のみ。

生成 HTML 末尾には「redacted: dict X 件 + NER Y 件」が表示。

## 気をつけること

### 1. Layer 1 は server 側 (別 repo)、claude-code-harness からは触らない

cross-repo handoff workflow (D42) の境界として、Layer 1 は harness-mem 側で完結。
client 側で `<private>` を含む新規 fixture を作っても、server 経由なら必ず strip される (opt-out 不可)。

### 2. NER tokenizer は opt-in 依存

`scripts/redact-by-ner.sh` は fugashi (Python tokenizer) を使う。
インストール状況:
- 環境にあれば自動使用 (確認: `python3 -c "from fugashi import Tagger"`)
- 不在なら fail-open (Layer 2a + Layer 3 のみで動作)

完全な NER カバレッジが必要な場合は `pip install fugashi unidic-lite` を実行。

### 3. Layer 3 final scan は fail-safe

カタカナ 5 文字以上連続を検出した場合、HTML は **生成されず exit 1**。
生成されない方が「漏れた HTML が公開される」より安全という判断。

template 著者の意図的な branding (例: `ハーネスオレンジ` in CSS comment) は除外される
(template chrome strip で `<!-- -->` `/* */` `<style>` `<script>` を scan 対象外に)。

### 4. 既存 server 側 sentinel `[REDACTED_*]` の二重置換ガード

mem 側 `event-recorder.ts:redactContent` が出力する `[REDACTED_EMAIL]` `[REDACTED_KEY]` `[REDACTED_SECRET]` `[REDACTED_HEX]` を、
client Layer 2 が再 redact しないよう sentinel 退避 → redact → 復元の 3 段で実装。
regex `[A-Za-z0-9_]+` で大文字小文字両対応。

### 5. cross-project default は OFF

`--cross-project-group` flag を指定しない限り、検索は現プロジェクトのみ (Phase 65.1.x の挙動)。
明示的に opt-in しないと横断検索は走らない。

### 6. 監査ログには生クエリを残さない

`query_hash` は sha256 (64 chars hex) のみ記録。
復元不可能なため、漏洩時も実クエリ内容は守られる。

## 関連

- [cross-project-groups-schema.md](cross-project-groups-schema.md) — グループ設定方法
- [cognitive-load-surfaces.md](cognitive-load-surfaces.md) — 3 surface の役割
- `.claude/rules/cross-repo-handoff.md` — D42 (claude-code-harness ↔ harness-mem 境界)
- `.claude/memory/decisions.md` D43 (本機能の設計判断、4 判断パッケージ)

## 関連スクリプト

| スクリプト | 役割 |
|----------|------|
| `scripts/load-cross-project-groups.sh` | yaml SSOT を読んで member projects を解決 |
| `scripts/redact-by-dictionary.sh` | Layer 2a 辞書 redaction |
| `scripts/redact-by-ner.sh` | Layer 2b NER redaction |
| `scripts/final-scan-redaction.py` | Layer 3 最終 scan |
| `scripts/render-html.sh --with-redaction` | 3 層を順次適用して HTML 生成 |
| `scripts/cross-project-audit-log.sh` | 監査ログ append |
