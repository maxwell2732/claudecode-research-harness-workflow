# Hooks `type: "mcp_tool"` 採用判断 (Phase 62.1.3)

> **判断**: **保留 (Phase 62 では採用しない)**
> **再評価条件**: harness-mem の MCP 経路が GA となり、shell wrapper 経由の遅延が telemetry で
> 月 5 分以上を継続的に超えるようになった時点。

## ひとことで

Claude Code `2.1.118` で hooks が `type: "mcp_tool"` を使って MCP ツールを直接呼び出せるようになった。
ただし Harness 側の現行 wrapper (`scripts/hook-handlers/*.sh`) で発生している遅延は実測ベースで小さく、
fallback 設計と auth scope の追加検討コストの方が大きいため、Phase 62 では保留として記録する。

## たとえると

「電動工具を新調する話」と似ている。手動工具 (shell wrapper) でも作業は終わるし、
電動工具 (MCP 直叩き) に切り替える前に、コンセント (auth) の位置と延長コード (fallback) を整える必要がある。
今は手動の不便がそこまで効いていないので、買い替えは先送りにする。

## 背景

### Claude Code 2.1.118 の変更点

- 既存の `type: "command"` (shell script) と `type: "agent"` (LLM agent) に加えて、
  `type: "mcp_tool"` が PostToolUse / PreToolUse などで使えるようになった
- `mcp_tool` を指定すると、hook 実行時に MCP server の特定ツールを直接呼び出せる
- Harness では `harness_mem_record_event`、`harness_mem_resume_pack` 等の MCP ツールが既に存在

### Harness の現行 hook 実装

| Hook 経路 | 仕組み | 例 |
|-----------|--------|-----|
| `scripts/hook-handlers/memory-bridge.sh` | shell wrapper が `curl` で harness-mem daemon に POST | UserPromptSubmit, PostToolUse |
| `scripts/hook-handlers/memory-session-start.sh` | shell wrapper が `harness-mem` 同名 script を `exec` | SessionStart |
| `scripts/hook-handlers/elicitation-handler.sh` | shell wrapper が `jq` で input を整形して JSON で stdout 返却 | Elicitation |

これらは Phase 49 (XR-003) で配線済みで、現状ほぼ無風。

## 比較表

| 観点 | shell wrapper 経由 (現状) | `type: "mcp_tool"` 直接呼び出し |
|------|--------------------------|----------------------------------|
| latency | 50-200ms (curl + jq + daemon RTT) | 推定 10-50ms (CC 内部 MCP client RTT) |
| auth scope | wrapper が token を直接持たない (daemon 側で処理) | hook 実行時に MCP auth scope の解決が必要 |
| error 伝播 | shell exit code + stderr で粒度低 | MCP RPC error code で粒度高 |
| fallback | wrapper 内で `silent skip` を実装済み | hook 自身では fallback できない (CC 側に依存) |
| 観測性 | `.claude/state/hook-runs.jsonl` に shell ログ | OTel 経由で MCP call として可視化 |
| 実装コスト | 既存資産そのまま | hooks.json schema 拡張 + auth 設計 + fallback 配線 |
| 配布リスク | 低 (shell wrapper は冪等性確保済み) | 中 (MCP server 不達時に hook が失敗する可能性) |

## 判断材料

### (i) PostToolUse から `harness_mem_record_event` を直接呼ぶ場合の予測

- **遅延**: 現状の `memory-post-tool-use.sh` の実測 (合計 50-150ms) が `mcp_tool` で 10-50ms 程度に減る見込み。
  ただし PostToolUse hook 自体のクリティカルパスではないため、ユーザー体感に影響しない。
- **auth**: `harness_mem_record_event` は harness-mem daemon の bearer token (もしくは local socket) を要求する。
  CC の MCP client が hook 実行コンテキストでこの token を保持できるかは未確認。
- **error 伝播**: 現状 daemon 不達時は shell wrapper が silent skip するが、
  `mcp_tool` で同等の挙動を実現するには CC 側の hook timeout / retry 仕様に依存する。

### (ii) shell wrapper 経由 vs 直接呼び出しトレードオフ

shell wrapper の利点:

- 既に Phase 49 で配線済みで運用上の問題が出ていない
- 失敗時の silent skip / 部分成功が wrapper 内で完結する
- harness-mem の API スキーマ変更時に CC 側 (hooks.json) を触らずに対応できる

`mcp_tool` の利点:

- CC 内部で完結するため、外部プロセス (curl, jq) の依存が消える
- OTel telemetry が一貫する
- 将来 `harness-mem` を pure MCP server 化する際の自然な経路となる

### (iii) MCP 不達時の fallback 方針

候補と本件での選択:

| 方針 | 説明 | 採用判断 |
|------|------|----------|
| `silent skip` | MCP 不達 = no-op で続行 | **本件で採用するなら第一候補**。Phase 49 の現行挙動と整合する |
| `queue` | 不達時はローカル queue に蓄積し次回 retry | 過剰設計 (harness-mem 自身が queue を持つため二重化) |
| `drop` | 不達時はイベント自体を破棄 | telemetry の正確性を損なうため非推奨 |

採用する場合は **silent skip** に統一する。

### (iv) Phase 61 ローカル ledger との関係

Phase 61 で導入した `.claude/state/elicitation/events.jsonl` は、
harness-mem 不達時の **append-only fallback** として機能する。
`mcp_tool` 採用後も、daemon 不達時は CC 側 hook → ローカル ledger へ書き込む経路を残す必要がある。
これは現状の wrapper 構造と同等の二段防御を CC hook 側で再実装する負荷を意味する。

## 結論

| 項目 | 内容 |
|------|------|
| 採用判断 | **保留** |
| 理由 | 現状の shell wrapper で運用上の問題が出ておらず、`mcp_tool` 採用には auth / fallback / Phase 61 ledger との整合検討が追加で必要 |
| 再評価トリガー | (a) harness-mem の MCP 経路が GA、(b) wrapper 遅延が telemetry で月 5 分以上、(c) CC が hook auth に対する公式ガイドを公開 |
| Phase 62 でやること | この doc の作成のみ。実装と hooks.json 変更は次フェーズ判断 |

## Acceptance 条件 (Phase 62.1.3 DoD)

- [x] `docs/hooks-mcp-tool-evaluation.md` がある
- [x] shell wrapper 経由 vs `type: "mcp_tool"` 直接呼び出しの比較表 (latency / auth / error / fallback の 4 項目) がある
- [x] MCP 不達時の fallback 方針が `silent skip` に明示確定
- [x] Phase 61 ledger との重複・補完関係が 1 段落で説明
- [x] 採用 / 保留 / 却下のいずれかで判断結論が記録 → **保留**
- [x] 採用条件 (再評価トリガー) が 3 項目で書かれる

## 参考

- Claude Code CHANGELOG `2.1.118`: <https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md>
- Phase 53 snapshot doc: `docs/upstream-update-snapshot-2026-04-23.md` (`53.1.2 MCP tool hook decision` で読み取り専用 MCP のみ許可、書き込み系は禁止と決定)
- Phase 49 (XR-003): `.claude-plugin/hooks.json` shell wrapper 配線
- Phase 61: `.claude/state/elicitation/events.jsonl` ローカル ledger
