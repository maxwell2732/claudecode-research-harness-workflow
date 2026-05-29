# Claude Code / Codex Feature Table (Full Upstream Snapshot)

> **Overview**: List of major Claude Code / Codex features tracked and utilized by Harness, along with upstream snapshots.
> Full version of the Feature Table from CLAUDE.md (with detailed descriptions).

## Feature List

| Feature | Applicable Skills | Purpose |
|--------|------------------|---------|
| **Phase 80 Claude Code 2.1.143-2.1.152 + Codex 0.131-0.134 upstream refresh** | upstream-update, hooks, skill-editing, setup, codex, harness-plan | `A: Implemented / C: Auto-inherited / P: Added to Plans / Reject: Unverified claim (B: 0 items)`.`docs/upstream-update-snapshot-2026-05-27.md` + `docs/upstream-adoption-plan-2026-05-27.md` を Plans `80.1.1`-`80.1.6` connected to.Claude: `disallowed-tools`, `/reload-skills`, `SessionStart.reloadSkills`, `MessageDisplay` opt-in policy, `/code-review` rename, `claude agents --json`, Auto mode consent Deprecated (Harness default 維持).Codex: `--profile` primary, curl/PowerShell installer docs, MCP environment/OAuth (defer), read-only MCP parallelism (inherit). |
| **Phase 69 Claude Code 2.1.133-2.1.142 follow-up utilization** | upstream-update, hooks, guardrails, agents, harness-plan, harness-work | `A: Implemented / C: Auto-inherited / P: Added to Plans (B: 0 items)`.`docs/upstream-update-snapshot-2026-05-15.md` を Tier 1 5 items (`worktree.baseRef` template explicit / hooks `$CLAUDE_EFFORT` rule / `autoMode.hard_deny` baseline 7 items / hook `args` exec form + `continueOnBlock` + SessionStart command-only rules / hook `terminalSequence` opt-in Implementation) + Tier 2 5 items (CC native `/goal` も Plans.md SSOT following policy / `claude agents` agent-view policy + 9 flag usage conditions / background permission mode retention Worker expectations / `claude plugin details` as CI supplementary info / Phase 69 rule SSOT) decomposed into.`.claude/rules/hooks-2.1.139-plus.md` and `docs/agent-view-policy.md` newly created, `templates/claude/settings.security.json.template` に `worktree.baseRef: "fresh"` / `autoMode.hard_deny` を baseline Addition (`.claude-plugin/settings.json` manual merge is self-write guardrail is release operator work), `scripts/lib/terminal-notify.sh` 経由で `webhook-notify.sh` と `notification-handler.sh` が `HARNESS_TERMINAL_NOTIFY` opt-in で `terminalSequence` を emit. |
| **Phase 67 Codex 0.130.0 stable snapshot** | upstream-update, setup, codex, harness-review | `A: Verification strengthened / C: Auto-inherited / P: Added to Plans (B: 0 items)`.`docs/upstream-update-snapshot-2026-05-10.md` を Plans `67.1.1`-`67.1.4` connected to, `rust-v0.130.0` stable の `codex remote-control`, plugin-bundled hooks, plugin sharing metadata, app-server Thread pagination APIs, Bedrock `aws login`, selected-environment `view_image`, live threads from latest config snapshot, `apply_patch` 後の turn diffs, ThreadStore summaries/resume/fork, `response.processed`, Windows sandbox runtime bin cache, `cargo install --locked`, OTel trace metadata, built-in MCPs, `CODEX_HOME` environments TOML provider classified as A/C/P minutes類. |
| **Phase 62 Claude Code 2.1.112-2.1.132 follow-up utilization + Opus 4.7 follow-up** | upstream-update, harness-loop, breezing, harness-review, guardrails, hooks | `A: Verification strengthened / C: Auto-inherited (B: 0 items)`.`docs/upstream-update-snapshot-2026-05-07.md` を Plans `62.1.1`-`62.3.1` connected to.Tier 1: subagent stall 2-layer defense (CC 600s + elicitation-handler), `ENABLE_PROMPT_CACHING_1H` 1h cache opt-in for long-running, hooks `type: "mcp_tool"` adopted判断 (= deferred), `sandbox.network.deniedDomains` baseline extended (template canonical 9 items), R06/R11/R12 wrapper bypass test (env/sudo/watch x 3 = 9 ケース).Tier 2: `PostToolUse.updatedToolOutput` opt-in handler + audit, agent permissionMode reaffirmation (Phase 59.2.3 Policy gate), `skill_activated.invocation_trigger` privacy-first telemetry, `CLAUDE_CODE_SESSION_ID` env policy 4 paths, `skillOverrides` 3 mode governance. |
| **Phase 61 Sandbagging-Aware Weak-Supervision Harness** | harness-review, harness-loop, harness-mem | `docs/sandbagging-aware-weak-supervision.md` and `docs/weak-supervision-elicitation-snapshot-2026-05-06.md` connected to.`weak-supervision-report.v1` / `elicitation-event.v1` / `.claude/state/elicitation/events.jsonl` で, fake successes, weak scoring, and counter-examples recorded, Advisor cue と Reviewer 検出 used for.Advisor uses `PLAN/CORRECTION/STOP`, Reviewer は最終判定のまま. |
| **Issue #105 English default + Japanese opt-in CI gate** | setup, harness-work, CI | New distribution surfaces default to English while Japanese opt-in UX, bilingual skill metadata, setup rendering, and mirror consistency are locked by the i18n regression suite. |
| **Phase 58 Claude Code 2.1.120-2.1.126 / Codex 0.125.0-0.128.0 snapshot** | upstream-update, harness-review, setup, codex | `A: Verification strengthened / P: Added to Plans`.`docs/upstream-update-snapshot-2026-05-03.md` and `docs/upstream-followups-phase58-2026-05-03.md` を Plans `58.1.1`-`58.3.2` connected to, Claude Code `--dangerously-skip-permissions`, `PostToolUse.updatedToolOutput`, MCP `alwaysLoad`, `claude plugin prune`, `claude project purge`, Codex permission profiles, `codex exec --json` reasoning tokens, plugin-bundled hooks, `/goal`, MultiAgentV2, and `0.129.0-alpha.2` watch status classified as A/C/P, and runtime implementation is protected path taxonomy / output governance / Codex profile migration 's follow-up task was cut into. |
| **Phase 56 Claude Code 2.1.119 / Codex 0.124.0 snapshot** | upstream-update, harness-review, setup | `A: Verification strengthened`.`docs/upstream-update-snapshot-2026-04-25.md` and `docs/upstream-followups-phase56-2026-04-25.md` を Plans `56.1.1`-`56.2.4` connected to, `--print` frontmatter parity, `PostToolUse.duration_ms`, status line effort/thinking, `prUrlTemplate`, Codex stable hooks, multi-environment app-server, and `0.125.0-alpha.2` watch status classified as A/C/P, and statusline tracking and docs-only safe defaults locked in tests. |
| **Task tool metrics** | parallel-workflows | Aggregate subagent token/tool/time metrics |
| **`/debug` Command** | troubleshoot | Diagnose complex session issues |
| **PDF page range** | notebookLM, harness-review | Efficient processing of large documents |
| **Git log Flag** | harness-review, CI, harness-release | Structured commit analysis |
| **OAuth Authentication** | codex-review | Configure MCP servers without DCR support |
| **68% memory optimization** | session-memory, session | `--resume` actively utilized |
| **Subagent MCP** | task-worker | MCP tool sharing during parallel execution |
| **Reduced Motion** | harness-ui | Accessibility settings |
| **TeammateIdle/TaskCompleted Hook** | breezing | Automate team monitoring |
| **Agent Memory (memory frontmatter)** | task-worker, code-reviewer | Persistent learning |
| **Fast mode (Opus 4.6)** | All skills | Fast output mode |
| **Automatic memory recording** | session-memory | Auto-persist knowledge across sessions |
| **Skill budget scaling** | All skills | Auto-adjust to 2% of context window |
| **Task(agent_type) restriction** | agents/ | Subagent type restriction |
| **Plugin settings.json** | setup | Reduce init tokens and provide immediate security protection |
| **Worktree isolation** | breezing, parallel-workflows | Safe parallel writes to the same file |
| **Background agents** | generate-video | Async scene generation |
| **ConfigChange hook** | hooks | Audit configuration changes |
| **last_assistant_message** | session-memory | Session quality assessment |
| **Sonnet 4.6 (1M context)** | All skills | Large-scale context processing |
| **Memory leak fix (v2.1.50-v2.1.63)** | breezing, work | Improve stability of long-running team sessions |
| **`claude agents` CLI (v2.1.50)** | troubleshoot | Diagnose and verify agent definitions |
| **WorktreeCreate/Remove hook (v2.1.50)** | breezing | Automatic worktree lifecycle setup and cleanup (implemented) |
| **`claude remote-control` (v2.1.51)** | Investigated — future support | External build and local environment serving |
| **`/simplify` (v2.1.63)** | work | Phase 3.5 Auto-Refinement: automatic code refinement after implementation |
| **`/batch` (v2.1.63)** | breezing | Delegate parallel migration of cross-cutting tasks |
| **`code-simplifier` plugin** | work | `--deep-simplify` time deep refactoring |
| **HTTP hooks (v2.1.63)** | hooks | Provides JSON POST template. TaskCompleted notifications enabled when `HARNESS_WEBHOOK_URL` is set |
| **Auto-memory worktree Sharing (v2.1.63)** | breezing | Share memory between worktree agents |
| **`/clear` スキルCacheリセット (v2.1.63)** | troubleshoot | Diagnose cache issues during skill development |
| **`ENABLE_CLAUDEAI_MCP_SERVERS` (v2.1.63)** | setup | Option to disable claude.ai MCP servers |
| **Effort levels + ultrathink (v2.1.68)** | harness-work | Auto-inject ultrathink for complex tasks using multi-factor scoring |
| **Agent hooks (v2.1.68)** | hooks | LLM agent code quality guard via type: "agent" |
| **Opus 4/4.1 Deletion (v2.1.68)** | — | Removed from first-party API. Auto-migrated to Opus 4.6 |
| **`${CLAUDE_SKILL_DIR}` Variable (v2.1.69)** | All skills | Resolve reference paths within skills independent of execution environment |
| **InstructionsLoaded hook (v2.1.69)** | hooks | Track instructions loading event before session |
| **`agent_id` / `agent_type` Addition (v2.1.69)** | hooks, breezing | Stabilize teammate identification and role determination |
| **`{"continue": false}` teammate 応答 (v2.1.69)** | breezing | Enable automatic stop when all tasks complete |
| **`/reload-plugins` (v2.1.69)** | All skills | Immediate reflection after editing skills and hooks |
| **`includeGitInstructions: false` (v2.1.69)** | work, breezing | Reduce tokens in scenarios where git instructions are unnecessary |
| **`git-subdir` plugin source (v2.1.69)** | setup, release | Support for plugin sources managed in subdirectories |
| **Auto Mode (RP Phase 1)** | breezing, work | CC native feature. Harness side tracks PermissionDenied only. Decision logic not implemented. Current default is `bypassPermissions` |
| **Per-agent hooks (v2.1.69+)** | agents/ | Add `hooks` field to agent definition frontmatter. Set PreToolUse guard for Worker, Stop log for Reviewer |
| **Agent `isolation: worktree` (v2.1.50+)** | agents/worker | Add `isolation: worktree` to Worker agent definition. Automatic worktree isolation during parallel writes |
| **Compaction 画像保持 (v2.1.70)** | notebookLM, harness-review | Preserve images in summary requests. Improved prompt cache reuse |
| **サブエージェント最終レポート簡潔化 (v2.1.70)** | breezing, harness-work | Reduce token consumption in subagent completion reports |
| **`--resume` スキルList再注入Deprecated (v2.1.70)** | session | Save ~600 tokens on session resume |
| **Plugin hooks Fix (v2.1.70)** | hooks | Stop/SessionEnd fires after /plugin, template conflicts resolved, WorktreeCreate/Remove works correctly |
| **Teammate ネスト防止AdditionFix (v2.1.70)** | breezing | Additional nesting prevention fix on top of v2.1.69 support |
| **PostToolUseFailure hook (v2.1.70)** | hooks | New hook event that fires on tool call failure |
| **`/loop` + Cron スケジューリング (v2.1.71)** | breezing, harness-work | `/loop 5m <prompt>` で定期実行.タスク進捗のAutomaticMonitoring utilized in |
| **Background Agent OutputパスFix (v2.1.71)** | breezing, parallel-workflows | Completion notification includes output file path. Results recoverable after compaction |
| **`--print` チームエージェント hang Fix (v2.1.71)** | CI Integration | `--print` mode team agent hang fix |
| **Plugin InstallParallel実行Fix (v2.1.71)** | breezing | Stabilize plugin state with multiple instances |
| **Marketplace Improvement (v2.1.71)** | setup | @ref parser fix, update merge conflict fix, MCP server deduplication, /plugin uninstall uses settings.local.json |
| **Subagent `background` Field (v2.1.71+)** | breezing, parallel-workflows | Add `background: true` to agent definition. Always executes as a background task |
| **Subagent `local` MemoryScope (v2.1.71+)** | agents/ | Save to `.claude/agent-memory-local/` with `memory: local`. Isolate sensitive learning that should not be committed to VCS |
| **Agent Teams 実験Flag (v2.1.71+)** | breezing | Enable Agent Teams with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var. Officially documented |
| **`/agents` Command (v2.1.71+)** | troubleshoot, setup | Interactive agent management UI. Create, edit, delete, list via GUI |
| **Desktop Scheduled Tasks (v2.1.71+)** | harness-work | CC native feature. No Harness default config (CronCreate tool is available) |
| **`CronCreate/CronList/CronDelete` ツール (v2.1.71+)** | breezing, harness-work | `/loop` internal tool. Create and manage scheduled tasks within a session |
| **`CLAUDE_CODE_DISABLE_CRON` 環境Variable (v2.1.71+)** | setup | `=1` disables Cron scheduler. For environments where security policy restricts scheduled execution |
| **`--agents` CLI Flag (v2.1.71+)** | breezing, CI | Pass session-level agent definitions in JSON. Temporary agent config not saved to disk |
| **`ExitWorktree` ツール (v2.1.72)** | breezing, harness-work | Tool to programmatically exit a worktree session |
| **Effort levels simplified (v2.1.72)** | harness-work | `max` deprecated; 3 levels `low/medium/high` + `○ ◐ ●` symbols. Reset to default with `/effort auto` |
| **Agent tool `model` Parameter復活 (v2.1.72)** | breezing | per-invocation model override available again |
| **`/plan` description Argument (v2.1.72)** | harness-plan | `/plan fix the auth bug` enters plan mode with description |
| **Parallelツール呼び出しFix (v2.1.72)** | breezing, harness-work | Read/WebFetch/Glob failures no longer cancel sibling calls (only Bash errors cascade) |
| **Worktree isolation fix (v2.1.72)** | breezing | Restore cwd on Task resume, include worktreePath in background notifications |
| **`/clear` バックグラウンドエージェント保持 (v2.1.72)** | breezing | `/clear` stops foreground tasks only. Background agents remain |
| **Hooks fixes (v2.1.72)** | hooks | transcript_path fix, PostToolUse double display fix, async hooks stdin fix, skill hooks double-fire fix |
| **HTML コメント非表示 (v2.1.72)** | All skills | CLAUDE.md `<!-- -->` hidden on auto-injection. Still visible with Read tool |
| **Bash auto-approval Addition (v2.1.72)** | guardrails | `lsof`, `pgrep`, `tput`, `ss`, `fd`, `fdfind` added to allowlist |
| **プロンプトCacheFix (v2.1.72)** | All skills | Fix SDK `query()` cache invalidation. Up to 12x reduction in input token cost |
| **Output styles (v2.1.72+)** | All skills | `.claude/output-styles/` to define custom output styles. `harness-ops` provides structured output for Plan/Work/Review |
| **`permissionMode` in agent frontmatter (v2.1.72+)** | agents/ | Explicitly declare `permissionMode` in agent definition YAML. No need to specify `mode` at spawn time |
| **Agent Teams official best practices (v2.1.72+)** | breezing | 5-6 tasks/teammate guidelines, `teammateMode` config, plan approval patterns reflected in team-composition |
| **Sandboxing (`/sandbox`)** | breezing, harness-work | OS-level filesystem/network isolation. Complementary layer to `bypassPermissions` |
| **`opusplan` モデルエイリアス** | breezing | Auto-switch to Opus for planning, Sonnet for execution. Optimal for Lead Plan → Execute flow |
| **`CLAUDE_CODE_SUBAGENT_MODEL` 環境Variable** | breezing, harness-work | Specify subagent model in bulk. Centralize model control for Worker/Reviewer |
| **`availableModels` Configuration** | setup | Restrict list of available models. Model governance for enterprise operations |
| **Checkpointing (`/rewind`)** | harness-work | Track, rewind, and summarize session state. Supports safe exploration and experimentation |
| **Code review (managed service)** | harness-review | Multi-agent PR review + `REVIEW.md`. Research Preview for Teams/Enterprise |
| **Status line (`/statusline`)** | All skills | Custom shell script status display bar. Constantly monitor context usage, cost, and git state |
| **1M context window (`sonnet[1m]`)** | harness-review, breezing | Leverage 1M token context window for large codebase analysis |
| **Per-model prompt caching control** | All skills | `DISABLE_PROMPT_CACHING_*` to control cache per model. Debug and cost optimization |
| **`CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING`** | harness-work | Disable Adaptive Reasoning to revert to fixed thinking budget. Predictable cost control |
| **Chrome integration (`--chrome`, beta)** | harness-work, harness-review | Browser automation for UI testing, form input, console debug. Switch within session with `/chrome` |
| **LSP サーバーIntegration (`.lsp.json`)** | setup | CC native feature. No Harness default `.lsp.json` config (can configure individually with `/setup lsp`) |
| **`SubagentStart`/`SubagentStop` matcher (v2.1.72+)** | breezing, hooks | Monitor subagent lifecycle per agent type at settings.json level. Individual tracking for Worker/Reviewer/Scaffolder/Video Generator |
| **Agent Teams: task dependencies** | breezing | Automatic management of task dependencies. Blocked tasks auto-unblock on dependency completion. File locking prevents claiming conflicts |
| **`--teammate-mode` CLI Flag (v2.1.72+)** | breezing | Switch `in-process`/`tmux` display mode per session. `claude --teammate-mode in-process` |
| **`CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` (v2.1.72+)** | setup | `=1` disables all background task features. For environments where security policy restricts background execution |
| **`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` (v2.1.72+)** | breezing, harness-work | Adjust subagent auto-compaction threshold (default 95%). `50` for early compaction, improved stability for long-running Workers |
| **`cleanupPeriodDays` Configuration (v2.1.72+)** | setup | Automatic cleanup period for subagent transcripts (default 30 days) |
| **`/btw` サイドクエスチョン (v2.1.72+)** | All skills | Ask a short question while preserving current context. No tool access, not saved to history. Lightweight alternative to spawning subagents |
| **Plugin CLI Command群 (v2.1.72+)** | setup | `claude plugin install/uninstall/enable/disable/update` + `--scope` flag. Supports automation via scripts |
| **Remote Control 強化 (v2.1.72+)** | Investigated — future support | `/remote-control` (`/rc`) to enable within session. `--name`, `--sandbox`, `--verbose` flags. Show QR code with `/mobile`. Supports auto-reconnect |
| **`skills` Field in agent frontmatter (v2.1.72+)** | agents/ | サブエージェントにスキルをプリロード.Worker に `harness-work`+`harness-review`, Reviewer に `harness-review`, Scaffolder に `harness-setup`+`harness-plan` injected (Implemented) |
| **`modelOverrides` Configuration (v2.1.73)** | setup, breezing | Map model picker entries to custom provider model IDs such as Bedrock ARNs |
| **`/output-style` 非Recommended化 (v2.1.73)** | All skills | `/config` migrated. Output style selection integrated into config menu |
| **Bedrock/Vertex Opus 4.6 Default化 (v2.1.73)** | breezing | Cloud provider default Opus updated from 4.1 → 4.6 |
| **`autoMemoryDirectory` Configuration (v2.1.74)** | session-memory, setup | Customize auto-memory save path. Support project-specific memory isolation |
| **`CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` (v2.1.74)** | hooks | Make SessionEnd hook timeout configurable (previously fixed at 1.5 seconds before kill) |
| **Full model ID fix (v2.1.74)** | agents/, breezing | `claude-opus-4-6` etc. full model IDs now recognized in agent frontmatter and JSON config |
| **Streaming API Memory leak fix (v2.1.74)** | breezing, harness-work | Fix unlimited RSS growth in streaming response buffer |
| **`--remote` / Cloud Sessions** | breezing, harness-work | `--remote` to launch cloud sessions from terminal. Async task execution |
| **`/teleport` (`/tp`)** | session | Bring cloud sessions into local terminal |
| **`CLAUDE_CODE_REMOTE` 環境Variable** | hooks, session-env-setup | Detect cloud vs local execution. Used for hook conditional branching |
| **`CLAUDE_ENV_FILE` SessionStart 永続化** | hooks, session-env-setup | Persist env vars from SessionStart hook to subsequent Bash commands |
| **Slack integration (`@Claude`)** | — | Future support (Teams/Enterprise 前提).Harness 側のImplementationなし |
| **Server-managed settings (public beta)** | setup | Bulk settings management via server delivery. For Teams/Enterprise |
| **Microsoft Foundry** | setup, breezing | Added as new cloud provider |
| **`PreCompact` hook** | hooks | ContextCompress前の状態Saveと WIP タスクWarning (Implemented) |
| **`Notification` hook event** | hooks | 通知発火時のカスタムハンドラ (Implemented) |
| **`/context` command (v2.1.74)** | all skills | Visualize context consumption and suggest optimizations |
| **`maxTurns` エージェント安全制限** | agents/ | Prevent runaway with turn limits. Worker: 100, Reviewer: 50, Scaffolder: 75 |
| **Output token limits 64k/128k (v2.1.77)** | all skills | Opus 4.6 / Sonnet 4.6 default 64k, max 128k tokens |
| **`allowRead` sandbox Configuration (v2.1.77)** | harness-review | `denyRead` re-allow reading specific paths within |
| **PreToolUse `allow` respects `deny` (v2.1.77)** | guardrails | Hook `allow` does not override settings.json `deny` |
| **Agent `resume` → `SendMessage` (v2.1.77)** | breezing | Agent tool `resume` deprecated; migrated to `SendMessage({to: agentId}) |
| **`/branch` (formerly `/fork`) (v2.1.77)** | session | `/fork` → `/branch` renamed. Alias retained |
| **`claude plugin validate` enhanced (v2.1.77)** | setup | frontmatter + hooks.json syntax validation added |
| **`--resume` 45% 高速化 (v2.1.77)** | session | Faster resume and reduced memory for fork-heavy sessions |
| **Stale worktree conflict fix (v2.1.77)** | breezing | Prevent accidental deletion of active worktrees |
| **`StopFailure` hook event (v2.1.78)** | hooks | Capture session stop failures due to API errors |
| **`${CLAUDE_PLUGIN_DATA}` Variable (v2.1.78)** | hooks, setup | State directory that persists across plugin updates |
| **Agent `effort`/`maxTurns`/`disallowedTools` frontmatter (v2.1.78)** | agents/ | Declarative control of plugin agents |
| **`deny: ["mcp__*"]` fix (v2.1.78)** | setup | Correctly block MCP tools with settings.json deny |
| **`ANTHROPIC_CUSTOM_MODEL_OPTION` (v2.1.78)** | setup | Custom model picker entry |
| **`--worktree` skills/hooks LoadFix (v2.1.78)** | breezing | Normal skill/hook loading with worktree flag |
| **Skill `effort` frontmatter (v2.1.80)** | harness-work, harness-review, harness-plan, harness-release | Give the 5-verb skills their own thinking budget to improve initial quality of heavy flows |
| **Agent `initialPrompt` frontmatter (v2.1.83)** | agents/ | Stabilize the first turn of Worker/Reviewer/Scaffolder per role |
| **`sandbox.failIfUnavailable` (v2.1.83)** | setup, guardrails | Do not silently fall back to unsandboxed on sandbox launch failure |
| **`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` (v2.1.83)** | hooks, setup | Reduce credential exposure surface to hook/Bash/MCP stdio subprocesses |
| **`TaskCreated`/`CwdChanged`/`FileChanged` hooks (v2.1.83-2.1.84)** | hooks, session | Add reactive state tracking and Plans/rules re-read reminders |
| **Rules/skills `paths:` YAML list (v2.1.84)** | setup, localize-rules | Store multiple globs in structured form; make rule scope readable and robust |
| **Hooks conditional `if` field (v2.1.85)** | hooks, guardrails | Limit `PermissionRequest` to safe Bash and edit operations; reduce unnecessary hook activations and false warnings |
| **Large session truncation fix (v2.1.78)** | session | Fix truncation of sessions exceeding 5MB |
| **`--console` auth flag (v2.1.79)** | setup | Anthropic Console API billing authentication |
| **Turn duration display (v2.1.79)** | all skills | `/config` toggle turn execution time display |
| **`CLAUDE_CODE_PLUGIN_SEED_DIR` 複数対応 (v2.1.79)** | setup | Specify multiple seed directories |
| **SessionEnd hooks `/resume` fix (v2.1.79)** | hooks | Correct SessionEnd firing on interactive session switching |
| **18MB startup memory 削減 (v2.1.79)** | all skills | Reduce startup memory usage |
| **MCP tool description cap 2KB (v2.1.84)** | all skills | OpenAPI 由来の巨大 MCP SchemaによるContext肥大化 prevents.CC Auto-inherited |
| **`TaskCreated` hook blocking (v2.1.84)** | hooks | Hook fires synchronously on TaskCreate. Used for state tracking in runtime-reactive |
| **Idle-return prompt 75min (v2.1.84)** | session | 75 minutes or more離席後に `/clear` を提案.stale SessionのToken浪費防止.CC Auto-inherited |
| **`X-Claude-Code-Session-Id` header (v2.1.86)** | setup | API RequestにSession ID HeaderAddition.プロキシ側の集計に利用可能.CC Auto-inherited |
| **Cowork Dispatch fix (v2.1.87)** | breezing | Cowork Dispatch のメッセージ配信Fix.CC Auto-inherited |
| **`PermissionDenied` hook event (v2.1.89)** | hooks, breezing | Fires when auto mode classifier rejects. `{retry:true}` induces retry. Implemented for Breezing Worker rejection tracking and Lead notification |
| **`"defer"` permission decision (v2.1.89)** | hooks, breezing | Returning `"defer"` from PreToolUse pauses headless session → re-evaluate on resume. Safety valve for Breezing |
| **`updatedInput` + `AskUserQuestion` (v2.1.89+)** | hooks | ヘッドレス環境で外部 UI / Explicit answer source が質問 times答を収集し, 既知同義語 only canonical option label に寄せて `updatedInput.answers` returns.A: Implemented (`ask-user-question-normalize`) |
| **Hook output >50K disk save (v2.1.89)** | hooks | Save large-output hooks to disk + preview. Prevent context bloat |
| **Hooks `if` compound command fix (v2.1.89)** | hooks | `ls && git push` や `FOO=bar git push` のような複合Commandが `if` Conditionにマッチ ようFix.CC Auto-inherited |
| **Autocompact thrash loop fix (v2.1.89)** | all skills | 3 times連続 compact→即再充填で actionable error を出 Stop.CC Auto-inherited |
| **Nested CLAUDE.md re-injection fix (v2.1.89)** | all skills | 長Sessionで CLAUDE.md が数十 times再注入 isバグ fixed.CC Auto-inherited |
| **Thinking summaries default off (v2.1.89)** | all skills | thinking summaries のDefault生成 stops.`showThinkingSummaries:true` で復元.CC Auto-inherited |
| **PreToolUse exit 2 JSON fix (v2.1.90)** | hooks, guardrails | Fix block behavior with JSON stdout + exit 2. pre-tool.sh deny works more reliably |
| **PostToolUse format-on-save fix (v2.1.90)** | hooks | PostToolUse フックがファイルを書き換えた後の Edit/Write 失敗 fixed.CC Auto-inherited |
| **`--resume` prompt-cache miss fix (v2.1.90)** | session | v2.1.69 +の times帰バグFix.deferred tools/MCP/agents 使用時の resume Cacheミス.CC Auto-inherited |
| **SSE/transcript performance (v2.1.90)** | all skills | SSE フレーム O(n²)→O(n), transcript writes 二次Function→線形.CC Auto-inherited |
| **`/powerup` interactive lessons (v2.1.90)** | — | Claude Code Feature学習のアニメーションデモ.CC Auto-inherited |
| **MCP `maxResultSizeChars` 500K (v2.1.91)** | hooks, setup | MCP ツールResultのMaximumサイズを `_meta["anthropic/maxResultSizeChars"]` で 500K up toextended.大きな harness-mem Result等で活用可能 |
| **`disableSkillShellExecution` setting (v2.1.91)** | setup, guardrails | スキル内の shell 実行 disables.Security要 itemsが高い環境向けConfiguration |
| **Plugin `bin/` directory (v2.1.91)** | setup | プラグインが `bin/` ディレクトリにコンパイル済みバイナリを同梱可能.futureの配布形態extended候補 |
| **Transcript chain breaks fix (v2.1.91)** | session | `--resume` 時の transcript 途切れ fixed.CC Auto-inherited |
| **Subagent spawning fix (v2.1.92)** | breezing | "Could not determine pane count"Fix.Breezing 安定性向上.CC Auto-inherited |
| **`forceRemoteSettingsRefresh` (v2.1.92)** | — | Teams/Enterprise 向け fail-closed remote settings.CC Auto-inherited |
| **`/usage` usage / cost / stats view (v2.1.92, v2.1.118 refresh)** | all skills | `/usage` を利用量 / コスト / 統計の入口 as扱う.旧 `/cost` / `/stats` はRelated tab を開く shortcut as CC Auto-inherited |
| **Linux `apply-seccomp` helper (v2.1.92)** | setup | sandbox unix-socket ブロッキング強化.CC Auto-inherited |
| **Plugin `skills` FieldExplicit化 (v2.1.94)** | setup | plugin.json に `"skills": ["./"]` をExplicit宣言.CC 2.1.94 でスキル呼び出し名が frontmatter `name` Criteriaに.A: Implemented (plugin.json Update) |
| **Monitor ツール (v2.1.98)** | breezing/harness-work/ci/deploy/harness-review | 長 hoursプロセスの stdout ストリーミングMonitoring.polling from低レイテンシ / 低Token消費で CI/デプロイ進捗を追跡.A: Implemented (allowed-tools + OperationGuide + Feature Table) |

## Phase 44 追補テーブル

この追補Sectionでは, `2.1.99-2.1.111` と Opus 4.7 onlyをまとめて見られるように います.

| Feature | 活用スキル / 領域 | 用途 | 付加価Value |
|------|-------------------|------|----------|
| **公開 changelog なしの版 (`2.1.99`, `2.1.100`, `2.1.102`, `2.1.103`, `2.1.104`, `2.1.106`)** | all skills | ExplicittrackingItemなし.ベースラインVerification only | `C: CC Auto-inherited` |
| **`/team-onboarding` と `2.1.101` 系の安定化** | setup, session | onboarding / resume UX 向上 | `C: CC Auto-inherited` |
| **`PreCompact` hook (v2.1.105)** | hooks, breezing | 長 hours Worker 実行中の compaction を block Designの土台 | `A: ExplicittrackingTarget` |
| **plugin `monitors` manifest (v2.1.105)** | hooks, setup, breezing | monitor を session start / skill invoke で auto-arm | `A: ExplicittrackingTarget` |
| **thinking hint Improvement (v2.1.107, v2.1.109)** | all skills | 長考中の UI ヒントImprovement | `C: CC Auto-inherited` |
| **`ENABLE_PROMPT_CACHING_1H` (v2.1.108)** | session, work, breezing | 1 hours prompt cache TTL を opt-in でOperation可能に | `A: ExplicittrackingTarget` |
| **recap / built-in slash command discovery (v2.1.108)** | session, all skills | 再開品質と slash command 利用の向上 | `C: CC Auto-inherited` |
| **permission deny 再評価 fix (v2.1.110)** | hooks, guardrails | `updatedInput` と mode Update後も deny を再評価 前提を docs とTest観点 reflected in | `A: ExplicittrackingTarget` |
| **`/tui`, focus, recap まわりの UX Improvement (v2.1.110)** | session | 画面表示と remote client 体験のImprovement | `C: CC Auto-inherited` |
| **`xhigh` effort (v2.1.111)** | harness-review, advisor, docs | `high` と `max` の中間強度を正式Target asadopted | `A: ExplicittrackingTarget` |
| **`/ultrareview` (v2.1.111)** | harness-review, docs | cloud 多エージェント review と `/harness-review` の役割を整理 | `A: ExplicittrackingTarget` |
| **Auto mode no longer requires `--enable-auto-mode` (v2.1.111)** | docs, guardrails | Auto Mode の前提文言を古い enable flag Dependency fromUpdate | `A: ExplicittrackingTarget` |
| **`/effort` slider と model picker Integration (v2.1.111)** | harness-review, docs | effort を会話中に調整しやすく | `A: ExplicittrackingTarget` |
| **read-only bash permission prompt 緩和 (v2.1.111)** | guardrails, docs | 安全な read-only Commandの prompt 発火が減る前提 updates | `C: CC Auto-inherited` |

### Opus 4.7 Section

| Feature | 活用スキル / 領域 | 用途 | 付加価Value |
|------|-------------------|------|----------|
| **literal instruction following** | agents, skills, docs | 曖昧表現を減らし, 指示とStopConditionを具体化 | `A: ExplicittrackingTarget` |
| **`xhigh` effort** | harness-review, advisor, docs | 重い review / advisory only thinking を一段引き上げる | `A: ExplicittrackingTarget` |
| **task budgets** | docs, future work | Existing `max_consults` / cost 制御との競合をfirst整理 | `A: ExplicittrackingTarget` |
| **tokenizer Improvement** | all skills | token 効率Improvementの恩恵を受ける | `C: CC Auto-inherited` |
| **vision 2576px** | harness-review, docs | 高解像度ReviewのOperationUpper limit updates | `A: ExplicittrackingTarget` |
| **memory Improvement** | session-memory, docs | 長 hours実行と resume の説明を新前提に合わせる | `A: ExplicittrackingTarget` |
| **`/ultrareview`** | harness-review, docs | `/harness-review` との役割 minutes担を明文化 | `A: ExplicittrackingTarget` |
| **Auto Mode 拡大** | docs, guardrails | enable flag 前提を落とし, 常設Feature as扱う | `A: ExplicittrackingTarget` |

| **`context: fork` host CLAUDE.md InheritSpecificationと auto-start times避パターン (Phase 46)** | harness-review | `context: fork` スキルは isolated context で動作し, host CLAUDE.md の session-start rules に override されてStop 事象を解消.host CLAUDE.md InheritSpecificationと auto-start times避パターンを `skill-editing.md` に明文化 (Issue #84).A: Implemented (SKILL.md Step 0 硬化 + `REVIEW_AUTOSTART` marker 契約) | `A: Implemented` |

**注記**:
この追補では `A` / `C` / `P` を使い, `B` は `0` itemsです.
`A` は"Harness 側でExplicittracking 責務がa/anItem", `C` は"Claude Code / Codex 本体のUpdateをas-isInherit Item", `P` は"今 times直接Implementationせず Added to Plans Item"を意味します.

## Phase 51 追補テーブル

この追補Sectionでは, Claude Code `2.1.112-2.1.114` と Codex `0.121.0` の一次情報 from, Harness に載せるItem onlyを minutes類します.

| Feature | 活用スキル / 領域 | 用途 | 付加価Value |
|------|-------------------|------|----------|
| **AskUserQuestion `updatedInput.answers` bridge** | hooks, harness-plan, harness-release | `PreToolUse` でExplicit的に渡 was answers を読み, `solo/team` や `scripted/exploratory` など既知同義語 onlyを option label に正規化 headless 対話を継続 | `A: Implemented` (`go/internal/hookhandler/ask_user_question_normalizer.go`, `hooks/hooks.json`, `tests/test-claude-upstream-integration.sh`) |
| **Claude Code 2.1.113 permission / sandbox hardening** | settings, guardrails | `sandbox.network.deniedDomains` configuredし, `find -exec` / `-delete` と macOS dangerous rm paths を Harness guardrail even検出 | `A: Implemented` (`.claude-plugin/settings.json`, `go/internal/guardrail/helpers.go`, `tests/test-claude-upstream-integration.sh`) |
| **Claude Code 2.1.114 permission dialog crash fix** | hooks, team execution | Agent Teams teammate の permission dialog crash Fix | `C: CC Auto-inherited` |
| **Claude/Codex upstream update Skills gate** | skills, review | upstream update 実施前に version-by-version minutes解表をRequired化し, PR Targetの `skills/` / `codex/.codex/skills/` と local-only `.agents/skills/` の判定をSync | `A: Implemented` (`claude-codex-upstream-update`, `cc-update-review`) |
| **Codex 0.121.0 marketplace / MCP Apps / memory controls** | setup, future Codex workflow | plugin marketplace, MCP Apps tool calls, memory reset / cleanup, sandbox metadata を Harness の Codex 比較軸へ残す | `P: Added to Plans`.今 timesは Claude hardening ImplementationをPriorityし Plans に切り出し |
| **Codex 0.121.0 secure devcontainer / bubblewrap** | setup, guardrails | secure devcontainer profile と macOS Unix socket allowlist をfutureの sandbox policy 比較Targetに | `C: Codex 側調査済み / Harness 変更なし` |
| **Skills mirror 総点検** | skills, setup | `.agents/skills` の Claude/Codex 置換 drift, Codex native tool model, memory/session path, media generation metadata を棚卸し | `P: Added to Plans` (`docs/skills-audit-2026-04-20.md`) |

**注記**:
Phase 51 even `B: 書いた only` は `0` itemsです.Codex 0.121.0 の大きいItemは, 今 timesの直接Implementationではなく"Codex 比較軸" as Plans に残し, Claude Code 側の `AskUserQuestion.updatedInput` と 2.1.113 hardening は settings / Go / tests up toImplementation `A` としま.

## Phase 52 追補テーブル

この追補Sectionでは, Claude Code `2.1.116` と Codex `0.122.0` / `0.123.0-alpha.2` の一次情報 from, Harness に直接Implementation べきか, Auto-inherited / Added to Plansに留めるべき whether minutes類します.Detailsは `docs/upstream-update-snapshot-2026-04-21.md` recorded in います.

| Feature | 活用スキル / 領域 | 用途 | 付加価Value |
|------|-------------------|------|----------|
| **Claude Code 2.1.116 resume / MCP / plugin updater UX refresh** | session, setup, MCP | `/resume` 高速化, MCP startup deferred loading, plugin dependency auto-install を Harness の session / setup guidance と照合 | `C/P: Auto-inherited + Added to Plans`.Harness wrapper はAdditionせず, plugin dependency policy と MCP health watch のFollow-up候補 retained in |
| **Claude Code 2.1.116 dangerous-path safety / agent hooks refresh** | guardrails, agents | sandbox auto-allow dangerous-path safety と main-thread `--agent` hooks 発火をExisting guardrail / agent policy と照合 | `C/P: Auto-inherited + Added to Plans`.R05 guardrail は維持し, agent frontmatter policy audit retained in |
| **Codex 0.122.0 plugin / Plan Mode / permission model** | codex workflow, setup, sandbox | `/side`, fresh-context Plan Mode, plugin workflow, deny-read glob, tool discovery default-on を Codex mirror Improvement候補 classified as | `P: Added to Plans`.Phase 51.2 の Codex-native skill audit と一緒に扱う |
| **Codex 0.123.0-alpha.2 pre-release** | future compare | release body が薄い alpha を推測Implementationせず, stable 化後の再VerificationTargetに | `P: Added to Plans`.compare from推測Implementation not |
| **Upstream update Skills merge hardening** | skills, review, tests | `cc-update-review` を diff-aware 化し, `claude-codex-upstream-update` を no-op adaptation 対応に mirror drift test added | `A: Implemented` (`skills/cc-update-review`, `skills/claude-codex-upstream-update`, `tests/test-claude-upstream-integration.sh`) |

**注記**:
Phase 52 even `B: 書いた only` は `0` itemsです.Claude / Codex 本体が自然にImprovement UX は `C` とし, Harness に重ねると二重責務 becomesものは `P` asFollow-upの Codex-native skill audit / plugin policy connected toしま.直接Implementationは review findings の再発防止に絞り, skill mirror drift と no-op adaptation を test で固定 います.

## Phase 53 追補テーブル

この追補Sectionでは, Claude Code `2.1.117-2.1.118` と Codex `0.123.0` の一次情報 from, Harness に直接Implementation べきか, Auto-inherited / Added to Plansに留めるべき whether minutes類します.Detailsは `docs/upstream-update-snapshot-2026-04-23.md` recorded in います.

| Feature | 活用スキル / 領域 | 用途 | 付加価Value |
|------|-------------------|------|----------|
| **Claude Code `type: "mcp_tool"` hooks** | hooks, MCP diagnostics, tests | shell script を増やさず, 読み取り専用の MCP health / resource 診断 hook を小さくVerification | `A: Implemented`.53.1.2 では manifest Additionを no-op とし, 常設 read-only diagnostic tool と安定 field Specificationが揃う up to配布 hooks へ入れない判断を snapshot recorded in.書き込み系 MCP tool を呼ばないことは `tests/test-claude-upstream-integration.sh` で固定 |
| **Claude Code `claude plugin tag`** | harness-release, plugin release | `VERSION` と `.claude-plugin/plugin.json` のSyncVerification後に plugin version validation 付き tag creates | `A: Implementation予定`.53.1.3 で release flow / dry-run / test guidance にAddition |
| **Auto Mode `"$defaults"` extension** | permissions, sandbox, settings docs | built-in default を置き換えず, Harness 独自Rule added 形へ guidance updates | `A: Implemented`.53.1.4 で `"$defaults"` を additive baseline as記録し, R05 / `deniedDomains` と二重責務にならないReasonを snapshot / template / upstream integration test で固定 |
| **Plugin themes / managed settings / dependency auto-resolve** | setup, plugin policy, enterprise docs | `themes/`, `DISABLE_UPDATES`, `blockedMarketplaces`, `strictKnownMarketplaces`, dependency hints をManagement環境向けに整理 | `A: docs 化済み`.53.1.5 で `docs/plugin-managed-settings-policy.md` newly createdし, Harness 独自 resolver を重ねないPolicyを明記.theme 同梱判断は snapshot 側で `P` as残す |
| **Claude Code UX / runtime fixes** | session, agents, MCP, search, effort | `/usage` Integration, `/resume` `/add-dir` 対応, `--agent` + `mcpServers`, stale session summary, native `bfs` / `ugrep`, 高 effort default を整理 | `C/P: Auto-inherited + Added to Plans`.53.1.6 で wrapper added notReasonを snapshot recorded inし, `--agent` + `mcpServers` と external forked subagent flag は agent audit 候補 as `P` retained in |
| **Codex 0.123.0 provider / model metadata** | Codex setup, provider policy | built-in `amazon-bedrock` provider, AWS profile support, current `gpt-5.4` default metadata を Codex setup guidance reflected in | `A: docs 化済み`.53.2.1 で `docs/codex-provider-setup-policy.md` newly createdし, Harness 配布 config では `model` / `model_provider` fixedせず, Bedrock 利用者 onlyが user / project config にAddition Policy fixed |
| **Codex 0.123.0 MCP diagnostics / plugin loading** | troubleshoot, setup, Codex plugin docs | `/mcp verbose`, diagnostics / resources / resource templates, `.mcp.json` の `mcpServers` Formatと top-level server map Formatを setup guidance reflected in | `A: docs 化済み`.53.2.2 で `docs/codex-mcp-diagnostics.md` newly createdし, 普段は `/mcp`, 困った時 only `/mcp verbose` usesProcedureと, Claude Code 側 MCP guidance と混ぜないPolicy fixed |
| **Codex 0.123.0 realtime handoff silence** | harness-loop, breezing, long-running | background agents が transcript delta receives and, 必要ない時はExplicit的に沈黙できる前提で途中報告の頻度を整理 | `A: docs 化済み`.53.2.3 で `harness-loop` は 1 cycle につき最終報告 1 times, `breezing` は task 完了 per progress feed 1 timesを基本にし, advisor / reviewer drift は silence Target外 as固定 |
| **Codex 0.123.0 sandbox / exec changes** | sandbox, execution policy | `remote_sandbox_config`, `codex exec` shared flags をtracking | `A: docs 化済み`.53.2.4 で `docs/codex-sandbox-execution-policy.md` addedし, remote environment ごとの sandbox 要 items比較と wrapper flag 重複削減可否 fixed |
| **Codex 0.123.0 automatic bug fixes** | Codex long-running UX, session shell, review privacy | `/copy` rollback, manual shell follow-up queue, Unicode / dead-key, stale proxy env, VS Code WSL keyboard, review prompt leak を記録 | `C: Codex Auto-inherited`.53.2.5 で workaround added notReasonを明記 |

**注記**:
Phase 53 even `B: 書いた only` は `0` itemsです.Feature Table は入口に留め, 公式 URL と version-by-version の判断根拠は `docs/upstream-update-snapshot-2026-04-23.md` に集約しま.`A` は Phase 53 の具体 task connected to, `C` は本体FixのAuto-inherited, `P` は推測Implementation notfuture判断 as扱います.

Phase 53 closeout では, Codex mirror / path drift の広い棚卸しを Phase 51.2 の Codex-native skill audit TODO に残します.Phase 53 は upstream `0.123.0` 差 minutesの具体反映 onlyを閉じ, Phase 51.2.1-51.2.4 の tool model / memory path / mirror path / media metadata 整理を先取りしません.

## Phase 69 追補テーブル (Claude Code 2.1.133-2.1.142)

この追補Sectionでは, Claude Code `2.1.133-2.1.142` の 10 バージョン minutesを Harness のImplementation/Auto-inherited/deferredにどう minutes類 whether記載します.一次情報と version-by-version の判断根拠は `docs/upstream-update-snapshot-2026-05-15.md` reference ください.

| Feature | 活用スキル / 領域 | 用途 | 付加価Value |
|------|-------------------|------|----------|
| **Claude Code `worktree.baseRef` (2.1.133)** | settings, breezing, worker isolation | `--worktree` / `EnterWorktree` / agent-isolation worktree の起点を `origin/<default>` (`fresh`) or local `HEAD` (`head`) でExplicit | `A: Implemented` (`templates/claude/settings.security.json.template`).Phase 69.1.1 で template に baseline `fresh` をExplicitし, unpushed commits を持ち込みたい team は project-level で `head` を opt-in できる.Plugin 本体 `.claude-plugin/settings.json` は self-write deny for release operator がManualマージ |
| **Claude Code hook `$CLAUDE_EFFORT` env + `effort.level` JSON (2.1.133)** | hooks, observability | hook handler / Bash subprocess fromCurrentの effort を観測できる | `A: Implemented` (`.claude/rules/hooks-2.1.139-plus.md`).Phase 69.1.2 で"観測 only可, guard rail の effort 緩和はProhibited"を明文化 |
| **Claude Code `settings.autoMode.hard_deny` (2.1.136)** | settings, guardrails, auto mode | Auto Mode classifier が"許可意図に関わらず必ず deny"を扱える | `A: Implemented` (`templates/claude/settings.security.json.template`).Phase 69.1.3 で template baseline 7 items (`Bash(sudo:*)` / `Bash(rm -rf:*)` / `Bash(rm -fr:*)` / `Bash(git push -f:*)` / `Bash(git push --force:*)` / `Bash(git reset --hard:*)` / `mcp__codex__*`) を Harness deny と整合.Plugin 本体 `.claude-plugin/settings.json` は self-write deny for release operator がManualマージ |
| **Claude Code `claude agents` agent view (2.1.139-2.1.142)** | agents, breezing, operator workflow | 全 CC session を 1 画面でMonitoringできる operator entrypoint.`--cwd`, `--add-dir`, `--settings`, `--mcp-config`, `--plugin-dir`, `--permission-mode`, `--model`, `--effort`, `--dangerously-skip-permissions` の 9 flag が dispatched background session をConfiguration | `A: Implemented` (`docs/agent-view-policy.md`, `docs/team-composition.md`, `agents/worker.md`).Phase 69.2.2 で teammate spawn workflow (breezing skill) とのIsolationとeach flag usage conditionsを明文化 |
| **Claude Code native `/goal` command (2.1.139)** | harness-plan, harness-work, Codex `/goal` Complement | 完了Conditionを turn more thanえで保持できる | `A: Implemented` (`docs/codex-plugin-workflows-policy.md`).Phase 69.2.1 で"session continuation memo 限定""Plans.md SSOT を奪わない""acceptance criteria を `/goal` only to置かない"3 規則を Codex `/goal` とIntegration |
| **Claude Code `claude plugin details <name>` (2.1.139)** | plugin observability, CI 補助 | plugin の component 内訳と projected per-session token cost が見える | `A: Implemented` (`docs/agent-view-policy.md`, `docs/upstream-update-snapshot-2026-05-15.md`).Phase 69.2.4 で CI / doctor の補助情報 as位置付け, plugin が session 予算閾Valueを越えた時の対応 step を docs 化 |
| **Claude Code hook `args: string[]` (exec form, 2.1.139)** | hooks, security, future-proof | shell を介さず command を直接 spawn できる | `A: Implemented` (`.claude/rules/hooks-2.1.139-plus.md`).Phase 69.1.4 で"path placeholder onlyは exec form Priority, shell 制御が必要な whenExisting `command` maintained"を rules 化 |
| **Claude Code hook `PostToolUse.continueOnBlock` (2.1.139)** | hooks, guardrails | hook の rejection reason を Claude に feedback し turn 継続できる | `A: Implemented` (`.claude/rules/hooks-2.1.139-plus.md`).Phase 69.1.4 で"diagnostic feedback only true, R01-R13 / secret / protected config では `false` Required"を rule 化 |
| **Claude Code hook `terminalSequence` (2.1.141)** | hooks, local notification | controlling terminal なしで desktop 通知 / window title / bell を発火 | `A: Implemented` (`scripts/lib/terminal-notify.sh`, `scripts/hook-handlers/webhook-notify.sh`, `scripts/hook-handlers/notification-handler.sh`).Phase 69.1.5 で `HARNESS_TERMINAL_NOTIFY` (`0` / `bell` / `title` / `osc9` / `notify`) opt-in Implementation.Existing `HARNESS_WEBHOOK_URL` と独立 |
| **Claude Code background permission mode 保持 (2.1.141)** | agents, breezing | `/bg` / `←←` / `claude agents` launched with teammate がLaunch時 mode を保持 | `A: Implemented` (`agents/worker.md`, `docs/team-composition.md`).Phase 69.2.3 で"Worker は permission mode 再注入不要, `bypassPermissions` even settings.json deny は override not"期待Valueを明文化 |
| **Claude Code hook config error (SessionStart/Setup/SubagentStart は command-only, 2.1.142)** | hooks, validation | bootstrap 段階の hook で LLM Type hook が拒絶 is | `A: Implemented` (`.claude/rules/hooks-2.1.139-plus.md`).Phase 69.1.4 と同 rule 内で"SessionStart/Setup/SubagentStart は `type: "command"` 限定"を grep-able にExplicit |
| **CC 2.1.142 fast mode Opus 4.7 default + `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE`** | model defaults | fast mode が常に Opus 4.7 で動く | `C: CC Auto-inherited`.Harness はalready Opus 4.7 を default as扱う for変更不要 |
| **CC 2.1.139 MCP stdio receives `CLAUDE_PROJECT_DIR`** | MCP setup | MCP server が project dir をResolutionできる | `C: CC Auto-inherited` |
| **CC 2.1.139 `x-claude-code-agent-id` / `parent-agent-id` headers + OTEL attrs** | OTel | subagent Monitoring性が上がる | `C: CC Auto-inherited` |
| **CC 2.1.141 `claude agents --cwd`** | operator UX | session list を directory scope できる | `A: Implemented` (`docs/agent-view-policy.md`).Phase 69.2.2 で project ごとのIsolationOperationを docs 化 |
| **CC 2.1.141 Rewind "Summarize up to here"** | session | context compression 中間状態保持 | `C: CC Auto-inherited`.`.claude/rules/commit-safety.md` の `/undo` policy と整合 |
| **CC 2.1.133/2.1.136-2.1.142 runtime bug fixes (parallel session credential race / MCP `/clear` persistence / OAuth refresh / extended thinking redaction / `--resume` underscore / WSL2 image paste / agent color palette / settings hot-reload symlink / spinner amber / 多数の plugin/MCP/UX Fix)** | runtime | safety / stability | `C: CC Auto-inherited`.Harness 側に wrapper added not |

**注記**:
Phase 69 even `B: 書いた only` は `0` itemsです.Feature Table は入口に留め, 公式 URL と version-by-version の判断根拠は `docs/upstream-update-snapshot-2026-05-15.md` に集約しま.`A` は実 file 変更 (settings / hooks / rules / docs / scripts) と紐付き, `C` は本体FixのAuto-inherited, `P` は推測Implementation notfuture判断 as扱います.

## FeatureDetails

### Task tool metrics

サブエージェントが消費 Token数 / ツール呼び出し数 / 実行 hours aggregatedできる.
`parallel-workflows` スキルでは複数サブエージェントのメトリクスを集約し, コスト minutes析に使用.

```
metrics: {tokens: 40000, tools: 7, duration: 67s}
```

### `/debug` Command

Session診断用Command.複雑なErrorや予期 not挙動の原因調査に使用.
`troubleshoot` スキルがAutomatic的にLaunchし, Issueを体系的に診断.

### PDF page range指定

大Type PDF loads際にページ範囲を指定可能 (Example: `pages: "1-5"`).
`notebookLM` スキル atドキュメント処理, `harness-review` at大TypeSpecification書参照 utilized in.

### Git log Flag

`git log` のStructure化Option (`--format`, `--stat`, `--since` 等)を活用.
リリースノート生成, コミット minutes析, 変更追跡を効率化.

### OAuth Authentication

DCR (Dynamic Client Registration)非対応 MCP サーバー to OAuth AuthenticationConfiguration.
`codex-review` スキル at Codex CLI Connectionに使用.

### 68% memory optimization

`--resume` FlagによるSession再開時のMemory使用量削減.
長 hoursworkSession atContext継続に有効.

### Subagent MCP

Task tool launched with サブエージェントが親Sessionの MCP ツールをSharingできる.
`task-worker` atParallelImplementation時に, eachエージェントが同じ MCP ツールセット used可能.

### Reduced Motion

Accessibility settings.モーション/アニメーションを削減 Option.
`harness-ui` スキルで UI 生成時に考慮.

### TeammateIdle/TaskCompleted Hook

Breezing チームのメンバーがアイドル状態 became時, alsoはタスク完了時に発火 フック.
`scripts/hook-handlers/teammate-idle.sh` と `task-completed.sh` で処理.

```json
"TeammateIdle": [{"hooks": [{"type": "command", "command": "...teammate-idle", "timeout": 10}]}],
"TaskCompleted": [{"hooks": [{"type": "command", "command": "...task-completed", "timeout": 10}]}]
```

### Agent Memory (memory frontmatter)

エージェントDefinition YAML の `memory: project` Fieldで永続Memory enables.
`task-worker`, `code-reviewer` が過去のImplementationパターン / 失敗とResolution策を跨ぎSessionで学習.

### Fast mode (Opus 4.6)

`/fast` Commandで切り替えるFast output mode.同じ Opus 4.6 モデル used.
All skillsで利用可能.長いImplementationタスク at待ち hours短縮に有効.

### Automatic memory recording

Session終了時に学習内容をAutomatic的にMemoryファイルへ永続化.
`session-memory` スキルがManagement.the nextSessionで前 timesの文脈をAutomatic復元.

### Skill budget scaling

SKILL.md の文字数予算がAuto-adjust to 2% of context window is.
Recommended 500 行は目安Value.実効Upper limitはモデルのContext窓サイズにDependency.

### Task(agent_type) restriction

Task tool 呼び出し時に `subagent_type` を指定し, サブエージェントのTypeを制限.
`agents/` Definition combined with, 意図 エージェント onlyをLaunch ことを保証.

### Plugin settings.json

プラグインの `settings.json` でInitialize時のConfigurationを事前Definition.
init Token消費を削減し, SecurityPolicyをSession開始直後 from適用.

### Worktree isolation

`git worktree` を使って同一ファイル toParallel書き込みを安全化.
`breezing` と `parallel-workflows` at複数エージェントParallelImplementation時のコンフリクト防止.

### Background agents

非SyncでバックグラウンドエージェントをLaunch.完了を待たずに他の処理を継続可能.
`generate-video` スキル at複数シーンParallel生成に使用.

### ConfigChange hook

Configurationファイル (`settings.json` 等)が変更 was時に発火 フック.
`scripts/hook-handlers/config-change.sh` で変更を記録 / 監査.

### last_assistant_message

Session終了時のthe lastアシスタントメッセージ referenceできるFeature.
`session-memory` スキルがSession品質の自己評価に使用.

### Sonnet 4.6 (1M context)

Maximum 1M TokenのContext窓 has Sonnet 4.6 モデル.
大規模コードベースの minutes析, 長大なドキュメント処理 supports.All skillsで利用可能.

> Note: 2.1.69 系では旧 Sonnet 4.5 参照は Sonnet 4.6 へAutomaticMigration is前提でOperation.

### Memory leak fix (v2.1.50-v2.1.63)

CC 2.1.50 で LSP 診断データ, 大TypeツールOutput, ファイル履歴, シェル実行に関 MemoryリークがFix was.
完了タスクのガベージコレクションもImplementationされ, `/breezing` 等の長 hoursチームSessionの安定性が大幅にImprovement.
v2.1.63 ではさらに MCP 再Connection時のリーク, git root Cache, JSON ParseCache, Teammate メッセージ保持, シェルCommandプレフィックスCacheのリークがAdditionFix was.
Harness 側は JSONL ローテーション (500→400 行)やアトミックUpdateでalready独自対策を実施済み.

### `claude agents` CLI (v2.1.50)

`claude agents list` で登録済みエージェントのList displays.
`troubleshoot` スキルでエージェント spawn 失敗時の診断 utilized in.

```bash
claude agents list # 登録済みエージェントのList
```

### WorktreeCreate/WorktreeRemove hook (v2.1.50)

Worktree の作成 / Deletion時に発火 ライフサイクルフック.
`/breezing` ParallelWorkflow atAutomaticSetup / Cleanup utilized in.
`scripts/hook-handlers/worktree-create.sh` と `worktree-remove.sh` でImplemented.

### `claude remote-control` (v2.1.51)

外部ビルドシステムとローカル環境のサービングを可能に サブCommand.
future的に Breezing のクロスSession制御や CI Integration utilized inの余地あり.

### `/simplify` (v2.1.63)

CC 2.1.63 でAddition wasImplementation後のAutomaticコード洗練Command.
`/work` の Phase 3.5 Auto-Refinement asIntegrationされ, Implementation完了後にAutomaticでコードを簡潔化 / 整理.
`code-simplifier` plugin combined with `--deep-simplify` Optionで深いリファクタリングも可能.

### `/batch` (v2.1.63)

横Decompressタスク (同じ変更を複数ファイル applied to Migration等)をParallel委任 Command.
`/breezing` combined with, Breezing チームに一括MigrationをParallel実行させる際に使用.
繰り返しworkの効率化と, 人為的ミスの削減に有効.

### `code-simplifier` plugin

`/simplify` deep refactoringModeを担う外部プラグイン.
`--deep-simplify` 指定時にLaunchし, 複雑なロジックの minutes解 / 不要な抽象化の除去 / 命名のImprovementをAutomatic実行.
通常の `/simplify` は軽量, `--deep-simplify` は from踏み込んだリファクタリングを実施.

### HTTP hooks (v2.1.63)

CC 2.1.63 でAddition was新しいフックFormat.Existingの `command` / `prompt` タイプ in addition to `http` タイプが利用可能 became.
JSON を指定 URL に POST し, 外部サービス (Slack, ダッシュボード, メトリクス収集等)とIntegrationできる.
Detailsは [.claude/rules/hooks-editing.md](../.claude/rules/hooks-editing.md) の"http Type"Section reference.

### Auto-memory worktree Sharing (v2.1.63)

CC 2.1.63 で `isolation: "worktree"` 使用時に Agent Memory が worktree 間でSharing isよう became.
`/breezing` のParallel Implementer がeach自 worktree Isolationでworkしながら, 同一の MEMORY.md reference / Update可能.
Implementer 間の知識Sharingと, 同一バグ to重複対応 prevents.

### `/clear` スキルCacheリセット (v2.1.63)

CC 2.1.63 でAddition wasスキルCacheのリセットCommand.
スキルファイルを編集後に古いCacheで動作 Issue (スキルDevelopment時に頻発)を `/clear` で解消できる.
`troubleshoot` スキルのCacheIssue診断Stepに組み込み済み.

### `ENABLE_CLAUDEAI_MCP_SERVERS` (v2.1.63)

CC 2.1.63 でAddition was環境Variable.`false` configured と claude.ai が提供 MCP サーバー disablesできる.
SecurityPolicy上, 外部 MCP サーバー toConnectionを制限 い環境 at利用を想定.
`setup` スキルの環境InitializeCheckListにAddition済み.

### Agent hooks (v2.1.68)

CC 2.1.68 でAddition was `type: "agent"` フック.LLM エージェントがフック判断を行うことで, 正規表現では検出困難なコード品質Issueを動的に判断できる.
Harness では3箇所に限定adoptedし, コストManagement for `model: "haiku"` と `matcher` でTargetを絞る:

- **PreToolUse Write|Edit**: シークレット埋め込み / TODO スタブ / Security脆弱性のガード
- **Stop**: WIP タスク残存ガード (Plans.md の `cc:WIP` タスクが残っていないかVerification)
- **PostToolUse Write|Edit**: 非SyncコードReview (品質 / 命名 / 単一責任)

効果不足時は `command` TypeにRollback可能なDesign.

### Effort levels + ultrathink (v2.1.68)

CC 2.1.68 で Opus 4.6 が **medium effort** をDefaultに変更.`ultrathink` キーワードで1ターン only high effort (extended thinking) enablesできる.
`harness-work` スキルが多要素スコアリング (変更ファイル数 / Targetディレクトリ / キーワード / 失敗履歴 / PM Explicit指定)でスコアを算出し, 閾Value 3 or moreで Worker spawn prompt 冒頭に `ultrathink` をAutomatic注入.
Detailsは `skills/harness-work/SKILL.md` の"Effort Level制御"Section参照.

### Opus 4/4.1 Deletion (v2.1.68)

CC 2.1.68 で Opus 4 と Opus 4.1 が first-party API fromDeletion was.Harness がTargetエージェントで `model: opus` 相当を指定 is場合, Opus 4.6 へAutomatic移行 is.
Worker/Reviewer エージェントは `model: sonnet` for影響なし.Lead (Opus 使用時) only medium effort がDefault becomes変更を受ける.

### `${CLAUDE_SKILL_DIR}` Variable (v2.1.69)

CC 2.1.69 でスキル実行時のCriteriaパスVariable `${CLAUDE_SKILL_DIR}` が導入 was.
Harness では `SKILL.md` from `references/*.md` reference リンクを `${CLAUDE_SKILL_DIR}/references/...` へ統一し, ミラーConfiguration (codex/opencode) even同じ参照 maintained.

### InstructionsLoaded hook (v2.1.69)

CC 2.1.69 で `InstructionsLoaded` イベントがAddition was.Harness では
`scripts/hook-handlers/instructions-loaded.sh` newly createdし, instructions 読み込み完了時の軽量トラッキングと事前Verificationに利用.

### `agent_id` / `agent_type` Addition (v2.1.69)

Teammate 系イベントに `agent_id` / `agent_type` がAddition was.
Harness の guardrail は `session_id` 前提 from `agent_id` Priority (fallback: `session_id`)へextendedし, role ガードを安定化.

### `{"continue": false}` teammate 応答 (v2.1.69)

`TeammateIdle` / `TaskCompleted` で `{"continue": false, "stopReason": "..."}` を返せるよう became.
Harness では stop RequestReceive時と全タスク完了時に同Response returns and, breezing のStop判定をExplicit化.

### `/reload-plugins` (v2.1.69)

スキル / フック編集後にSession再Launchなしで反映 for, DevelopmentFlowに `/reload-plugins` added.
編集 → `/reload-plugins` → 再実行, を標準Procedureと.

### `includeGitInstructions: false` (v2.1.69)

git 指示を常時埋め込む必要がないタスクでは `includeGitInstructions: false` を適用し, Token消費 suppressesできる.
Harness では breezing/work の軽量タスク (ドキュメントUpdateなど) at活用をRecommended.

### `git-subdir` plugin source (v2.1.69)

plugin source を monorepo のサブディレクトリ managed with `git-subdir` 方式がサポート was.
Harness では現状 `.claude-plugin/plugin.json` にAdditionFieldを強制せず, リリース時に `plugin source` をExplicit Operation (Compatible性Priority).

### Compaction 画像保持 (v2.1.70)

CC 2.1.70 でContextCompress (Compaction)時にサマリーRequestが画像を保持 よう became.
これ via, スクリーンショットや図表 includingSessionで Compaction 後も画像Contextが維持 is.
プロンプトCacheの再利用率もImprovementされ, 画像を扱うスキル全般で効率が向上.

### サブエージェント最終レポート簡潔化 (v2.1.70)

サブエージェント完了時の最終レポートが簡潔化され, Token消費が削減 was.
`breezing` や `harness-work` で多数のサブエージェントをLaunch when, 累積的なToken節約効果が大きい.

### `--resume` スキルList再注入Deprecated (v2.1.70)

`--resume` でSession再開 際, スキルListの再注入がDeprecated was.
これ via約 600 tokens が節約され, `session` スキル at再開Flowが軽量化.

### Plugin hooks Fix (v2.1.70)

v2.1.70 で複数の Plugin hooks RelatedバグがFix was:
- `Stop` / `SessionEnd` フックが `/plugin` Command実行後にも正常に発火
- 同一Template hasフック間の衝突が解消
- `WorktreeCreate` / `WorktreeRemove` フックの正常動作がVerification

### Teammate ネスト防止AdditionFix (v2.1.70)

v2.1.69 で対応済みの Teammate ネスト防止にAdditionFixが入った.
エージェントが別のエージェントを無限に spawn カスケードIssueの防止が強化 was.

### PostToolUseFailure hook (v2.1.70)

CC 2.1.70 で `PostToolUseFailure` イベントがAddition was.ツール呼び出しが失敗 whenに発火 新しいフックイベント.
Harness では `hooks` スキルと `error-recovery` で活用し, 連続失敗時のAutomaticエスカレーション (3 times連続失敗でStop)に使用.

```json
"PostToolUseFailure": [{
 "hooks": [{
 "type": "command",
 "command": "...post-tool-failure.sh",
 "timeout": 10
 }]
}]
```

### `/loop` + Cron スケジューリング (v2.1.71)

CC 2.1.71 で `/loop` CommandがAddition was.`/loop 5m <prompt>` のように間隔とプロンプトを指定 と, 定期的にCommand executes Cron 風スケジューリングが可能.
`breezing` では `/loop 5m /sync-status` でタスク進捗の定期Check utilized in.
Existingの `TeammateIdle` (受動的 / イベント駆動) unlike, 能動的に定期Monitoringを行える.

### Background Agent OutputパスFix (v2.1.71)

CC 2.1.71 で Background Agent の完了通知にOutputファイルパスが含まれるよう became.
これ via, Compress後 evenバックグラウンドエージェントのResultを安全に times収可能.
`breezing` や `parallel-workflows` at `run_in_background: true` が実用的に.

### `--print` チームエージェント hang Fix (v2.1.71)

`--print` Modeでチームエージェントが hang IssueがFix was.
CI Pipeline at `claude --print` 実行時のチームエージェント安定性が向上.

### Plugin InstallParallel実行Fix (v2.1.71)

複数の Claude Code インスタンスが同時にプラグインをInstall 際の状態競合がFix was.
`breezing` で複数 Teammate が同時にLaunch 際のプラグイン読み込み安定性が向上.

### Marketplace Improvement (v2.1.71)

CC 2.1.71 で Marketplace 周りに複数のImprovementが入った:
- `@ref` パーサーFix: `owner/repo@vX.X.X` Formatの参照Resolutionが正確に
- update 時の merge conflict Fix: プラグインUpdateが from安定に
- MCP server 重複排除: 同一 MCP サーバーの多重登録 prevents
- `/plugin uninstall` が `settings.local.json` used: ユーザーローカルConfiguration to正確な反映

### Per-agent hooks (v2.1.69+)

CC 2.1.69 でエージェントDefinitionの frontmatter に `hooks` FieldがAddition was.
グローバル hooks.json とは別に, エージェント固有のフック definesできる.

Harness at活用:
- **Worker**: `PreToolUse` で Write/Edit 時の `pre-tool.sh` ガードレールを適用
- **Reviewer**: `Stop` でReviewSession完了をLogOutput

エージェントDefinition内フックはそのエージェントのライフサイクル中 only有効で, 終了時にAutomaticCleanup is.

### Agent `isolation: worktree` (v2.1.50+)

エージェントDefinitionの frontmatter に `isolation: worktree` added と, 
そのエージェントがLaunch時にAutomaticで git worktree を作成し, 独立 リポジトリコピーでwork.
変更がない when worktree がAutomaticCleanup is.

Harness では Worker エージェントに `isolation: worktree` added.
`memory: project` combine withことで, worktree 間で Agent Memory (MEMORY.md)がSharingされ, 
Parallel Worker が同一の学習内容 reference / Update可能.

### Auto Mode rollout Policy

Auto Mode は Claude Code の team execution を from安全側に寄せる for移行候補 as整理 is.
However shipped default はnot yet `bypassPermissions` であり, project template や frontmatter には公式 docs に載っている permission mode only retained.

| レイヤー | adoptedValue | Reason |
|---------|--------|------|
| project template (`permissions.defaultMode`) | `bypassPermissions` | documented permission modes に `autoMode` が含まれない for |
| agent frontmatter (`permissionMode`) | `bypassPermissions` | 宣言的Configurationは documented Value only uses for |
| teammate 実行path | `bypassPermissions` (現行) | shipped default と実際の permission Inheritを一致させる for |
| `--auto-mode` | opt-in marker | 親SessionがCompatibleな permission mode in the case of only rollout を試す for |

DefaultCommandExample:

```bash
/breezing all
/execute --breezing all
```

### Subagent `background` Field

エージェントDefinitionの frontmatter に `background: true` added と, そのエージェントは常にバックグラウンドタスク as実行 is.
Explicit的に `run_in_background: true` を指定しなくても, Agent tool 経由 launched with たびにバックグラウンド実行 becomes.

```yaml
---
name: long-running-analyzer
background: true
---
```

Harness では `breezing` の Worker spawn 時に検討可能だが, 現状は Lead がExplicit的に `run_in_background` controls is for, Addition適用は Phase 2 +で検討.

### Subagent `local` MemoryScope

`memory: local` は `.claude/agent-memory-local/<name>/` saved toされ, `.gitignore` にAdditionすべきパス.
`project` との違い:

| Scope | パス | VCS コミット | ユースケース |
|---------|------|-------------|------------|
| `user` | `~/.claude/agent-memory/<name>/` | Target外 | 全プロジェクト共通の学習 |
| `project` | `.claude/agent-memory/<name>/` | Sharing可能 | チームSharingのプロジェクト知識 |
| `local` | `.claude/agent-memory-local/<name>/` | 非Recommended | items人固有 / 機密性の高い学習 |

Harness では Worker/Reviewer bothに `memory: project` used中.`local` は items人的なDebugパターンの記録に適 が, チームSharingをPriority for現行Configuration maintained.

### Agent Teams 実験Flag

Agent Teams は実験的Feature as `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 環境Variableで有効化 is.
settings.json 経由 evenConfiguration可能:

```json
{
 "env": {
 "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
 }
}
```

Harness の `breezing` スキルは Agent Teams Featureを前提 asいる for, 
Setup時にこの環境VariableがConfigurationされていること verify VerificationStep added.

### Desktop Scheduled Tasks

Desktop アプリの Scheduled Tasks は `~/.claude/scheduled-tasks/<task-name>/SKILL.md` saved to is.
YAML frontmatter で `name` と `description` definesし, 本文にプロンプトを記述.

ScheduleConfiguration (頻度 / 時刻 / フォルダ)は Desktop アプリの UI fromManagement.
`/harness-work` や `/harness-review` を定期実行 用途 utilized in可能.

### `/agents` Command

エージェントの対話的Managementインターフェース. or fewerの操作が可能:
- 利用可能な全エージェントのList表示 (built-in, user, project, plugin)
- Guide付き alsoは Claude 生成によるエージェント作成
- ExistingエージェントのConfiguration / ツールアクセス編集
- カスタムエージェントのDeletion

CLI fromの非対話的なList表示: `claude agents`

### `--agents` CLI Flag

SessionLaunch時に JSON でエージェントDefinition passes.ディスク saved toされない一時的なConfiguration:

```bash
claude --agents '{
 "quick-reviewer": {
 "description": "Quick code review",
 "prompt": "Review for critical issues only",
 "tools": ["Read", "Grep", "Glob"],
 "model": "haiku"
 }
}'
```

CI/CD Pipeline at一時的なエージェント注入に有用.

### `ExitWorktree` ツール (v2.1.72)

CC 2.1.72 で `ExitWorktree` ツールがAddition was.`EnterWorktree` で作成 was worktree Session fromプLogラム的に離脱できる.
従来は worktree Session終了時のプロンプトでManual選択 しかなかったが, エージェントがImplementation完了後にAutomaticで worktree を離脱できるよう became.

Harness at活用:
- `breezing` の Worker が `isolation: worktree` でwork完了後, `ExitWorktree` でExplicit的に worktree を閉じる
- worktree Cleanupの確実性が向上 (変更がない whenAutomaticDeletion isExisting動作と組み合わせ可能)

### Effort levels simplified (v2.1.72)

CC 2.1.72 で effort Levelが `low/medium/high` の3段階に簡素化 was.`max` LevelがDeprecatedされ, 表示シンボルが `○ ◐ ●` に統一 was.`/effort auto` でDefault (medium)にリセット可能.

Harness to影響:
- `ultrathink` キーワードによる high effort 注入はcontinuing to有効 (変更なし)
- harness-work のスコアリングロジックに変更は不要 (ultrathink → high effort の対応が維持)
- ドキュメント上の `max` to言及を `high` に統一

### Agent tool `model` Parameter復活 (v2.1.72)

CC 2.1.72 で Agent tool の `model` Parameterが復活.per-invocation でモデルを指定 サブエージェントをLaunchできる.
エージェントDefinitionの `model` Fieldとは別に, spawn 時に一時的なモデル指定が可能.

Harness at活用余地:
- 軽量タスク (ドキュメントUpdate, FormatFix等)には `model: "haiku"` で spawn コスト削減
- SecurityReviewやアーキテクチャ変更には `model: "opus"` で spawn 品質Maximum化
- 現状は Worker/Reviewer both `model: sonnet` locked.Lead がタスク特性 according to動的にモデルを切り替えるImplementationは Phase 2 +で検討

### `/plan` description Argument (v2.1.72)

CC 2.1.72 で `/plan` CommandがOptionの description Argumentを受け付けるよう became.
`/plan fix the auth bug` のように, 説明付きで即座にプランModeに入れる.

Harness at活用:
- `harness-plan` スキルの `create` サブCommandとComplement的に使用可能
- ユーザーが簡易にプランModeに入りたい場合のショートカット as案内

### Parallelツール呼び出しFix (v2.1.72)

CC 2.1.72 でParallelツール呼び出し時の重要なバグがFix was.
prior toは Read, WebFetch, Glob のanyが失敗 と, Parallel実行中の sibling 呼び出しもCancelされていた.
Fix後は Bash Error onlyがカスケードし, 他のツールの失敗は独立 処理 is.

Harness to影響:
- `breezing` や `harness-work` でファイル読み込みと Web 検索をParallel実行 際の安定性が向上
- 存在 notファイルの Read が他の正常な Read をCancel Issueが解消
- Worker エージェントの探索Phase at信頼性Improvement

### Worktree isolation fix (v2.1.72)

CC 2.1.72 で worktree isolation に関 2つのバグがFix was:

1. **Task resume の cwd 復元**: `resume` Parameterで再開 タスクが worktree のworkディレクトリを正しく復元 よう became
2. **Background 通知の worktreePath**: バックグラウンドタスクの完了通知に `worktreePath` Fieldが含まれるよう became

Harness to影響:
- `breezing` の Worker が `isolation: worktree` でworkし, Lead がResultを times収 際の信頼性が向上
- `run_in_background: true` で spawn Worker の完了通知 from worktree パス retrieves可能に

### `/clear` バックグラウンドエージェント保持 (v2.1.72)

CC 2.1.72 で `/clear` の動作が変更 was.フォアグラウンドのタスク onlyStopし, バックグラウンド executed with中のエージェントや Bash タスクは影響を受けなくなった.

Harness to影響:
- `breezing` のチーム実行中にユーザーが `/clear` もバックグラウンド Worker が存続
- Lead が `/clear` でContextを整理 も, 実行中のタスクが中断されない for安全性向上

### Hooks fixes (v2.1.72)

CC 2.1.72 で複数のフックRelatedバグがFix was:

1. **transcript_path**: `--resume` / `--fork` Session at `transcript_path` が正しくConfiguration isよう became
2. **PostToolUse BlockReasonの二重表示**: PostToolUse フックがBlock 際のReasonメッセージが2 times表示 isIssueがFix
3. **async hooks の stdin**: 非Syncフックが stdin を正しくReceive よう became
4. **skill hooks 二重発火**: スキルフックが1イベントにつき2 times発火 IssueがFix

Harness to影響:
- `pre-tool.sh` / `post-tool.sh` ガードレールフックの発火が正確に1 timesになり, Logの信頼性が向上
- `session-memory` の transcript 参照が `--resume` Session even正常動作

### HTML コメント非表示 (v2.1.72)

CC 2.1.72 で CLAUDE.md ファイル内の HTML コメント (`<!-- ... -->`)がAutomatic注入時に非表示 became.
Read ツールで直接ファイルを読んだ whencontinuing to可視.

Harness to影響:
- **実害なし**: 重要な指示やConfigurationは HTML コメント内に記述 notOperationを徹底

### Bash auto-approval Addition (v2.1.72)

CC 2.1.72 で or fewerのCommandが Bash auto-approval 許可ListにAddition was:
`lsof`, `pgrep`, `tput`, `ss`, `fd`, `fdfind`

Harness to影響:
- Worker がプロセスVerification (`pgrep`)やファイル検索 (`fd`)を権限プロンプトなし executed with可能に
- guardrails の `pre-tool.sh` はcontinuing toこれらのCommandを通過させる (BlockTarget外)

### プロンプトCacheFix (v2.1.72)

CC 2.1.72 で SDK の `query()` 呼び出し時のプロンプトCache無効化バグがFix was.
InputTokenコストがMaximum 12 倍削減 is.

Harness to影響:
- `breezing` や `harness-work` で多数のサブエージェント spawn を行う際のコスト大幅削減
- 特に同一Session内 at反復的な API 呼び出しパターンで効果大

### Output styles (v2.1.72+)

CC の Output styles Feature via, システムプロンプト自体をカスタマイズできる.
CLAUDE.md (ユーザーメッセージ asAddition)や Skills (特定タスク用)とは異なるレイヤー.

Harness では `.claude/output-styles/harness-ops.md` provides:
- `keep-coding-instructions: true` — コーディング指示 maintainedしつつOperationFlowを最適化
- Structure化 was進捗報告Format (実施/Current地/次アクション)
- Quality Gate の表FormatOutput
- Review 判定のStructure化Format
- エスカレーション (3 timesRule)の標準OutputFormat

```bash
# 有効化
/output-style harness-ops
```

### `permissionMode` in agent frontmatter (v2.1.72+)

公式ドキュメントで `permissionMode` がエージェント frontmatter の正式Field as文書化 was.

Harness to反映:
- Worker/Reviewer/Scaffolder の3エージェントallに `permissionMode: bypassPermissions` added
- spawn 時の `mode` 指定にDependency not宣言的権限Management achieves
- Auto Mode は rollout 候補 as整理し, 現行 shipped default は `bypassPermissions` のまま維持 

```yaml
# agents/worker.md frontmatter
permissionMode: bypassPermissions # Addition
```

### Agent Teams official best practices (v2.1.72+)

Claude Code 公式に `agent-teams.md` が独立ドキュメント as整備 was.
Harness の `docs/team-composition.md` に or fewer reflected:

1. **タスク粒度Guideライン**: 5-6 tasks/teammate のRecommendedValue
2. **`teammateMode` Configuration**: `"auto"` / `"in-process"` / `"tmux"` の公式サポート
3. **Plan Approval パターン**: Worker に plan mode を要求 公式パターン
4. **Quality Gate Hooks**: `TeammateIdle`/`TaskCompleted` のexit 2 フィードバックパターン
5. **チームサイズ**: 3-5 teammates のRecommendedValue (Harness の Worker 1-3 + Reviewer 1 と整合)

### Sandboxing (`/sandbox`)

Claude Code にネイティブIntegration was OS LevelのサンドボックスFeature.macOS は Seatbelt, Linux は bubblewrap usedし, Bash Commandのファイルシステム/Networkアクセスを制限.

**2つのMode**:
- **Auto-allow mode**: サンドボックス内のCommandはAutomaticApproval.Constraint外のアクセスは通常の権限FlowへFallback
- **Regular permissions mode**: サンドボックス内 even全CommandにApprovalが必要

**Harness at活用戦略**:
- `bypassPermissions` の **Complementレイヤー** as位置づける (置換ではない)
- Worker エージェントの Bash Commandに OS Levelの安全境界 added
- `sandbox.filesystem.allowWrite` で Worker が書き込める範囲をExplicit制限
- `sandbox.network` で外部アクセスを信頼済みドメインに制限 (エクスフィルトレーション防止)

**段階導入計画**:

| Phase | Worker 権限 | Sandbox |
|---------|-----------|---------|
| 現行 | `bypassPermissions` + hooks ガード | 未適用 |
| VerificationPhase | `bypassPermissions` + hooks + sandbox auto-allow | Worker の Bash applied to |
| 安定後 | sandbox auto-allow only (`bypassPermissions` Deprecated検討) | 全 Bash applied to |

```json
// settings.json (VerificationPhase用)
{
 "sandbox": {
 "enabled": true,
 "filesystem": {
 "allowWrite": ["~/.claude", "//tmp"]
 }
 }
}
```

> `@anthropic-ai/sandbox-runtime` が OSS as公開されており, MCP サーバーのサンドボックス化にも利用可能.

### `opusplan` モデルエイリアス

Plan mode では Opus, 実行Modeでは Sonnet にAutomatic切替 ハイブリッドエイリアス.

**Harness at活用**:
- Breezing の Lead Sessionに最適: Plan Phase (タスク minutes解 / アーキテクチャ決定)は Opus の推論力 utilized and, Worker spawn 後の実行コーディネーションは Sonnet でコスト効率化
- `claude --model opusplan` alsoは `/model opusplan` で有効化

**環境Variableによる制御**:
```bash
# opusplan の内部マッピングをカスタマイズ
ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4-6 # Plan 時
ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-6 # 実行時
```

### `CLAUDE_CODE_SUBAGENT_MODEL` 環境Variable

サブエージェント (Worker/Reviewer)のモデルを一括で指定 環境Variable.

**Harness at活用**:
- 現状: Worker/Reviewer は `model: sonnet` をエージェントDefinitionで固定
- 本環境Variable usesと, エージェントDefinitionを変更せずにモデルを切り替え可能
- CI 環境 atコスト制御 (`CLAUDE_CODE_SUBAGENT_MODEL=haiku` でTest実行)に有用

```bash
# 全サブエージェントを haiku executed with (CI コスト削減)
export CLAUDE_CODE_SUBAGENT_MODEL=claude-haiku-4-5-20251001
```

### `availableModels` Configuration

ユーザーが選択可能なモデルを制限 Configuration.managed/policy settings でConfiguration と, `/model`, `--model`, `ANTHROPIC_MODEL` のいずれ even制限が適用 is.

**Harness at活用**:
- エンタープライズ環境 atモデルガバナンス: Worker/Reviewer が意図 notモデル used こと prevents
- `availableModels` + `model` の組み合わせで全ユーザーのモデル体験を統制可能

```json
// managed settings
{
 "model": "sonnet",
 "availableModels": ["sonnet", "haiku", "opusplan"]
}
```

### Checkpointing (`/rewind`)

Session中のファイル編集をAutomatic追跡し, Optionalのポイントに巻き戻し可能に Feature.
eachユーザープロンプトでCheckポイントがAutomatic作成 is.

**操作方法**:
- `Esc + Esc` alsoは `/rewind` でリワインドメニューを開く
- 選択肢: コード復元 / 会話復元 / 両方復元 / ここ from要約

**Harness at活用**:
- `harness-work` のセルフReviewPhaseでIssue発見時, Implementation前の状態に巻き戻し
- "ここ from要約"で冗長なDebugSessionのContext窓を times収
- `/compact` との違い: Checkポイントは選択的にCompress範囲を指定できる

**制限事項**:
- Bash Commandによるファイル変更は追跡されない (`rm`, `mv`, `cp` 等)
- 外部のManual変更は追跡されない
- Git のAlternativeではなく, SessionLevelの"ローカル Undo"

### Code review (managed service)

Anthropic インフラ上で動作 マルチエージェント PR Reviewサービス.Teams/Enterprise 向け Research Preview.

**動作Overview**:
1. PR 作成/Update時にAutomaticLaunch
2. 複数の専門エージェントがParallelで差 minutesとコードベースを minutes析
3. VerificationStepで偽陽性をフィルタ
4. 重複排除 / 重要度ランク付け後にインラインコメント as投稿

**重要度Level**:
| マーカー | Level | 意味 |
|---------|--------|------|
| 🔴 | Normal | マージ前にFixすべきバグ |
| 🟡 | Nit | 軽微なIssue (ブロッキングではない) |
| 🟣 | Pre-existing | この PR prior to from存在 バグ |

**`REVIEW.md`**: リポジトリルートに配置 Review専用ガイダンスファイル.`CLAUDE.md` とは別に, Review時 only適用 isRule defines.

**Harness at活用**:
- `harness-review` スキルの Code Review 対応 as `REVIEW.md` Template生成を検討
- Harness の Worker セルフReviewと managed Code Review はComplement的 (ローカル + リモートの二重検査)
- Averageコスト $15-25/Review.`on-push` トリガーは push times数 minutesのコストが発生 forNote

### Status line (`/statusline`)

Claude Code のターミナル下部に表示 isカスタマイズ可能な状態バー.シェルScriptに JSON Sessionデータ passes and, Outputテキスト displays.

**利用可能データ**:
- `model.id`, `model.display_name` — Currentのモデル
- `context_window.used_percentage` — Context使用率
- `cost.total_cost_usd` — Sessionコスト
- `cost.total_duration_ms` — 経過 hours
- `worktree.*` — ワークツリー情報
- `agent.name` — エージェント名
- `output_style.name` — Outputスタイル名

**Harness at活用**:
- `scripts/statusline-harness.sh` で Harness 専用ステータスライン提供
- モデル名 / Context使用率 / Sessionコスト / git ブランチ / Harness バージョンを常時表示
- ANSI カラーでContext使用率のしきいValue表示 (70% 黄色, 90% 赤)

### 1M context window (`sonnet[1m]`)

Opus 4.6 と Sonnet 4.6 で利用可能な 100 万TokenContext窓.200K Tokenを more thanえると long-context pricing が適用 is.

**Harness at活用**:
- `harness-review` の大規模コードベース minutes析に有用
- `breezing` で多数のファイルを同時に扱うSession
- `/model sonnet[1m]` で有効化.`CLAUDE_CODE_DISABLE_1M_CONTEXT=1` で無効化可能

### Per-model prompt caching control

モデル別にプロンプトCache controls 環境Variable群.

| 環境Variable | 用途 |
|---------|------|
| `DISABLE_PROMPT_CACHING` | 全モデルのCache無効化 |
| `DISABLE_PROMPT_CACHING_HAIKU` | Haiku only無効化 |
| `DISABLE_PROMPT_CACHING_SONNET` | Sonnet only無効化 |
| `DISABLE_PROMPT_CACHING_OPUS` | Opus only無効化 |

**Harness at活用**:
- Debug時に特定モデルのCache disables 挙動 verify
- クラウドプロバイダ (Bedrock/Vertex)でCacheImplementationが異なる場合の選択的制御

### `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING`

Opus 4.6 / Sonnet 4.6 の Adaptive Reasoning disablesし, `MAX_THINKING_TOKENS` で制御 is固定 thinking budget に復帰 環境Variable.

**Harness at活用**:
- Tokenコストの予測可能性が必要な CI 環境で有用
- `harness-work` の effort スコアリングと排他的ではない (両方使用可能だが, 通常は adaptive thinking enabledに まま ultrathink で制御 方が効果的)

### Chrome integration (`--chrome`)

Claude Code の Chrome extendedFeatureとIntegrationし, ブラウザAutomatic化をターミナル from実行 beta Feature.
`--chrome` FlagでSessionLaunch, alsoは `/chrome` でSession内 from有効化.

**主要Feature**:
- ライブDebug: コンソールErrorを読み取り, 原因コードを即座にFix
- UI Test: フォームVerification, ビジュアルリグレッションVerification, ユーザーFlowVerification
- データ抽出: Web ページ fromStructure化データを抽出しローカルSave
- GIF 記録: ブラウザ操作シーケンスを GIF as記録

**Harness at活用**:
- `harness-work` at UI コンポーネントImplementation後のAutomaticVerification
- `harness-review` at Web アプリケーションのビジュアルReview
- `/chrome` 有効化で Worker がブラウザTest executes可能に

**Constraint**: Google Chrome / Microsoft Edge only.Brave, Arc 等は未対応.WSL 非対応.

### LSP サーバーIntegration (`.lsp.json`)

Language Server Protocol サーバーを Plugin 経由でIntegrationし, リアルタイムコード診断 provides.

**利用可能な LSP プラグイン**:
| プラグイン | Language Server | Install |
|-----------|----------------|------------|
| `pyright-lsp` | Pyright (Python) | `pip install pyright` |
| `typescript-lsp` | TypeScript Language Server | `npm install -g typescript-language-server typescript` |
| `rust-lsp` | rust-analyzer | rust-analyzer 公式Guide参照 |

**提供 isFeature**:
- 即座の診断: 編集後すぐにError/Warning displays
- コードナビゲーション: Definitionジャンプ, 参照検索, ホバー情報
- Type情報: シンボルのTypeとドキュメント表示

**ConfigurationExample** (`.lsp.json`):
```json
{
 "typescript": {
 "command": "typescript-language-server",
 "args": ["--stdio"],
 "extensionToLanguage": {
 ".ts": "typescript",
 ".tsx": "typescriptreact"
 }
 }
}
```

### `SubagentStart`/`SubagentStop` matcher

settings.json Levelでサブエージェントのライフサイクルを agent type 別にMonitoring フック.
公式ドキュメントで matcher にエージェント名を指定 パターンが文書化 was.

**Harness のImplementation**:
- `SubagentStart`: Worker/Reviewer/Scaffolder/Video Generator のLaunchを items別にトラッキング
- `SubagentStop`: eachエージェントの完了を items別 recorded in
- Existingの `subagent-tracker` Node.js Scriptに matcher added

```json
"SubagentStart": [
 { "matcher": "worker", "hooks": [{ "type": "command", "command": "...subagent-tracker start" }] },
 { "matcher": "reviewer", "hooks": [{ "type": "command", "command": "...subagent-tracker start" }] }
]
```

### Agent Teams: task dependencies

Agent Teams のタスクにDependency関係 configured可能.Dependencyタスク完了で blocked タスクがAutomatic unblock.

**動作**:
- タスクは `pending`, `in_progress`, `completed` の3状態
- 未ResolutionのDependencyがa/an pending タスクは claimed 不可
- Dependency完了時にAutomatic unblock (Manual介入不要)
- ファイルロックで複数 teammate の同時 claim prevents

**Harness at活用**:
- Breezing の Lead がタスク minutes解時にDependency関係をExplicit指定
- Example: "API EndpointImplementation"→"Test作成"→"ドキュメントUpdate"の順序保証

### `--teammate-mode` CLI Flag

Session単位で Agent Teams の表示Modeを指定 Flag.

```bash
claude --teammate-mode in-process # 全 teammate を同一ターミナル
claude --teammate-mode tmux # each teammate に items別ペイン
```

settings.json の `teammateMode` ConfigurationをOverride.VS Code Integrationターミナルでは `in-process` がRecommended.

### `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`

`=1` で全バックグラウンドタスクFeature disables 環境Variable.

**Harness at活用**:
- SecurityPolicyでバックグラウンド実行を制限 環境向け
- Breezing のバックグラウンド Worker spawn も無効化 is for, 使用時は要Note

### `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`

サブエージェントの auto-compaction しきいValueを調整 環境Variable (Default 95%).

**Harness at活用**:
- `50` にConfigurationで早期Compress enables.長 hours Worker の安定性向上
- Breezing の Worker が大量のファイル loads場合にContext溢れ prevents

### `cleanupPeriodDays` Configuration

サブエージェント transcript のAutomaticCleanup期間 controls Configuration (Default 30 days).
transcript は `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl` saved to.

### `/btw` サイドクエスチョン

CurrentのContextを保持 まま短い質問を行うCommand.
 times答後にメインの会話履歴に残らない for, Context窓を消費 not.

**サブエージェントとの使い minutesけ**:
- `/btw`: CurrentのContextで即答可能な質問 (ツールアクセスなし)
- サブエージェント: 独立 調査 / Implementationタスク (ツールアクセスあり)

### Plugin CLI Command群

プラグインの非対話的ManagementCommand.ScriptによるAutomatic化 supports.

```bash
claude plugin install <plugin> [--scope user|project|local]
claude plugin uninstall <plugin> [--scope user|project|local]
claude plugin enable <plugin> [--scope user|project|local]
claude plugin disable <plugin> [--scope user|project|local]
claude plugin update <plugin> [--scope user|project|local|managed]
```

### Remote Control 強化

`/remote-control` (`/rc`) でSession内 from Remote Control enables可能に.

**新Feature**:
- `--name "My Project"`: Session名の指定
- `--sandbox` / `--no-sandbox`: サンドボックスの有効化/無効化
- `--verbose`: DetailsLog表示
- `/mobile`: QR コード表示で iOS/Android アプリに素早くConnection
- Automatic再Connection: Network断 fromのAutomatic復帰 (10 minutes以内)
- `/config` → "Enable Remote Control for all sessions" で常時有効化

### `skills` Field in agent frontmatter

サブエージェントの frontmatter に `skills` Field addedし, Launch時にスキルの全コンテンツをプリロード.
親会話のスキルはInheritされない for, Explicit的にList need toa/an.

**Harness のImplementation状況**:
- Worker: `skills: [harness-work, harness-review]` — ImplementationとセルフReviewのスキルをプリロード
- Reviewer: `skills: [harness-review]` — Reviewスキルをプリロード
- Scaffolder: `skills: [harness-setup, harness-plan]` — Setupと計画スキルをプリロード

> `skills` in skill (`context: fork`) の逆パターン.skill が agent controls のではなく, agent が skill loads.

### `modelOverrides` Configuration (v2.1.73)

CC 2.1.73 でAddition wasConfiguration.モデルピッカー (`/model` メニュー)のエントリを, カスタムプロバイダのモデル ID にマッピングできる.
Bedrock ARN や Vertex AI のモデル ID など, プロバイダ固有の識別子を指定可能.

**Harness at活用**:
- エンタープライズ環境で Bedrock/Vertex 経由の Anthropic モデル used when, `modelOverrides` でモデルピッカーの表示名と実際のプロバイダモデル ID を対応付け
- Worker/Reviewer の `model: sonnet` がプロバイダ固有の ARN にAutomaticResolution is
- `availableModels` combined with, チーム全体のモデル体験を統制可能

```json
// settings.json
{
 "modelOverrides": {
 "sonnet": "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-sonnet-4-6-20250514-v1:0",
 "opus": "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-opus-4-6-20250610-v1:0"
 }
}
```

### `/output-style` 非Recommended化 (v2.1.73)

CC 2.1.73 で `/output-style` Commandが非Recommendedとなり, Outputスタイルの選択は `/config` メニューにIntegration was.
Existingの `/output-style harness-ops` 等はcontinuing to動作 が, 公式には `/config` 経由の選択がRecommended is.

**Harness to影響**:
- ドキュメント上の `/output-style harness-ops` to言及を `/config` 経由にUpdateRecommended
- `.claude/output-styles/harness-ops.md` 自体はcontinuing to有効 (Configurationファイルの配置場所に変更なし)
- スキル内で `/output-style` executes is箇所があれば `/config` に切り替え検討

### Bedrock/Vertex Opus 4.6 Default化 (v2.1.73)

CC 2.1.73 でクラウドプロバイダ (Amazon Bedrock / Google Vertex AI)上のDefault Opus モデルが 4.1 from 4.6 にUpdate was.
first-party API では v2.1.68 時点で Opus 4.6 がDefaultだったが, クラウドプロバイダ経由 even統一 was.

**Harness to影響**:
- Bedrock/Vertex 環境 even Lead (Opus 使用時)が medium effort Defaultで動作
- `opusplan` エイリアスが Bedrock/Vertex 環境 even Opus 4.6 reference
- `ANTHROPIC_DEFAULT_OPUS_MODEL` 環境VariableによるOverrideはcontinuing to有効

### `autoMemoryDirectory` Configuration (v2.1.74)

CC 2.1.74 でAddition wasConfiguration.AutomaticMemory (auto-memory)のSaveディレクトリをカスタマイズ可能.
Defaultの `~/.claude/` 配下 fromプロジェクト固有のパスに変更できる.

**Harness at活用**:
- 複数プロジェクトで Harness used when, プロジェクト perAutomaticMemoryをIsolation
- CI 環境で一時ディレクトリにMemoryをSaveし, Session終了時にCleanup
- Agent Memory (`memory: project`)とは異なるレイヤー (AutomaticMemoryはユーザーLevelの学習)

```json
// settings.json (プロジェクトLevel)
{
 "autoMemoryDirectory": ".claude/auto-memory"
}
```

### `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` (v2.1.74)

CC 2.1.74 でAddition was環境Variable.`SessionEnd` フックのTimeoutをミリ seconds単位で指定可能.
従来は固定 1.5 secondsで kill されていた for, 重いCleanup処理が完了前に中断 isIssueがあった.

**Harness at活用**:
- `SessionEnd` フックで `harness-mem` のSession記録や JSONL ローテーション executes when, 十 minutesなTimeoutを確保
- RecommendedValue: `5000` (5 seconds).複雑なCleanupが必要な when `10000` (10 seconds) up to

```bash
export CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000
```

### Full model ID fix (v2.1.74)

CC 2.1.74 で `claude-opus-4-6`, `claude-sonnet-4-6` 等の完全なモデル ID (ハイフン区切りFormat)がエージェント frontmatter and JSON config で正しく認識 isよう became.
従来はエイリアス (`opus`, `sonnet`) onlyが安定 動作 いた.

**Harness to影響**:
- エージェントDefinitionの `model` Fieldに完全モデル ID を指定可能に (Example: `model: claude-sonnet-4-6`)
- `--agents` CLI Flagの JSON 内 even完全モデル ID が使用可能
- 現状 Harness はエイリアス (`sonnet`, `opus`) used おり即時影響なし.Bedrock/Vertex 環境でフル ID 指定が必要な場合に有用

```yaml
# agents/worker.md frontmatter (完全モデル ID 使用Example)
model: claude-sonnet-4-6
```

### Streaming API Memory leak fix (v2.1.74)

CC 2.1.74 でストリーミング API ResponseBufferの無制限 RSS (Resident Set Size)増大がFix was.
長 hoursのストリーミングSessionで Node.js プロセスのMemory使用量が際限なく増加 Issueが解消.

**Harness to影響**:
- `breezing` の長 hoursチームSession at安定性が向上
- `harness-work` で大量のファイル読み書き including長 hours Worker SessionのMemory消費が安定化
- v2.1.50-v2.1.63 のMemory leak fixシリーズ (LSP 診断, ツールOutput, ファイル履歴等)に続くAdditionFix
- Harness 側の JSONL ローテーション対策 (独自のMemoryManagement) combined with, 二重の安定性確保

### `--remote` / Cloud Sessions

CC の `--remote` Flagでターミナル fromクラウドSessionをLaunchできる.タスクは Anthropic Managementの隔離 VM 上 executed withされ, 完了後に PR 作成が可能.

**Harness at活用**:
- `breezing` の大規模タスクをクラウドに委任し, ローカルリソースを節約
- `--remote` で複数タスクをParallelLaunch (eachタスクが独立 クラウドSession)
- `/teleport` でクラウドの成果物をローカルに取り込み, Follow-upの `/harness-review` connected to

```bash
# クラウドでタスク実行
claude --remote "Fix the authentication bug in src/auth/login.ts"

# 完了後にローカルに取り込み
/teleport
```

### `/teleport` (`/tp`)

クラウドSessionをローカルターミナルに取り込むCommand.`/teleport` alsoは `/tp` で対話的にSession selected, `claude --teleport <session-id>` で直接指定も可能.

**Prerequisites**:
- ローカルの git working directory がクリーン isこと
- 同一リポジトリ from実行 こと
- 同一 Claude.ai アカウントでAuthenticationされていること

### `CLAUDE_CODE_REMOTE` 環境Variable

クラウドSession内では `CLAUDE_CODE_REMOTE=true` がConfiguration is.Harness の `session-env-setup.sh` はこのValueを `HARNESS_IS_REMOTE` as永続化し, 他のフックハンドラがローカル専用処理をSkip 判定に使用可能.

```bash
# フックScript内 atクラウド検出Example
if [ "$HARNESS_IS_REMOTE" = "true" ]; then
 # クラウド環境ではローカル専用処理をSkip
 exit 0
fi
```

### `CLAUDE_ENV_FILE` SessionStart 永続化

CC の `SessionStart` フックは `CLAUDE_ENV_FILE` 環境Variableが指すファイルに `KEY=VALUE` writesことで, Follow-upの Bash Commandにも環境Variableを永続化できる.

Harness の `session-env-setup.sh` はこの機構 utilized and, `HARNESS_VERSION`, `HARNESS_AGENT_TYPE`, `HARNESS_IS_REMOTE` 等をSession全体で利用可能に is.

### Slack integration (`@Claude`)

Slack チャネルで `@Claude` にコーディングタスクをメンション と, Automatic的にクラウドSessionが作成 is.GitHub リポジトリとのIntegrationが前提.

**Harness との関係**:
- Harness の HTTP hooks (`type: "http"`)を Slack Webhook URL にConfiguration ことで, タスク完了時の Slack 通知が可能
- クラウドSession内 even `.claude/settings.json` のフックが動作 for, Harness のガードレールは Slack 経由のタスクにも適用 is

### Server-managed settings (public beta)

Claude.ai のManagement画面 fromチーム全体の Claude Code Configurationをサーバー配信 Feature.Teams/Enterprise 向け.

**Harness at活用**:
- チーム全体の `permissions.deny` Ruleを一括Management
- Harness のフックConfigurationをサーバー経由で配信 (HoweverフックConfigurationはSecurityVerificationダイアLogが表示 is)
- `availableModels` + `model` の組み合わせでチームのモデル体験を統制

### Microsoft Foundry

Azure ベースの新クラウドプロバイダ.Bedrock / Vertex に続く第3のサードパーティプロバイダ asAddition.
`modelOverrides` Configurationで Foundry のモデル ID にマッピング可能.

### `PreCompact` hook

ContextCompressが実行 is直前に発火 フックイベント.Harness では or fewerの2層でImplemented:

1. **`pre-compact-save.js`**: Session状態 (進捗, メトリクス)を永続化
2. **agent hook**: `cc:WIP` タスクが残っていないかCheckし, Warningメッセージ injected

```json
"PreCompact": [
 { "hooks": [
 { "type": "command", "command": "...pre-compact-save.js" },
 { "type": "agent", "prompt": "Check Plans.md for WIP tasks...", "model": "haiku" }
 ]}
]
```

### `Notification` hook event

Claude Code が通知を発行 際に発火 フックイベント.プラグインリファレンスに記載.
外部Monitoringツールやダッシュボード to通知Forward utilized in可能.

### `--plugin-dir` Specification変更 (v2.1.76, breaking)

**変更内容**: `--plugin-dir` が1つのパス onlyを受け付けるように変更.複数ディレクトリは繰り返し指定.

```bash
# 旧 (非対応に)
claude --plugin-dir path1,path2

# 新
claude --plugin-dir path1 --plugin-dir path2
```

**Harness to影響**: Harness プラグイン only used 一般的なConfigurationでは影響なし.
複数プラグインを同時使用 when only構文変更が必要.

---

## Claude Code 2.1.76 新Feature

### MCP Elicitation サポート

**動作Overview**: MCP サーバーがタスク実行中にユーザーへStructure化 wasInputを要求できるProtocol.フォームField alsoはブラウザ URL viaインタラクティブなダイアLog displays.

**Harness at活用**:
- Breezing のバックグラウンド Worker/Reviewer は UI 対話不能な for, `Elicitation` フックでAutomaticSkip implements
- 通常Sessionではas-is通過 (ユーザーが対話で応答)
- Go hookhandler が旧CompatibleLog `.claude/state/elicitation-events.jsonl` in addition toて, `elicitation-event.v1` を `.claude/state/elicitation/events.jsonl` に append-only 記録
- harness-mem が healthy な時 only `/v1/events/record` へ `event_type: "elicitation_event"` as best-effort Forwardし, 不達時は local ledger に silent fallback

**Constraint事項**:
- バックグラウンドエージェントでは elicitation に応答不能 (フックによるAutomatic処理がRequired)
- MCP サーバー側が elicitation をサポート is必要がa/an
- Claude-harness は harness-mem DB を直接読まない

### `Elicitation`/`ElicitationResult` フック

**動作Overview**: MCP Elicitation の前laterインターセプト可能な2つの新フックイベント.`Elicitation` はResponseが MCP サーバーに返 is前に, `ElicitationResult` は返 was後に発火.

**Harness at活用**:
- `Elicitation`: Breezing Session中のAutomaticSkip判定 + Log記録 + `capability_probe` event 記録
- `ElicitationResult`: ResultのLog記録 (`.claude/state/elicitation-events.jsonl`)+ `eval_result` event 記録
- hooks.json に両イベントのハンドラを登録

**Constraint事項**:
- `Elicitation` フックでBlock (deny) とMCPサーバー toInputが届かない
- Recommended timeout: Elicitation 10s / ElicitationResult 5s

### `PostCompact` フック

**動作Overview**: Contextコンパクション完了後に発火 新フックイベント.`PreCompact` フック (Existing)と対 becomes.

**Harness at活用**:
- コンパクション後のContext再注入 (WIP タスク状態の復元)
- `.claude/state/compaction-events.jsonl` にイベント記録
- 長 hoursSession at状態継続性向上
- PreCompact (状態Save)→ PostCompact (状態復元)の対称Structure

**Constraint事項**:
- Recommended timeout: 15s
- コンパクション失敗時 (circuit breaker 発動時)は PostCompact が発火 not可能性あり

### `-n`/`--name` CLI Flag

**動作Overview**: SessionLaunch時に表示名 configured CLI Flag.`claude -n "auth-refactor"` のように使用し, SessionList at識別 utilized in.

**Harness at活用**:
- Breezing Sessionに `breezing-{timestamp}` Formatの名前をAutomaticConfiguration
- SessionList atフィルタリング / 追跡 utilized in
- Log minutes析時のSession特定が容易に

**コードExample**:
```bash
claude -n "breezing-$(date +%Y%m%d-%H%M%S)"
```

### `worktree.sparsePaths` Configuration

**動作Overview**: 大規模モノレポで `claude --worktree` 使用時に, git sparse-checkout via必要なディレクトリ onlyをCheckアウト Configuration.ワークツリー作成のPerformanceを大幅にImprovement.

**Harness at活用**:
- Breezing のParallel Worker Launch hoursを短縮 (大規模リポジトリ)
- `.claude/settings.json` でConfiguration:
```json
{
 "worktree": {
 "sparsePaths": ["src/", "tests/", "package.json"]
 }
}
```

**Constraint事項**:
- sparse-checkout されていないパスのファイルは Worker fromアクセス不可
- Dependency関係のa/anディレクトリはall sparsePaths に含める必要がa/an

### `/effort` スラッシュCommand

**動作Overview**: Session中に effort Level (low/medium/high)を切り替えるスラッシュCommand.`/effort auto` でDefaultにリセット.

**Harness at活用**:
- harness-work の多要素スコアリングとIntegrationし, タスク複雑度 tailored to effort 制御が可能
- 複雑なタスクでは `/effort high` (ultrathink 有効化)をManualでConfiguration可能
- 簡易タスクでは `/effort low` でToken消費 suppresses

### `--worktree` Launch高速化

**動作Overview**: git refs の直接読み取りと, リモートブランチが利用可能な場合の冗長な `git fetch` Skip via, `--worktree` のLaunch hoursを短縮.

**Harness at活用**:
- Breezing の Worker LaunchオーバーヘッドがAutomatic的に削減
- 特に多数の Worker を同時Launch whenに恩恵が大きい

### バックグラウンドエージェント部 minutesResult保持

**動作Overview**: バックグラウンドエージェントが kill was場合にも, 部 minutes的なResultが会話Context saved to is.

**Harness at活用**:
- Breezing の Worker がTimeoutやManualStopで中断 was場合, workの一部が Lead に伝達 is
- Worker の途中成果物を活用 再割り当てが可能に
- "やり直し"の無駄が削減

### stale worktree AutomaticCleanup

**動作Overview**: 中断 wasParallel実行で残った stale ワークツリーがAutomatic的にCleanup is.

**Harness at活用**:
- `worktree-remove.sh` によるManualCleanupのComplement
- Breezing Sessionのクラッシュ後もAutomatic times復
- ディスク容量の無駄な消費 prevents

### Automaticコンパクション circuit breaker

**動作Overview**: Automaticコンパクションが連続 失敗 when, 3 timesでStop サーキットブレーカーが導入 was.無限RetryによるToken浪費 prevents.

**Harness at活用**:
- Harness の"3 timesRule" (CI失敗時の3 times制限)と一致 Design思想
- 長 hours Breezing Session at予期せぬコスト増加 prevents
- circuit breaker 発動時は PostToolUseFailure フックとIntegration エスカレーション

### Deferred Tools SchemaFix

**動作Overview**: `ToolSearch` で読み込んだツールがコンパクション後にInputSchemaを失い, Array / 数ValueParameterがTypeErrorでRejection isIssue fixed.

**Harness at活用**:
- 長 hoursSession at ToolSearch 経由ツールの安定性が向上
- Breezing のコンパクション後もMCPツールが正常に動作

### `/context` command (v2.1.74)

**動作Overview**: Context窓の消費状況を minutes析し, Contextを圧迫 isツールやMemoryを特定.アクション可能な最適化提案 (不要な MCP サーバーの切断, 肥大化 Memoryの整理等) displays.

**Harness at活用**:
- 長 hours Breezing Session at"なぜコンパクションが頻繁に起きるのか"の原因特定
- 大量の hooks や MCP サーバーがConnection was環境 atContext最適化
- Session中に `/context` executes only with即座に minutes析Resultが得られる

**Constraint事項**:
- Session中 only利用可能 (バッチModeでは非対応)
- サブエージェント内では利用不可

### `maxTurns` エージェント安全制限

**動作Overview**: サブエージェントのMaximumターン数を制限 frontmatter Field.Configurationターン数に到達 と, エージェントはAutomatic的にStop Result returns.CC 公式ドキュメントでRecommendedされている安全機構.

**Harness at活用**:
- Worker: `maxTurns: 100` — 複雑なImplementationタスク向け.十 minutesな余裕を持ちつつ暴走 prevents
- Reviewer: `maxTurns: 50` — Read-only minutes析に特化.50 ターンで完了 not whenIssueあり
- Scaffolder: `maxTurns: 75` — 足場構築と状態Updateの中間的な複雑度

**Design判断**:
- Upper limitに達 when, Lead が途中Resultを times収 判断可能
- `bypassPermissions` combine withことで, 暴走時の安全弁 asFeature

### `Notification` フックImplementation

**動作Overview**: Claude Code が通知を発行 際に発火 フックイベント.`permission_prompt` (権限Verification), `idle_prompt` (アイドル通知), `auth_success` (Authentication成功)等のイベントをインターセプト.

**Harness at活用**:
- `notification-handler.sh` で全通知イベントを `.claude/state/notification-events.jsonl` にLog記録
- Breezing のバックグラウンド Worker で発生 `permission_prompt` を追跡 (事後 minutes析用)
- hooks-editing.md では v3.10.3 fromドキュメント化済みだったが, hooks.json toImplementationが今 times完了

**LogFormat**:
```json
{"event":"notification","notification_type":"permission_prompt","session_id":"...","agent_type":"worker","timestamp":"2026-03-15T..."}
```

### Output token limits 64k/128k (v2.1.77)

CC 2.1.77 で Opus 4.6 と Sonnet 4.6 のDefaultMaximumOutputTokenが 64k に引き上げられ, Upper limitが 128k Token up toextended was.

**Harness to影響**:
- 長いImplementationコードや大規模リファクタリングのOutputがトランケートされにくくなった
- Worker エージェントが大量のファイル変更を一度にOutput whenの信頼性が向上
- 128k Outputはコスト増大につながる for, コストManagementにも留意が必要

### `allowRead` sandbox Configuration (v2.1.77)

`sandbox.filesystem.denyRead` で広範囲をBlockしつつ, `allowRead` で特定パスの読み取りを再許可できるよう became.

**Harness at活用**:
- Reviewer エージェントのサンドボックスで `/etc/` を denyRead しつつ, 特定のConfigurationファイル only allowRead 
- SecurityReview時に機密ディレクトリの制限付き読み取りアクセス provides

### PreToolUse `allow` respects `deny` (v2.1.77)

CC 2.1.77 で PreToolUse フックが `"allow"` を返 も, settings.json の `deny` パーミッションRuleがcontinuing to適用 isよう became.prior toはフックの `allow` がグローバル `deny` をOverride いた.

**Harness to影響**:
- guardrails のSecurityモデルが強化 was
- `deny: ["mcp__codex__*"]` を settings.json にConfigurationすれば, PreToolUse フックの判断に関わらず確実にBlock
- `.claude/rules/codex-cli-only.md` のフックベース MCP Block in addition to, settings.json deny がRecommendedパターンに

### Agent `resume` → `SendMessage` (v2.1.77)

CC 2.1.77 で Agent tool の `resume` ParameterがDeprecated was.Stop中のエージェントを再開 には `SendMessage({to: agentId})` used.`SendMessage` はStop中のエージェントをAutomaticでバックグラウンド再開.

**Harness at影響**:
- `breezing` スキルの Lead が Worker/Reviewer と通信 際は `SendMessage` used
- `team-composition.md` の Lead Phase B で `SendMessage` が正式なコミュニケーション手段 as記載

### `/branch` (formerly `/fork`) (v2.1.77)

CC 2.1.77 で `/fork` Commandが `/branch` にリネーム was.`/fork` はエイリアス ascontinuing toFeature.

### `claude plugin validate` enhanced (v2.1.77)

CC 2.1.77 で `claude plugin validate` がスキル / エージェント / Commandの YAML frontmatter と hooks.json の構文をVerification よう became.

**Harness at活用**:
- CI Pipelineに `claude plugin validate` addedし, frontmatter Errorを早期検出
- `tests/validate-plugin.sh` のComplement as活用可能

### `StopFailure` hook event (v2.1.78)

CC 2.1.78 で `StopFailure` イベントがAddition was.API Error (レート制限 429, Authentication失敗 401 等)でSessionStopが失敗 際に発火.

**Harness at活用**:
- `stop-failure.sh` ハンドラーでError情報を `.claude/state/stop-failures.jsonl` にLog記録
- Breezing の Worker がレート制限でStop失敗 whenの事後 minutes析に使用
- 10 secondsTimeoutの軽量ハンドラー asImplementation (復旧処理は不要)

### Hooks conditional `if` field (v2.1.85)

CC 2.1.85 で, hooks Definitionに `if` Conditionを付けて"どんなInputの when only hook を走らせるか"を細かく絞れるよう became.Permission rule syntax usesので, `Bash(git status*)` のようにツール名とInputパターンをまとめて指定できる.

**Harness at活用**:
- `PermissionRequest` を 2 系統に minutes割し, `Edit|Write|MultiEdit` は常時評価, `Bash` は安全Command候補 onlyを `if` で事前フィルタ 
- `hooks/permission.sh` 自体の安全判定は残しつつ, そもそも不要な Bash permission hook のLaunch数を減らす
- `MultiEdit` も matcher に含め, core guardrail では対応済みだったAutomaticApprovalの取りこぼしを hooks 側 evenなく 

**ユーザー体験のImprovement**:
- 今 up to: Bash の権限Verificationは広く hook が走り, finallyスルー isケース evenLaunchコストがかかっていた
- 今後: safe-read / test 系の Bash only to hook が走る for, 応答ノイズと無駄な評価を減らしつつ, AutomaticApprovalの精度は維持できる

### `${CLAUDE_PLUGIN_DATA}` Variable (v2.1.78)

CC 2.1.78 で `${CLAUDE_PLUGIN_DATA}` ディレクトリVariableがAddition was.プラグインUpdate even永続 ステートStorage as使用できる.

**Harness at活用余地**:
- Currentは `${CLAUDE_PLUGIN_ROOT}/.claude/state/` used isが, プラグインUpdateで消える可能性
- 長期的にはメトリクス / 通知Log等の永続データを `${CLAUDE_PLUGIN_DATA}` に移行を検討
- 移行パターン: `STATE_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PLUGIN_ROOT}/.claude/state}"`

### Agent frontmatter: `effort`/`maxTurns`/`disallowedTools` (v2.1.78)

CC 2.1.78 でプラグインエージェントDefinitionの frontmatter に `effort`, `maxTurns`, `disallowedTools` が公式サポート was.

**Harness at現状**:
- `maxTurns`: v3.10.4 でalreadyImplemented (Worker: 100, Reviewer: 50, Scaffolder: 75)
- `disallowedTools`: Worker は `[Agent]`, Reviewer は `[Write, Edit, Bash, Agent]` でImplemented
- `effort`: 未使用.Worker/Reviewer Definitionに `effort` Field added , Default thinking Levelを宣言的に制御可能

### `deny: ["mcp__*"]` fix (v2.1.78)

CC 2.1.78 で settings.json の `deny` パーミッションRuleが MCP サーバーツールに対 正しくFeature ようにFix was.

**Harness at活用**:
- `.claude/rules/codex-cli-only.md` でRecommended is Codex MCP Blockを, フックベース from settings.json `deny` に移行可能
- `"permissions": { "deny": ["mcp__codex__*"] }` がクリーンなパターン

### `--console` auth flag (v2.1.79)

CC 2.1.79 で `claude auth login --console` FlagがAdditionされ, Anthropic Console API 課金 atAuthentication supports.

### SessionEnd hooks `/resume` fix (v2.1.79)

CC 2.1.79 で対話的 `/resume` Session切替時に `SessionEnd` フックが正常に発火 よう became.prior toはSession切替時に SessionEnd が発火 did not for, cleanup 処理が実行されないケースがあった.

### `PermissionDenied` hook event (v2.1.89)

CC 2.1.89 で auto mode classifier がCommandをRejection 際に `PermissionDenied` フックが発火 よう became.`{retry: true}` returnsとモデルにRetry可能 isことを伝えられる.Rejection wasCommandは `/permissions` → Recent タブにも表示 is.

**Harness at活用**:
- `permission-denied-handler.sh` をNewImplementationし, Rejectionイベントを `permission-denied.jsonl` に telemetry 記録
- Breezing Worker がRejection was場合, Lead に `systemMessage` で通知しAlternativeアプローチの検討 promotes
- `agent_id` / `agent_type` Fieldを活用 , どのエージェントが何をRejection was whether追跡

**ユーザー体験のImprovement**:
- 今 up to: auto mode のRejectionは通知 only with記録に残らず, 同じRejectionが繰り返されやすかった
- 今後: Rejectionパターンが蓄積され, Breezing では Lead が即座に認知 対応できる

### `"defer"` permission decision (v2.1.89)

CC 2.1.89 で PreToolUse フック from `"defer"` permission decision を返せるよう became.ヘッドレスSession (`-p` Mode)でフックが defer returnsとSessionが一時Stopし, `claude -p --resume` で再開時にフックが再評価 is.

**Harness at活用余地**:
- Breezing Worker が本番環境 to書き込みや外部サービス toRequestなど, 判断困難な操作に遭遇 際の安全弁
- `pre-tool.sh` の guardrail に"defer Condition" addedし, 特定パターンで Worker を一時Stop→Lead が判断
- at this timeFeatureの文書化 only.具体的な defer RuleはOperationパターンの蓄積後にDesign

### Hook output >50K disk save (v2.1.89)

CC 2.1.89 でフックOutputが 50K 文字を more thanえる場合, Context to直接注入ではなくディスク saved toされ, ファイルパス+プReview as参照 is.

**Harness to影響**:
- 大量のOutput returns可能性のa/anフック (quality-pack, ci-status-checker 等)はこの挙動を前提にDesign
- 現状の Harness フックはOutputが軽量 for直接影響は小さいが, futureのextended時のDesignConstraint as文書化

### PreToolUse exit 2 JSON fix (v2.1.90)

CC 2.1.90 で PreToolUse フックが JSON を stdout にOutput exit code 2 で終了 際のBlock動作がFix was.prior toはこのパターンでBlockが正しくFeature notバグがあった.

**Harness to影響**:
- `pre-tool.sh` は deny 時に JSON + exit 2 パターン used おり, v2.1.90 +で guardrail の deny が from確実に動作
- Existingのガードレールが"deny を出 のにツールが実行 was"ケースがあった場合, このバグが原因だった可能性

### Built-in slash commands を Skill tool from呼ぶ際の Harness 影響 (v2.1.108)

CC 2.1.108 +, モデルが `Skill` tool via `/init`, `/review`, `/security-review` などの
built-in slash commands を呼び出せるよう became.これ via Harness スキルが CC の組み込みFeatureを
内部 from呼び出すConfigurationが可能 becomesが, Harness 独自の `/harness-review` との役割重複にNoteが必要.
具体的には, `Skill` tool 経由で `/review` を呼び出 when, Harness の guardrails (R01-R13)が
適用されない CC ネイティブのReviewが実行 is.Harness のReviewFlowでは
`/harness-review` alsoは `codex-companion.sh review` を経由させることで guardrails の保護と
`review-result.v1` Format to正規化が維持 is.built-in slash command の Skill tool 呼び出しは
軽量な inline ReviewやInitialize処理に限定し, 品質Gateを要 Reviewには使用 not.

## v2.1.99-v2.1.110 + Opus 4.7 DetailsSection (Phase 44.11.1)

> このSectionは `.claude/rules/cc-update-policy.md` の 3 カテゴリ minutes類 (A/B/C)に準拠.
> B minutes類は **0 items**.A = Implemented, C = CC Auto-inherited.

### PreCompact hook 3-way decision API (v2.1.99)

**付加価Value**: `A: Implemented` (hooks/hooks.json PreCompact エントリ, Phase 44.13 confirmed with済み)

CC 2.1.99 で PreCompact フックが `"block"` / `"allow"` / `"defer"` の 3-way decision API supports.
それ up toは `block` / `allow` の 2 択 onlyで, "later判断"の選択肢がなかった.

**Harness at活用**:
- Breezing Worker が cc:WIP 状態の when compaction を `"block"` し, WIP 完了後に `"allow"` パターンが安全にImplementationできる
- `hooks/hooks.json` の PreCompact ハンドラは `bin/harness pre-compact` 経由で Plans.md の cc:WIP detectsし block returns
- `"defer"` はヘッドレス環境 atCondition付き延期 utilized in予定 (Currentは block/allow の 2-way used)

**ユーザー体験のImprovement**:
- 今 up to: WIP 中の compaction preventsには `block` しかなく, 長 hours Worker では不要な compaction 抑止が続くIssueがあった
- 今後: `defer` で"今はダメだが resume 後に再評価"を指示でき, Worker 完了と同時に compaction が適切に走る

### ENABLE_PROMPT_CACHING_1H opt-in (v2.1.108)

**付加価Value**: `A: Implemented` (`scripts/enable-1h-cache.sh`, Phase 44.6.1 でImplemented)

CC 2.1.108 で `ENABLE_PROMPT_CACHING_1H=1` 環境Variableによる 1 hours prompt cache TTL がAddition was.
Defaultの 5 minutes TTL では 30 minutes more thanのSessionでCacheミスが頻発しコスト増大 いた.

**Harness at活用**:
- `scripts/enable-1h-cache.sh` executes と `env.local` に `ENABLE_PROMPT_CACHING_1H=1` を idempotent に追記
- `skills/breezing/SKILL.md` と `skills/harness-loop/SKILL.md` の開始前Recommended as記載
- `docs/long-running-harness.md` に選択Criteriaテーブル (Session 30 minutes more thanなら 1h cache) added

**ユーザー体験のImprovement**:
- 今 up to: 長 hours Breezing Sessionで cache miss が増え, 同じ CLAUDE.md や hooks.json が繰り返し課金されていた
- 今後: 1h TTL でCacheヒット率が大幅向上.長 hoursタスクのコストを削減できる

### /undo (rewind alias) (v2.1.108)

**付加価Value**: `A: Implemented` (`.claude/rules/commit-safety.md`, Phase 44.7.1 でImplemented)

CC 2.1.108 で `/rewind` のエイリアス as `/undo` がAddition was.Session内の直前ツール呼び出しを取り消す.

**Harness at活用**:
- `.claude/rules/commit-safety.md` に `/undo` の動作Definition / 利用Constraint / Prohibitedパターンを明記
- Worker / Reviewer が自律的に `/undo` executes ProhibitedCondition (git commit 後の取り消しは `git revert` uses)を文書化
- commit 済みの変更を間違えて `/undo` で消すリスク prevents

**ユーザー体験のImprovement**:
- 今 up to: `/rewind` と `/undo` の使い minutesけが曖昧で, エージェントが誤用 リスクがあった
- 今後: Harness Ruleで"`/undo` = Session内ファイル変更の取り消し""commit 後は `git revert`"と明確にIsolation

### PermissionRequest updatedInput / additionalContext (v2.1.110)

**付加価Value**: `A: Implemented` (`go/internal/guardrail/cc2110_regression_test.go`, Phase 44.3.1 でImplemented)

CC 2.1.110 で PermissionRequest フックに `updatedInput` と `additionalContext` FieldがAddition / 整備 was.
`updatedInput` で CC が再評価 Input passes and, `setMode: dontAsk` で mode 変更後も deny Ruleが再適用 is.

**Harness at活用**:
- `go/internal/guardrail/cc2110_regression_test.go` に 3 グループのリグレッションTest added
 - `updatedInput` + `setMode` → deny Rule (R01, R02, R06)が再評価後も適用 isことをVerification
 - `additionalContext` が JSON round-trip で保持 isこと verify (R09 Warningパス)
 - Bash bypass ベクター (`;`, `&&`, `||`, サブシェル等)の検出強化
- `helpers.go` の `hasSudo()` をシェルメタキャラクタ includingContextにも対応

**ユーザー体験のImprovement**:
- 今 up to: CC がInput updates 後, guardrail の deny が再評価されない抜け穴が理論的に存在 
- 今後: `updatedInput` 後も R01-R13 全Ruleが再適用され, guardrail の完全性が保証 is

### /recap と built-in slash command discovery (v2.1.108)

**付加価Value**: `C: CC Auto-inherited` (Harness 側変更不要)

CC 2.1.108 で `/recap` CommandがAdditionされ, resume 前にSession内容を要約 Verificationできるよう became.
built-in slash command の Skill tool 経由呼び出しも同バージョンで実現.

**Harness at活用**:
- `/recap` は長 hoursの `--resume` 時にSession記憶 verify Procedure as `skills/session-memory/SKILL.md` に記載
- CC 本体のFeature asAutomatic利用可能.Harness 側のImplementation変更は不要

### EnterWorktree path Argument / stale worktree AutomaticCleanup (v2.1.105)

**付加価Value**: `A: Implemented` (`scripts/reenter-worktree.sh`, Phase 44.7.1 でImplemented)

CC 2.1.105 で `EnterWorktree` フックに worktree パスがArgument as渡 isよう became.
それ up toは worktree パスをScript内で自力特定 need toあった.

**Harness at活用**:
- `scripts/reenter-worktree.sh` で EnterWorktree パスArgumentを活用 worktree 再入ヘルパー implements
- worktree 登録Verificationと `worktree-info.json` 照合 including安全な再入Flow
- Breezing の Worker が一時Stop後に正しい worktree に再入できることを保証

**ユーザー体験のImprovement**:
- 今 up to: Worker の worktree 再入は環境Dependencyの worktree パス特定が必要で不安定だった
- 今後: フック from直接パス receives and, worktree-info.json との照合で確実に正しいContextに再入

---

## Opus 4.7 DetailsSection (Phase 44.11.1)

> このSectionでは Opus 4.7 固有Featureの Harness toIntegration状況を詳述.
> 付加価Value minutes類: A = Implemented, C = CC Auto-inherited.B minutes類は 0 items.

### 1. Literal Instruction Following

**付加価Value**: `A: Implemented` (`.claude/rules/opus-4-7-prompt-audit.md`, Phase 44.4.1 + 44.4.2 でImplemented)

Opus 4.7 は"指示を文字通り実行 "能力が大幅に向上.曖昧な表現をComplement 意図を推測 のではなく, 指示 was内容 only executes.

**Harness at活用**:
- `.claude/rules/opus-4-7-prompt-audit.md` newly created.エージェントプロンプトの品質Criteria defines
 - 行動指示には実行Command名 / ファイルパス / JSON schema 名 / 数Value閾Valueのいずれ whetherRequired化
 - times数制御は `Maximum 3 times` のように数字で記述
 - `必要 according to` / `適宜` 等の曖昧語には直後にConditionNoteをRequired化
- `agents/worker.md`, `agents/reviewer.md`, `agents/advisor.md` のプロンプトを監査Criteriaに適合

**ユーザー体験のImprovement**:
- 今 up to: エージェントプロンプトの曖昧表現がモデルの誤解釈を招き, 意図 not動作が発生 
- 今後: 監査Criteriaに合格 プロンプトはモデルが文字通りに解釈し, 一貫 動作が保証 is

### 2. xhigh Effort

**付加価Value**: `A: Implemented` (`agents/reviewer.md`, `agents/advisor.md`, `docs/effort-level-policy.md`, Phase 44.5.1 でImplemented)

Opus 4.7 では `xhigh` effort LevelがAddition was (CC v2.1.111 frontmatter as受け付け可能).
`high` from thinking 強度が高く, 複雑なReviewやDesign判断に適.

**Harness at活用**:
- `agents/reviewer.md`: `effort: medium` → `effort: xhigh` に変更 (Reviewの深度向上)
- `agents/advisor.md`: `effort: high` → `effort: xhigh` に変更 (判断の正確性向上)
- `docs/effort-level-policy.md`: CC frontmatter effort と Anthropic API effort の対応マトリクスを整備
- `harness-work` スキルの多要素スコアリングで `ultrathink` を Worker に注入 仕組みは維持

**ユーザー体験のImprovement**:
- 今 up to: Reviewer は medium effort で動作し, 複雑なアーキテクチャ変更のReviewが浅くなるケースがあった
- 今後: xhigh effort で Reviewer の thinking 品質が向上し, critical/major 指摘の検出率が上がる

### 3. Task Budgets (adopted見送り)

**付加価Value**: `C: adopted見送り` (`docs/task-budgets-research.md`, Phase 44.10.1 で調査済み)

Anthropic Task Budgets (public beta) はタスク単位でToken / ツール呼び出し数を制限 Feature.

**Harness at活用**:
- `docs/task-budgets-research.md` にSpecification要約 / Harness Existing機構との競合関係 minutes析を記録
- Existingの `maxTurns` (Worker: 100, Reviewer: 50) and `MAX_REVIEWS` とFeatureが重複 for本 Phase ではadopted見送り
- GA 昇格時の再評価トリガーCondition (Harness 独自制御とのIntegrationDesignが確定 when点)を明記

**adopted見送りReason**:
- Harness はalready `maxTurns` と `MAX_REVIEWS` で Worker の実行制限をManagement
- Task Budgets との二重ManagementはConfigurationの複雑性を増やすリスクがa/an
- Public beta 段階 atadopted from GA 後の安定 API を待つ判断

### 4. Tokenizer Improvement

**付加価Value**: `C: CC Auto-inherited` (Harness 側変更不要)

Opus 4.7 の新 tokenizer via, 同一プロンプトのToken数が削減 is.特に days本語 / コード混在コンテンツで効果が大きい.

**Harness to影響**:
- CLAUDE.md, スキルファイル, エージェントプロンプトのToken消費がAutomatic的に削減
- スキルバジェット (Context窓の 2%)の実効文字数が増加
- Harness 側の変更は不要.モデルUpdateでAutomatic的に恩恵を受ける

### 5. Vision 2576px 対応

**付加価Value**: `A: Implemented` (`docs/opus-4-7-vision-usage.md`, `skills/harness-review/references/vision-high-res-flow.md`, Phase 44.9.1 でImplemented)

Opus 4.7 では画像の短辺Upper limitが 2576px up to拡大 was.PDF / Design図 / UI スクリーンショットのReview品質が向上.

**Harness at活用**:
- `docs/opus-4-7-vision-usage.md`: 高解像度ReviewのOperationGuide newly created (3 種のシナリオ: PDF Review / Design図解析 / UI スクリーンショット)
- `skills/harness-review/references/vision-high-res-flow.md`: 2576px Upper limitのOperationFlow (リサイズ判定 / 多ページ PDF の minutes割戦略)を整備
- `/harness-review` で画像添付時のAutomaticUpper limitCheckを組み込み

**ユーザー体験のImprovement**:
- 今 up to: 高解像度スクリーンショットはAutomaticリサイズで品質が低下し, 細部の UI Issueを見落とすケースがあった
- 今後: 2576px up to原寸でReview可能.UI のピクセルLevelのIssueやDesign図の微細なラベルも検出できる

### 6. Memory Featureextended

**付加価Value**: `C: CC Auto-inherited` (auto-memory システムがExisting.Harness 側変更不要)

Opus 4.7 の Memory Featureextended (Automatic memory recordingの精度向上 / 長期記憶のCompress品質Improvement)は Harness のExisting Agent Memory 基盤とAutomatic的にIntegration is.

**Harness at活用**:
- `memory: project` frontmatter によるエージェント固有Memoryはcontinuing toFeature
- CC のAutomaticMemory精度向上 via, Worker / Reviewer / Scaffolder の学習品質がAutomatic的に向上
- `.claude/agent-memory/` のExistingエントリとのCompatible性は維持

### 7. /ultrareview (並立維持Policy)

**付加価Value**: `A: Implemented` (`docs/ultrareview-policy.md`, `skills/harness-review/SKILL.md`, Phase 44.8.1 でImplemented)

CC v2.1.111 で `/ultrareview` が built-in operator entrypoint asAddition was.cloud 多エージェントReview executes.

**Harness at活用 (Policy B: 並立維持)**:
- `docs/ultrareview-policy.md`: `/ultrareview` は ad-hoc Reviewに限定, Harness automation flow には組み込まないPolicyを確立
- Harness の review automation は `review-result.v1` 契約ベースの `codex-companion.sh review` (Priority)+ reviewer agent (Fallback) maintained
- `skills/harness-review/SKILL.md` に役割 minutes担Section added

**ユーザー体験のImprovement**:
- 今 up to: `/ultrareview` の登場で Harness の `/harness-review` との役割が曖昧になっていた
- 今後: `/ultrareview` = 人間の ad-hoc Review向け / `/harness-review` = Automatic化Flow向け と明確にIsolation

### 8. Auto Mode 拡大

**付加価Value**: `C: opt-in 扱い` (`skills/breezing/SKILL.md` の `--auto-mode` Flag説明)

CC v2.1.111 で Auto Mode が `--enable-auto-mode` Flagなし even利用可能 became.

**Harness at活用**:
- `skills/breezing/SKILL.md` の `--auto-mode` Optionは"Harness 側の Auto Mode rollout をExplicit" opt-in Flag as説明 maintained
- CC 本体 at Auto Mode 拡大はAutomatic的にInherit isが, Harness の `bypassPermissions` ベースのImplementationと混在 notようNote
- operator entrypoint asの `--auto-mode` は呼び出し側が選ぶDesign maintained.agent Definition側に `autoMode` Valueは書かない

**ユーザー体験のImprovement**:
- 今 up to: Auto Mode には `--enable-auto-mode` Flagが必要で, Breezing との組み合わせが複雑だった
- 今後: CC 本体で Auto Mode が常設化 wasが, Harness では `--auto-mode` をExplicit opt-in as扱い続けることで予測可能な挙動 maintained

## Phase 65 (cognitive-load 3 surface) — 2026-05-09 - 2026-05-10

| Feature | Skill / Component | Purpose | 付加価Value |
|---------|-------------------|---------|---------|
| Plan Brief HTML (1st surface) | `harness-plan-brief` | 着工前の Claude 理解 / 選択肢 / リスク / 受け入れCondition / 確信度を 1 枚 HTML で施主にApprovalVerification | A: Implemented (Phase 65.1) |
| Acceptance Demo HTML (2nd surface) | `harness-accept` | 引き渡し時の ship/wait/reject 判定 + 受け入れConditionVerification + 過去Issueパターン表示 | A: Implemented (Phase 65.2) |
| Progress Tracker HTML (3rd surface) | `harness-progress` | 進捗 % + WIP/TODO/完了List + 5 種 drift alert + PostToolUse Automatic再生成 (60s rate limit) | A: Implemented (Phase 65.4) |
| 3-Layer Redaction | `redact-by-{dictionary,ner}.sh` + `final-scan-redaction.py` + `render-html.sh --with-redaction` | Layer 2a 辞書 + 2b NER (fugashi) + 3 final scan で固有名詞 leakage を 3 層防御 | A: Implemented (Phase 65.3) |
| Cross-Project Group | `cross-project-groups.yaml` + `load-cross-project-groups.sh` | 横断検索の opt-in グループDefinition (default OFF) | A: Implemented (Phase 65.3.1) |
| Cross-Project Audit Log | `cross-project-audit-log.sh` | 横断検索 1 times per 1 行 JSON Lines (privacy: query_hash only) | A: Implemented (Phase 65.3.6) |
| Audit-trail UI | 3 HTML templates 共通Addition | each surface 末尾"🔍 この artifact の根拠"Section (検索範囲 / 参照 ID / redact Count / log link) | A: Implemented (Phase 65.5.2) |
| user_request_hash join | `personal-preference.v1` + `acceptance-decision.v1` の sha256 fields | Plan Brief ↔ Acceptance を同 hash で graph join 可能に | A: Implemented (Phase 65.1.4 / 65.2.3) |

**ユーザー体験のImprovement**:
- 今 up to: Plans.md (200 行) + git log を読まないと進捗 / 判断根拠が見えなかった.エンジニアじゃない発注者は完全にブラックボックス
- 今後: ブラウザで 1 枚 HTML を開けば 3 secondsで"何 creates予定か (Plan Brief) / 今どこか (Progress) / 受け取れるか (Acceptance)"が判断できる
- 横断検索 enables も 3 層 redaction で他プロジェクトの固有名詞は漏れない (fail-safe)
- Details: [cognitive-load-surfaces.md](./cognitive-load-surfaces.md) / [cross-project-safety.md](./cross-project-safety.md)

## Relatedドキュメント

- [CLAUDE.md](../CLAUDE.md) - DevelopmentGuide (Feature Table の要約版)
- [CLAUDE-skill-catalog.md](./CLAUDE-skill-catalog.md) - スキルカタLog
- [CLAUDE-commands.md](./CLAUDE-commands.md) - Commandリファレンス
- [ARCHITECTURE.md](./ARCHITECTURE.md) - アーキテクチャOverview
