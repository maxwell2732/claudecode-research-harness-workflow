# Claude Code / Codex upstream snapshot - 2026-05-03

この snapshot は、Phase 56 以降の未対応 upstream を確認し、
Claude Code Harness に今すぐ入れるべきもの、計画化するもの、自動継承するものを分けた記録です。

確認日:

- 2026-05-03 (Asia/Tokyo)

ローカル確認:

- `claude --version`: `2.1.126 (Claude Code)`
- `codex --version`: `codex-cli 0.128.0`

既存 Harness の追従済み地点:

- Claude Code `2.1.119`
- Codex `0.124.0` stable
- Codex `0.125.0-alpha.2` watch
- 詳細: `docs/upstream-update-snapshot-2026-04-25.md`

一次情報:

- Claude Code docs changelog: <https://code.claude.com/docs/en/changelog>
- Claude Code GitHub changelog: <https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md>
- OpenAI Codex releases: <https://github.com/openai/codex/releases>
- OpenAI Codex `rust-v0.125.0` release tag: <https://github.com/openai/codex/releases/tag/rust-v0.125.0>
- OpenAI Codex `rust-v0.128.0` release tag: <https://github.com/openai/codex/releases/tag/rust-v0.128.0>
- OpenAI Codex `rust-v0.128.0...rust-v0.129.0-alpha.2` compare: <https://github.com/openai/codex/compare/rust-v0.128.0...rust-v0.129.0-alpha.2>

分類:

- `A: 検証強化`: 今回の snapshot / Feature Table / CHANGELOG / tests で upstream 追従判断を固定する。
- `C: 自動継承`: Claude Code / Codex 本体の修正をそのまま受ける。Harness wrapper を重ねない。
- `P: Plans 化`: Harness に活用価値があるが、この snapshot PR では runtime 実装せず Phase 58 task に切る。

## Version-by-version breakdown

| Version | Upstream item | どうよくなる | Category | Harness surface | Harness action |
|---------|---------------|--------------|----------|-----------------|----------------|
| Claude Code `2.1.120` | Windows で Git Bash が無い場合に PowerShell tool を使う | Windows 初期環境でも Claude Code の shell 実行が成立しやすくなる | P | Windows compatibility / setup docs | Phase 57 の Windows worktree fix と合わせ、PowerShell primary shell 前提の docs/test を Phase 58.2.3 で確認する |
| Claude Code `2.1.120` | `claude ultrareview [target]` と `--json` | CI や script から Claude Code の review を呼びやすくなる | P | `harness-review` / CI docs | `/harness-review` と競合させず、non-interactive review input と JSON stdout contract の比較を Phase 58.2.3 に残す |
| Claude Code `2.1.120` | Skills can reference `${CLAUDE_EFFORT}` | skill 本文が現在の effort を意識できる | P | skills / prompt guidance | Harness skills で effort 条件分岐を入れる価値を Phase 58.2.3 で確認する |
| Claude Code `2.1.120` | `AI_AGENT` env for subprocesses | `gh` などの外部 CLI で agent traffic attribution がしやすくなる | C | CLI runtime | Harness 側で env wrapper を増やさず本体継承 |
| Claude Code `2.1.120` | `claude plugin validate` accepts additional schema fields | marketplace / plugin validation の許容範囲が広がる | P | plugin validation / release docs | `.claude-plugin/marketplace.json` と `plugin.json` の validation guidance を Phase 58.2.3 で見直す |
| Claude Code `2.1.120` | telemetry disable, false dangerous-rm prompt, Bash `find` fd exhaustion fixes | 既存操作が安定し、誤検知や host-wide crash が減る | C | permissions / Bash runtime | Harness は追加 wrapper を作らず本体修正を自動継承 |
| Claude Code `2.1.121` | `PostToolUse` hooks can replace output for all tools via `hookSpecificOutput.updatedToolOutput` | tool 出力の redaction / compaction / normalization を hook で扱える範囲が広がる | P | hooks / telemetry / output governance | 既定では tool output を書き換えず、opt-in の redaction / compaction と audit trail 設計を Phase 58.2.2 に切る |
| Claude Code `2.1.121` | `--dangerously-skip-permissions` no longer prompts for writes to `.claude/skills/`, `.claude/agents/`, `.claude/commands/` | dangerous skip mode の UX は速くなるが、Harness の skill / agent / command integrity には影響がある | P | guardrail / protected paths / tests | `dangerously-skip` 前提でも守るべき protected path の分類を Phase 58.2.1 で hardening する |
| Claude Code `2.1.121` | MCP `alwaysLoad`, startup retry, `mcp_authenticate.redirectUri`, `claude plugin prune` | MCP / plugin の起動と cleanup が安定する | P | setup / MCP docs / plugin lifecycle | 常時ロードすべき MCP と deferred の境界、plugin prune の安全導線を Phase 58.2.3 に残す |
| Claude Code `2.1.121` | `CLAUDE_CODE_FORK_SUBAGENT=1` works in SDK and `claude -p` | 非対話 session でも fork subagent を使いやすくなる | P | CI review / agent docs | Harness の CI / headless review runner と相性を Phase 58.2.3 で確認する |
| Claude Code `2.1.122` | `ANTHROPIC_BEDROCK_SERVICE_TIER` | Bedrock 利用時に `default` / `flex` / `priority` を選べる | P | provider setup docs | Codex provider policy と混ぜず、Claude Code Bedrock setup guidance として Phase 58.2.3 に残す |
| Claude Code `2.1.122` | `/resume` PR URL search for GitHub Enterprise / GitLab / Bitbucket | PR URL から関連 session を見つけやすくなる | P | review / session docs | Phase 56 の multi-host docs-only 方針に接続し、automation は GitHub-first を維持 |
| Claude Code `2.1.122` | OpenTelemetry numeric attrs and `claude_code.at_mention` | telemetry schema がより機械処理しやすくなる | P | telemetry docs | skill activation telemetry と合わせ、Phase 58.2.3 で schema drift を確認する |
| Claude Code `2.1.122` | malformed hooks entry no longer invalidates entire settings file | settings の一部破損で全体が無効化されにくくなる | C | hooks / settings runtime | Harness の settings generator は引き続き valid JSON を出す。本体修正は自動継承 |
| Claude Code `2.1.123` | OAuth 401 retry loop fix when `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` | ログイン不能 loop が減る | C | auth runtime | Harness 変更不要 |
| Claude Code `2.1.126` | `claude project purge [path]` | transcripts / tasks / file history / config entry をまとめて削除できる | P | cleanup / maintenance docs | `--dry-run` を前提に、Harness state cleanup と混ぜない安全手順を Phase 58.2.3 に切る |
| Claude Code `2.1.126` | `--dangerously-skip-permissions` bypasses writes to `.claude/`, `.git/`, `.vscode/`, shell config files, and other protected paths | dangerous skip mode がより強くなる一方、Harness の安全境界を明文化する必要が増す | P | guardrail / protected paths / permission docs | `.claude/`, `.git/`, `.vscode/`, shell config files の deny / ask / warn 境界を Phase 58.2.1 で設計・実装する |
| Claude Code `2.1.126` | Security fix for `allowManagedDomainsOnly` / `allowManagedReadPathsOnly` precedence | managed sandbox policy の抜け道が減る | P | settings security consistency | Harness settings / template / consistency check で managed sandbox 境界を Phase 58.2.1 で再確認する |
| Claude Code `2.1.126` | `claude_code.skill_activated` includes `invocation_trigger` and user slash command activation | skill の起動経路を telemetry で見分けやすくなる | P | telemetry / skill analytics | Harness skill usage analysis へ入れるかを Phase 58.2.3 で検討 |
| Claude Code `2.1.126` | gateway `/v1/models` model picker, OAuth code paste, PowerShell 7 detection, deferred tools for forked skills/subagents | gateway / Windows / fork context の runtime が安定する | C/P | setup / Windows / agents | 基本は自動継承。Windows / forked skill guidance に必要なものだけ Phase 58.2.3 で docs 化 |
| Codex `0.125.0` stable | App-server Unix socket, sticky environments, remote thread config/store, pagination-friendly resume/fork | app-server / remote environment の session 管理が強くなる | P | Codex workflow / app-server docs | Phase 56 の one primary environment policy を維持しつつ、sticky environment を Phase 58.3.2 で整理 |
| Codex `0.125.0` stable | Remote plugin install and marketplace upgrade | Codex 側の plugin lifecycle が実用化する | P | Codex plugin setup / marketplace docs | Harness plugin mirror policy と衝突しない導線を Phase 58.3.2 に切る |
| Codex `0.125.0` stable | Permission profiles round-trip across TUI, user turns, MCP sandbox state, shell escalation, app-server APIs | permission state を複数 surface で一貫させやすくなる | P | `codex/.codex/config.toml` / requirements / sandbox docs | Phase 58.3.1 で current config と profile-based policy の差分を整理する |
| Codex `0.125.0` stable | `codex exec --json` reports reasoning-token usage | programmatic consumer が reasoning token を見られる | P | codex loop telemetry / reports | `harness-loop` / breezing の usage report に入れるか Phase 58.3.1 で検討 |
| Codex `0.125.0` stable | Rollout tracing records tool, code-mode, session, and multi-agent relationships | multi-agent execution の trace が読みやすくなる | P | agent trace / diagnostics | existing AgentTrace と統合するか Phase 58.3.1 で確認 |
| Codex `0.128.0` stable | Persisted `/goal` workflows | goal を作成・一時停止・再開・clear できる | P | Plans / goal workflow | `Plans.md` SSOT と二重化しない前提で Phase 58.3.2 に候補として残す |
| Codex `0.128.0` stable | `codex update`, configurable keymaps, plan-mode nudges, `/statusline` and `/title` during active turns | Codex TUI の長時間作業 UX が上がる | P | Codex setup / loop docs | setup docs と long-running status guidance を Phase 58.3.1 で更新候補にする |
| Codex `0.128.0` stable | Built-in permission profiles, sandbox CLI profile selection, cwd controls, active-profile metadata | explicit permission profile に寄せられる | P | Codex config / sandbox / `--full-auto` deprecation | `--full-auto` から explicit profile へ寄せる migration を Phase 58.3.1 に切る |
| Codex `0.128.0` stable | Plugin workflows: marketplace install, remote bundle caching/uninstall, plugin-bundled hooks, hook enablement state, external-agent config import | plugin と hook の配布・有効化 state が豊かになる | P | Codex plugin / hooks / setup docs | Phase 56 の no-inline-hooks 方針を再評価し、Phase 58.3.2 で plugin-bundled hooks を比較 |
| Codex `0.128.0` stable | MultiAgentV2 thread caps, wait-time controls, root/subagent hints, depth handling | multi-agent 実行の制御が細かくなる | P | breezing / codex agents config | `agents.max_threads` と MultiAgentV2 config の関係を Phase 58.3.2 で検証 |
| Codex `0.128.0` stable | Managed network hardening, Bedrock `apply_patch`, MCP/plugin cleanup | network / provider / MCP 周りの事故が減る | P/C | guardrails / provider docs | Harness で二重化せず、必要な config docs と tests だけ Phase 58.3.1 に切る |
| Codex `0.128.0` stable | `--full-auto` deprecated in favor of explicit permission profiles and trust flows | permission の意図が明確になる | P | Codex docs / setup scripts | 古い `--full-auto` guidance を Phase 58.3.1 で棚卸しする |
| Codex `0.129.0-alpha.2` pre-release | alpha body is thin; compare shows hooks browser, workspace plugin sharing, MCP output truncation, apply_patch streaming, sandbox/app-server changes | 次 stable の方向性を早く把握できる | P | upstream watch | alpha から推測実装しない。stable release か詳細 release notes が出たら再確認 |

## Phase 58 follow-up candidates

Detailed follow-up decisions: `docs/upstream-followups-phase58-2026-05-03.md`

| Follow-up | Why it matters | Suggested Plans owner |
|-----------|----------------|-----------------------|
| Claude protected-write and `dangerously-skip` hardening | 2.1.121 / 2.1.126 で skip mode の protected write bypass 範囲が広がったため、Harness の deny / ask / warn 境界を再定義する | 58.2.1 |
| `PostToolUse.updatedToolOutput` output governance | 全 tool output を hook で置換できるようになったため、便利さより先に opt-in / audit / no-default-mutation を固定する | 58.2.2 |
| Claude setup / MCP / telemetry refresh | `alwaysLoad`, `plugin prune`, Bedrock service tier, project purge, skill activation telemetry が setup guidance に効く | 58.2.3 |
| Codex permission profiles and `--full-auto` migration | 0.125.0 / 0.128.0 で profile-backed permission が中心になったため、Harness Codex docs の古い flag guidance を棚卸しする | 58.3.1 |
| Codex plugin hooks, `/goal`, MultiAgentV2, app-server updates | 0.128.0 は plugin/hook/workflow surface が大きく、Plans SSOT と二重化しない設計が必要 | 58.3.2 |

## B: 書いただけ 0 件の理由

- Feature Table へは Phase 58 の集約行だけを追加し、この snapshot と `Plans.md` の `58.1.1`-`58.3.2` に接続する。
- 今回の runtime 実装対象は、推測でその場実装せず `P: Plans 化` として DoD 付き task に分解した。
- `A` は Phase 58 snapshot / upstream integration test による検証強化として扱う。
- `C` は Claude Code / Codex 本体の bug fix を自動継承する理由を明記した。
- Codex `0.129.0-alpha.2` は alpha のため、compare から仕様を推測して実装しない。

## No-op adaptation decision for this snapshot

この snapshot 自体は no-op adaptation とする。

理由:

- Claude Code `2.1.121` / `2.1.126` の permission change は重要だが、`.claude/` 全体を即 deny すると rules / memory / setup 更新を壊す可能性がある。先に protected path taxonomy を Phase 58.2.1 で切る。
- `PostToolUse.updatedToolOutput` は強力だが、tool output を既定で書き換えると debugability を下げる。Phase 58.2.2 で opt-in と audit trail を先に設計する。
- Codex `0.128.0` の permission profiles / plugin hooks は価値が高いが、Phase 56 で no-inline-hooks 方針を置いた直後なので、profile-backed policy と plugin-bundled hooks の責務を Phase 58.3.x で分ける。
- `0.129.0-alpha.2` は pre-release で release body が薄いため、stable まで watch に留める。
