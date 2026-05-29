# Phase 58 Upstream Adoption Plan - 2026-05-03

この文書は、Claude Code `2.1.120`-`2.1.126` と Codex `0.125.0` / `0.128.0` の更新を、Claude Code Harness でどう活用するかを決めるための採用計画です。

## ひとことで

Phase 58 は、Claude / Codex の新機能をそのまま足すのではなく、Harness の安全境界、レビュー証跡、Codex 並列運用に合う形へ翻訳してから導入します。

## たとえると

新しい工具が届いた状態です。
すぐ現場に出すもの、保護カバーを付けるもの、まだ棚に置いておくものを分けます。

## 公式情報

- Claude Code changelog: <https://code.claude.com/docs/en/changelog>
- Claude Code GitHub changelog: <https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md>
- Codex `rust-v0.125.0`: <https://github.com/openai/codex/releases/tag/rust-v0.125.0>
- Codex `rust-v0.128.0`: <https://github.com/openai/codex/releases/tag/rust-v0.128.0>

## 採用メニュー

### 🛡️ A. Claude protected-write hardening

活用する更新:

- Claude Code `2.1.121`: `.claude/skills/`, `.claude/agents/`, `.claude/commands/` への write prompt bypass 範囲が変化。
- Claude Code `2.1.126`: `.claude/`, `.git/`, `.vscode/`, shell config files などの protected path bypass 範囲が拡大。
- Claude Code `2.1.126`: `allowManagedDomainsOnly` / `allowManagedReadPathsOnly` precedence 修正。

既存実装:

- `go/internal/guardrail/helpers.go` は `.git/`, `.env`, secret keys, `.husky/` を protected path 扱いしている。
- `go/internal/guardrail/rules.go` は `Write/Edit/MultiEdit` の protected path 書き込みを deny し、Bash redirection の `.env/.git/key` 書き込みも deny している。
- `templates/claude/settings.security.json.template` は `.claude/settings*` と `.claude-plugin/settings*` の deny を持つ。

不足:

- `.claude/skills`, `.claude/agents`, `.claude/commands`, `.vscode`, shell rc/profile files の分類がない。
- `.claude/rules`, `.claude/memory`, setup metadata を warn に残す分類がない。
- Bash `tee` / redirection で `.claude/*`, `.vscode/*`, shell config files に書くケースを検出していない。
- managed sandbox 境界を `harness.toml` / settings / template / CI で検証していない。

競合しない使い方:

- `.claude/` 全体 deny はしない。
- deny / ask / warn を分ける。
- `PermissionRequest` ではなく `PreToolUse` guardrail 側で止める。
- `WorkMode` でも protected path ルールは緩めない。

採用判断:

- ✅ 導入推奨。
- 最初に入れる。
- 事故防止の土台になる。

実装計画:

1. `go/internal/guardrail/helpers.go` に protected path taxonomy を追加する。
2. deny: `.git/`, secrets, shell rc/profile files, destructive hook entrypoints。
3. ask: `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, `.vscode/`。
4. warn: `.claude/rules/`, `.claude/memory/`, setup metadata。
5. `go/internal/guardrail/rules.go` で `Write/Edit/MultiEdit` と Bash write の分類を共通化する。
6. `scripts/ci/check-consistency.sh` で managed sandbox 境界を検証する。
7. `tests/test-claude-upstream-integration.sh` に Phase 58.2.1 実装検出を追加する。

検証:

- `go test ./go/internal/guardrail/...`
- `bash tests/test-claude-upstream-integration.sh`
- `bash scripts/ci/check-consistency.sh`
- `./tests/validate-plugin.sh`

### ✂️ B. PostToolUse `updatedToolOutput` output governance

活用する更新:

- Claude Code `2.1.121`: `PostToolUse` hooks can replace output for all tools via `hookSpecificOutput.updatedToolOutput`。

既存実装:

- `go/pkg/hookproto/types.go` の `PostToolHookSpecific` は `hookEventName` と `additionalContext` のみ。
- `harness hook post-tool` は警告がある時だけ `additionalContext` を返す。
- shell hooks も `additionalContext` 中心で、tool output の置換はしていない。

不足:

- `updatedToolOutput` 型がない。
- `tool_response`, `tool_use_id`, `duration_ms` の入力保持がない。
- before / after / audit record のモデルがない。
- review / test / lint 証拠を消さない機械テストがない。

競合しない使い方:

- 既定では tool output を書き換えない。
- opt-in のみ。
- 許可用途は secret redaction、長大出力 compaction、machine-readable normalization に限定する。
- 禁止用途は review / test / lint / error evidence の削除。
- stdout は JSON 契約だけにし、人間向け説明を混ぜない。

採用判断:

- 🟡 設計を先に導入。
- 実装は A の後。
- 便利だが証拠を壊しやすい。

実装計画:

1. `docs/output-governance.md` を追加する。
2. `go/pkg/hookproto` に `ToolResponse`, `ToolUseID`, `DurationMS`, `UpdatedToolOutput` を追加する。
3. `HARNESS_OUTPUT_GOVERNANCE=redact|compact|normalize` のような opt-in を設計する。
4. 単一の同期 PostToolUse mutation handler に集約する。
5. `.claude/state/output-governance.jsonl` に original hash / updated hash / policy / reason を記録する。
6. test failure / review finding / lint error は置換禁止としてテスト固定する。

検証:

- no-default-mutation test
- Bash secret redaction shape test
- review/test failure output non-mutation test
- audit record test
- stdout JSON-only test
- `bash tests/test-claude-upstream-integration.sh`

### 🧭 C. Claude setup / MCP / telemetry / provider guidance

活用する更新:

- `claude ultrareview [target] --json`
- `${CLAUDE_EFFORT}`
- `claude plugin validate` schema acceptance
- MCP `alwaysLoad`
- `claude plugin prune`
- `ANTHROPIC_BEDROCK_SERVICE_TIER`
- `claude project purge`
- `claude_code.skill_activated.invocation_trigger`
- Windows PowerShell primary shell
- forked skills/subagents deferred tools

既存実装:

- `/ultrareview` は Harness flow 内で呼ばない方針がある。
- `claude plugin validate` は `tests/validate-plugin.sh` で実行される。
- Codex MCP / provider guidance はある。
- Windows docs は Git Bash / MSYS / Cygwin / WSL2 中心である。

不足:

- `claude ultrareview --json` と Harness `review-result.v1` の境界が未更新。
- `${CLAUDE_EFFORT}` を skill tuning に使う方針がない。
- Claude Code MCP `alwaysLoad` と deferred discovery の使い分けがない。
- `plugin prune` の安全導線がない。
- Claude Code Bedrock service tier guidance が Codex provider docs と分離されていない。
- `project purge` と Harness state cleanup の違いが未整理。
- PowerShell primary shell route が docs にない。

競合しない使い方:

- Claude Code MCP と Codex MCP docs を混ぜない。
- `ANTHROPIC_BEDROCK_SERVICE_TIER` は Claude Code provider guidance に限定する。
- `plugin prune` は存在しない dry-run を案内せず、事前確認手順を置く。
- `ultrareview --json` は `/harness-review` の代替ではなく CI second-opinion 候補にする。

採用判断:

- ✅ docs / setup 更新として導入推奨。
- runtime wrapper は増やさない。

実装計画:

1. `docs/claude-code-setup-mcp-telemetry-provider.md` を追加する。
2. `docs/ultrareview-policy.md` と `skills/harness-review/SKILL.md` に `claude ultrareview --json` の境界を追記する。
3. `docs/effort-level-policy.md` に `${CLAUDE_EFFORT}` の限定用途を追記する。
4. `skills/harness-setup/SKILL.md` に MCP `alwaysLoad` と deferred discovery の使い分けを追加する。
5. `docs/plugin-managed-settings-policy.md` に `plugin validate` / `plugin prune` の安全導線を追加する。
6. Claude Code Bedrock service tier guidance を Codex provider policy から分離して追加する。
7. compatibility docs に PowerShell primary shell route を追加する。

検証:

- `bash tests/test-claude-upstream-integration.sh`
- `./tests/validate-plugin.sh`
- docs grep gate: `alwaysLoad`, `CLAUDE_EFFORT`, `plugin prune`, `ANTHROPIC_BEDROCK_SERVICE_TIER`, `project purge`, `invocation_trigger`, `PowerShell`, `deferred tools`

### 🔐 D. Codex permission profiles / `--full-auto` migration

活用する更新:

- Codex `0.125.0`: permission profiles round-trip across TUI, user turns, MCP sandbox state, shell escalation, app-server APIs。
- Codex `0.125.0`: `codex exec --json` reasoning-token usage。
- Codex `0.125.0`: rollout tracing records tool, code-mode, session, multi-agent relationships。
- Codex `0.128.0`: built-in permission profiles, sandbox CLI profile selection, cwd controls, active-profile metadata。
- Codex `0.128.0`: `--full-auto` deprecated in favor of explicit permission profiles and trust flows。

既存実装:

- Phase 58 snapshot / follow-up / Plans には記録済み。
- `codex/.codex/config.toml` は no-inline-hooks 方針と agent sandbox を持つ。
- `docs/codex-sandbox-execution-policy.md` は 0.123 系の sandbox policy を扱う。

不足:

- permission profile / trust flow の正本 docs がない。
- `scripts/codex/codex-exec-wrapper.sh` に `--full-auto` が残る。
- `scripts/codex-loop.sh` の local worker に `--dangerously-bypass-approvals-and-sandbox` が残る。
- `codex exec --json` reasoning token usage の保存先がない。
- rollout trace と existing AgentTrace の重複整理がない。
- `scripts/check-codex.sh` は `npm update -g @openai/codex` guidance のまま。

競合しない使い方:

- `--full-auto` を新規 docs の default として増やさない。
- 実装前に `codex exec --help` で現行 flag を確認する。
- `requirements.toml` は org-managed policy の置き場として扱い、配布 default に推測で入れない。
- `approval_policy: never` / `sandbox: workspace-write` の既存 worker setup と permission profiles の関係を明文化する。

採用判断:

- ✅ 導入推奨。
- ただし flag 置換は help / smoke test で確認してから。
- A の次に重要。

実装計画:

1. `docs/codex-permission-profiles-policy.md` を追加する。
2. `codex/README.md` と `codex/.codex/skills/harness-setup/SKILL.md` を profile 方針へ更新する。
3. `--full-auto` を legacy fallback 扱いへ移す。
4. wrapper / loop の flag を explicit profile または explicit sandbox/trust flow に移行する。
5. `codex exec --json` reasoning usage を job result に保存する設計を追加する。
6. rollout trace は `.claude/state/agent-trace.jsonl` と二重計上しない mapper 方針を作る。

検証:

- `bash tests/test-codex-package.sh`
- `bash tests/test-codex-loop-cli.sh`
- fake `codex` で `--json` reasoning usage 保存 test
- wrapper flag test
- `bash tests/test-claude-upstream-integration.sh`

### 🧩 E. Codex plugin workflows / `/goal` / MultiAgentV2

活用する更新:

- Codex `0.125.0`: app-server Unix socket, sticky environments, remote thread config/store。
- Codex `0.125.0`: remote plugin install and marketplace upgrade。
- Codex `0.128.0`: persisted `/goal` workflows。
- Codex `0.128.0`: plugin workflows, plugin-bundled hooks, hook enablement state, external-agent config import。
- Codex `0.128.0`: MultiAgentV2 thread caps, wait-time controls, root/subagent hints, depth handling。

既存実装:

- Phase 58 snapshot / follow-up / Plans に記録済み。
- `codex/.codex/config.toml` は no-inline-hooks 方針、`[features].multi_agent = true`, `[agents].max_threads = 8` を持つ。
- Breezing は Codex native `spawn_agent` / `send_input` / `wait_agent` / `close_agent` 前提。
- one-primary-environment policy は README / guard script / test にある。

不足:

- `/goal` に何を書いてよいかが未定義。
- plugin-bundled hooks / hook enablement state の opt-in 手順がない。
- external agent import の ownership 境界がない。
- MultiAgentV2 controls と `agents.max_threads = 8` の対応表がない。
- state path の説明に `${CODEX_HOME}/state/harness/` と `.claude/state/...` のズレがある。

競合しない使い方:

- `Plans.md` が SSOT。
- `/goal` は session continuation memo に限定する。
- task ID / DoD / status marker は `/goal` に書かない。
- plugin-bundled hooks は既定無効の opt-in。
- external agent import は直接使わず、allowlist / conversion table を先に作る。
- remote / sticky environment は read-only first。
- 書き込みは one primary environment per write turn。

採用判断:

- 🟡 設計レビュー向き。
- 58.3.1 の permission profile 方針後に着手。

実装計画:

1. `docs/codex-plugin-workflow-policy.md` を追加する。
2. `/goal`, plugin hooks, hook enablement state, external agent import, MultiAgentV2, sticky environment を採用 / opt-in / 禁止 / 保留に分ける。
3. `codex/README.md` と `codex/AGENTS.md` を更新する。
4. `codex/.codex/config.toml` の no-inline-hooks 方針を Codex 0.128 向けに言い換える。
5. MultiAgentV2 と `agents.max_threads = 8` の関係をテストで固定する。
6. state path の説明を `.claude/state/...` と `${CODEX_HOME}` の責務に分ける。

検証:

- `bash tests/test-codex-package.sh`
- `bash tests/test-claude-upstream-integration.sh`
- no-inline-hooks / plugin opt-in grep gate
- `/goal` と `Plans.md` SSOT boundary grep gate
- one-primary-environment regression test

## 導入順

1. 🛡️ A. Claude protected-write hardening
2. 🔐 D. Codex permission profiles / `--full-auto` migration
3. ✂️ B. PostToolUse output governance design
4. 🧭 C. Claude setup / MCP / telemetry / provider guidance
5. 🧩 E. Codex plugin workflows / `/goal` / MultiAgentV2

## レビュアー向け判定基準

### 導入してよい

- 既存の Harness 正本と競合しない。
- test で再発防止できる。
- upstream 機能を wrapper 化しすぎない。
- 既定では危険な自動化を有効にしない。
- 証拠ログとレビュー結果を消さない。

### 保留すべき

- `Plans.md` と別の正本を作る。
- `.claude/` 全体 deny のように通常運用を壊す。
- `--full-auto` や dangerous bypass を新規 default として広げる。
- output mutation で test / review / error evidence を隠す。
- Codex plugin hooks や external agent import を opt-in なしで有効化する。

## 次の実行コマンド

新しいセッションの起動コマンド:

```bash
claude
```

起動後の最初の入力:

```text
/harness-work 58.2.1
```

向いている場面:

最初に安全境界を固めるため。58.2.1 が通ると、58.2.2 以降の便利機能を入れても事故りにくくなります。

並列で進める場合の代替:

```text
/breezing 58.2.1 58.3.1 --parallel 2
```

向いている場面:

Claude 側の protected path hardening と Codex 側の permission profile migration は重なるファイルが少ないため、レビュアーが 2 本の PR として分けて確認しやすいです。
