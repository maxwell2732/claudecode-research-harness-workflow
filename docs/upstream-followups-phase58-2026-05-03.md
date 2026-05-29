# Phase 58 Follow-up Decisions - 2026-05-03

この文書は、Phase 58 の未対応 upstream を「今すぐ実装する前に設計すべきもの」と
「自動継承でよいもの」に分けるための判断メモです。

## ひとことで

Harness は、**Claude Code / Codex 本体の新機能をすぐ wrapper 化せず、安全境界とユーザー導線を先に固定します。**

## たとえると

新しい工具が届いた時に、いきなり全員に配るのではなく、
危ない刃物には保護カバーを付け、使う棚と名前を決めてから現場に出す、という整理です。

## Official References

- Claude Code changelog: <https://code.claude.com/docs/en/changelog>
- Claude Code GitHub changelog: <https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md>
- OpenAI Codex `rust-v0.125.0` release: <https://github.com/openai/codex/releases/tag/rust-v0.125.0>
- OpenAI Codex `rust-v0.128.0` release: <https://github.com/openai/codex/releases/tag/rust-v0.128.0>
- OpenAI Codex `0.129.0-alpha.2` compare: <https://github.com/openai/codex/compare/rust-v0.128.0...rust-v0.129.0-alpha.2>

## 58.2.1 Claude protected-write and `dangerously-skip` hardening

### Current Harness surface

| Surface | Current state | Gap from upstream |
|---------|---------------|-------------------|
| `go/internal/guardrail/helpers.go` | `.git/`, `.env`, keys, `.husky/` などを protected path として扱う | Claude Code 2.1.121 / 2.1.126 の skip mode は `.claude/`, `.vscode/`, shell config files なども prompt bypass 対象にした |
| `go/internal/guardrail/rules.go` | Write/Edit/MultiEdit と Bash write を block / ask / warn する | `.claude/` 全体を即 deny すると rules / memory / setup 更新も壊れる可能性がある |
| `.claude-plugin/settings.json` / `harness.toml` | sandbox denied domains などを sync している | `allowManagedDomainsOnly` / `allowManagedReadPathsOnly` precedence bug fix 後の managed sandbox 境界を再確認する必要がある |

### Decision

- **即時に `.claude/` 全体 deny はしない**
- 先に protected path taxonomy を作る
  - deny: `.git/`, secrets, shell rc / profile files, destructive hook entrypoints
  - ask: `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, `.vscode/`
  - warn: `.claude/rules/`, `.claude/memory/`, project-local setup metadata
- `--dangerously-skip-permissions` を使う session でも、Harness hook が動く範囲では guardrail を緩めない
- managed sandbox は `harness.toml` -> generated settings -> template -> tests の順で確認する

### Acceptance target

- protected path table が docs または rule comment にある
- Go guardrail tests に `.claude/skills`, `.claude/agents`, `.claude/commands`, `.vscode`, shell config files の deny / ask / warn 期待値がある
- `tests/test-claude-upstream-integration.sh` が Phase 58 hardening coverage を検出する
- normal setup / memory / rules 更新を過剰 deny しない

## 58.2.2 `PostToolUse.updatedToolOutput` output governance

### Current Harness surface

Phase 56 では `PostToolUse.duration_ms` を no-op にしました。
理由は per-tool telemetry sink がなく、session duration と tool duration を混ぜると分かりにくくなるためです。

Claude Code 2.1.121 では、`PostToolUse` が全 tool で `hookSpecificOutput.updatedToolOutput` を返せるようになりました。

### Decision

- **既定では tool output を書き換えない**
- 使う場合は opt-in にする
- 最初の候補は redaction / compaction / machine-readable normalization に限定する
- 元の output と更新後 output の traceability を失わない
- review や test の証拠を消す用途には使わない

### Acceptance target

- `updatedToolOutput` の許可用途 / 禁止用途が docs にある
- 実装する場合は before / after / audit record を test する
- stdout が JSON 契約の tool では、人間向け説明を stdout に混ぜない

## 58.2.3 Claude setup / MCP / telemetry refresh

### Decision

以下は runtime wrapper ではなく setup / docs / validation の候補として扱う。

| Item | Decision |
|------|----------|
| `claude ultrareview [target] --json` | `/harness-review` と競合させず、CI second-opinion として comparison task に残す |
| `${CLAUDE_EFFORT}` | skill prompt tuning に使う価値はあるが、全 skill に機械追加しない |
| `claude plugin validate` schema acceptance | release / marketplace validation docs で確認する |
| MCP `alwaysLoad` | always-load と deferred discovery の使い分けを setup docs に残す |
| `claude plugin prune` | stale dependency cleanup として docs 化候補。ただし uninstall/prune は破壊的なので dry-run 相当の説明を優先する |
| `ANTHROPIC_BEDROCK_SERVICE_TIER` | Claude Code Bedrock guidance として扱い、Codex provider policy と混ぜない |
| `claude project purge` | Harness state cleanup と混ぜず、`--dry-run` first の maintenance guidance にする |
| `claude_code.skill_activated.invocation_trigger` | skill analytics に入れる価値はあるが、telemetry sink 設計が先 |

## 58.3.1 Codex permission profiles and `--full-auto` migration

### Current Harness surface

`codex/.codex/config.toml` は Phase 56 で no-inline-hooks 方針を記録しています。
Codex `0.125.0` / `0.128.0` は permission profiles と sandbox profile controls を大きく進めました。

### Decision

- `--full-auto` を新規 docs の default として増やさない
- explicit permission profiles / trust flows を主導線に寄せる
- `requirements.toml` は org-managed policy の置き場として扱い、配布 default には推測で入れない
- `codex exec --json` reasoning token usage は loop / report telemetry 候補にする
- rollout tracing と existing AgentTrace の重複を確認する

### Acceptance target

- stale `--full-auto` guidance を `rg` で棚卸しする
- Codex permission profile examples が config surface と矛盾しない
- `codex/.codex/config.toml` に即時 hook を足す場合は Codex package test を追加する
- no-op 継続の場合は理由を config comment / docs / tests に残す

## 58.3.2 Codex plugin hooks, `/goal`, MultiAgentV2, app-server updates

### Decision

| Item | Decision |
|------|----------|
| `/goal` workflows | `Plans.md` SSOT と二重化しない。goal は runtime continuation 候補として調査する |
| plugin-bundled hooks / hook enablement state | Phase 56 の no-inline-hooks 方針を再評価するが、配布 default では無効化状態と opt-in を優先する |
| external agent import | Claude / Codex / external agent の ownership 境界を決めてから使う |
| MultiAgentV2 thread caps / wait controls | `agents.max_threads = 8` と v2-specific controls の関係を検証する |
| sticky environments / remote thread config | one primary environment per write turn は維持し、remote は read-only first にする |
| app-server release artifacts / Python SDK | Harness が SDK を同梱しない限り docs-only に留める |

## Why This Way

Phase 58 の upstream は、単純な docs refresh ではありません。
Claude 側は permission / hook output mutation、Codex 側は permission profiles / plugin hooks / goal workflow が大きく変わっています。

そのため、この snapshot では runtime を急いで増やさず、
まず「何を守るか」「どこまで自動継承するか」「どの task で実装するか」を固定します。
