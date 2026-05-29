# Claude Code upstream snapshot - 2026-05-07

この snapshot は、Phase 56 / Phase 58 で追従済みの `2.1.119`-`2.1.126` 以外の
**`2.1.112`-`2.1.118` および `2.1.127`-`2.1.132`** (合計 13 バージョン) を確認し、
Harness の Tier 1 5 件 + Tier 2 5 件として実装した記録です。

確認日:

- 2026-05-07 (Asia/Tokyo)

ローカル確認:

- `claude --version`: `2.1.132 (Claude Code)` 想定
- (CHANGELOG は GitHub 公式ソースで確認)

既存 Harness の追従済み地点:

- Claude Code `2.1.119` (Phase 56)
- Claude Code `2.1.120`-`2.1.126` (Phase 58, 一部実装は Phase 62.2.x で完了)

一次情報:

- Claude Code GitHub CHANGELOG: <https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md>
- Claude Code docs CHANGELOG: <https://code.claude.com/docs/en/changelog>

分類:

- `A: 検証強化`: 今回の Phase 62 で snapshot / Feature Table / CHANGELOG / tests / 実装で固定。
- `C: 自動継承`: Claude Code 本体の修正をそのまま受ける。Harness wrapper を重ねない。
- `B: 書いただけ`: **0 件** (この snapshot では `B` を作らない)。すべて `A` か `C` に分類した。

## Version-by-version breakdown

| Version | Upstream item | どうよくなる | Category | Harness surface | Harness action |
|---------|---------------|--------------|----------|-----------------|----------------|
| Claude Code `2.1.112` | Auto mode for Opus 4.7 stability fix | Opus 4.7 が auto mode で短期 unavailable にならない | C | runtime | 自動継承 |
| Claude Code `2.1.113` | Subagent stalling mid-stream fail after 10 minutes | Worker フリーズ時の検出が CC 側で 600s timeout として確定 | A | `agents/worker.md`, `docs/team-composition.md` | Phase 62.1.1 で 2 層防御として明文化 (CC 600s + elicitation-handler.sh) |
| Claude Code `2.1.113` | `sandbox.network.deniedDomains` setting | session レベルで outbound network deny できる | A | `.claude-plugin/settings.json`, `templates/claude/settings.security.json.template` | Phase 62.1.4 で template baseline を 9 件に拡張 (paste-site 系 6 件追加) |
| Claude Code `2.1.113` | deny rules match `env`/`sudo`/`watch` wrappers | wrapper bypass を CC 側で deny | A | `go/internal/guardrail/rules_test.go` | Phase 62.1.5 で R06/R11/R12 × 3 wrapper の 9 ケースを fix posture 固定 |
| Claude Code `2.1.113` | `/private/{etc,var,tmp,home}` dangerous removal targets, `find -exec`/`-delete` not auto-approved | macOS や find-based removal の安全性が上がる | C | guardrail | 既存の R05 helpers が classifyBashProtectedWrite / hasDangerousFindDelete でカバー済み |
| Claude Code `2.1.114` | Permission dialog crash fix with agent teammate | breezing が安定する | C | runtime | 自動継承 |
| Claude Code `2.1.116` | `/resume` 67% faster on 40MB+ sessions | session resume が高速化 | C | session | 自動継承 |
| Claude Code `2.1.116` | `/reload-plugins` auto-installs missing dependencies | plugin lifecycle が安定 | C | plugin | 自動継承 |
| Claude Code `2.1.116` | Bash tool hints when `gh` hits rate limit | API rate limit が見える | C | Bash runtime | 自動継承 |
| Claude Code `2.1.116` | Sandbox auto-allow bypasses dangerous-path check (security) | dangerous-path check の二重発火が消える | C | sandbox | 自動継承 |
| Claude Code `2.1.117` | `CLAUDE_CODE_FORK_SUBAGENT=1` works in SDK and `claude -p` | 非対話で fork subagent | P (Phase 58 既追従) | CI review docs | Phase 58 で対応済み |
| Claude Code `2.1.117` | Agent frontmatter `mcpServers` loaded for main-thread sessions | main-thread agent でも MCP が動く | C | agent runtime | 自動継承 (Harness 側に追加実装は不要) |
| Claude Code `2.1.117` | `cleanupPeriodDays` covers `tasks/`, `shell-snapshots/`, `backups/` | session cleanup が広範に動く | C | maintenance | 自動継承 |
| Claude Code `2.1.117` | Default effort for Pro/Max on Opus/Sonnet 4.6 is `high` | Pro/Max ユーザーの既定挙動 | C | runtime | 自動継承 |
| Claude Code `2.1.118` | `/cost` and `/stats` merged into `/usage` | 利用情報の入口統一 | C | session | 自動継承 |
| Claude Code `2.1.118` | Hooks can invoke MCP tools via `type: "mcp_tool"` | hook から MCP 直接呼び出し可能 | A | `docs/hooks-mcp-tool-evaluation.md` | Phase 62.1.3 で **採用判断: 保留**。再評価 trigger 3 項目を固定 |
| Claude Code `2.1.118` | Auto mode `"$defaults"` to extend built-in | 既存 default を残しつつ拡張 | C | auto-mode runtime | Phase 53 で対応済み (auto mode policy doc) |
| Claude Code `2.1.118` | `claude plugin tag` for release tags | release flow に plugin tag 統合 | C | release | Phase 53 で対応済み (`harness-release` skill が tag 対応) |
| Claude Code `2.1.118` | `DISABLE_UPDATES` env var | manual update 制御 | C | runtime | Phase 53 で対応済み (`docs/plugin-managed-settings-policy.md`) |
| Claude Code `2.1.127`-`2.1.128` | (no 2.1.127 release; 2.1.128 batch fixes) | runtime UX 改善 | C | UX | 自動継承 |
| Claude Code `2.1.128` | `--plugin-dir` accepts `.zip` plugin archives | plugin archive 読み込み柔軟化 | C | plugin | 自動継承 |
| Claude Code `2.1.128` | `EnterWorktree` creates branch from local HEAD (not `origin/<default>`) | 想定外の分岐元を防ぐ | C | worktree | 自動継承 (Harness の WorktreeCreate hook と整合) |
| Claude Code `2.1.128` | MCP `workspace` reserved server name | MCP 名前衝突防止 | C | MCP | 自動継承 |
| Claude Code `2.1.128` | Sub-agent progress summaries fixes | 進捗通知の重複・欠損が減る | C | agent | 自動継承 |
| Claude Code `2.1.129` | `--plugin-url <url>` for `.zip` plugin archives | remote plugin 取得 | C | plugin | 自動継承 |
| Claude Code `2.1.129` | `CLAUDE_CODE_FORCE_SYNC_OUTPUT=1`, `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE` | 出力同期、auto-update 制御 | C | env | 自動継承 |
| Claude Code `2.1.129` | `skillOverrides` works with `off` / `user-invocable-only` / `name-only` | skill governance の選択肢が広がる | A | `docs/skill-overrides-policy.md`, `tests/test-settings-baseline.sh` | Phase 62.2.5 で 3 mode の使い分けと推奨 default を docs 化 |
| Claude Code `2.1.129` | OTel `claude_code.pull_request.count` for MCP-created PRs | PR creation telemetry が拡張 | C | telemetry | 自動継承 |
| Claude Code `2.1.129` | `Bash(mkdir *)` and similar allow rules now honored, `deniedMcpServers` mixed-case | permission rules の一貫性 | C | permissions | 自動継承 |
| Claude Code `2.1.131` | VS Code extension fix on Windows; Mantle endpoint auth fix | エンタープライズ安定性 | C | enterprise runtime | 自動継承 |
| Claude Code `2.1.132` | `CLAUDE_CODE_SESSION_ID` env to Bash tool subprocess | Bash 子プロセスから session ID 直接取得 | A | `docs/session-id-env-policy.md`, `tests/test-hook-handler-session-id.sh` | Phase 62.2.4 で 4 経路の使い分け policy を docs 化、hook handlers は stdin JSON 経路維持を test で固定 |
| Claude Code `2.1.132` | `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` opt-out fullscreen | terminal fullscreen を切れる | C | TUI | 自動継承 |
| Claude Code `2.1.132` | Various TUI / paste / vim / MCP / cache fixes | 細かな安定化 | C | runtime | 自動継承 |

## Phase 62 implementation summary

Tier 1 (Phase 62.1.1-62.1.5) — Harness の弱点を直接強化:

| Task | 実装 |
|------|------|
| 62.1.1 | Worker stall 2 層防御 (CC 600s + elicitation-handler) |
| 62.1.2 | ENABLE_PROMPT_CACHING_1H opt-in を long-running skill で活用 (5 件 → 既存記載 + breezing/SKILL.md / long-running-harness.md 拡張) |
| 62.1.3 | hooks `type: "mcp_tool"` 採用判断 doc (= 保留) |
| 62.1.4 | `sandbox.network.deniedDomains` baseline 拡張 (template canonical 9 件、settings.json は user 手動) |
| 62.1.5 | R06/R11/R12 wrapper bypass test (env/sudo/watch × 3 = 9 ケース) |

Tier 2 (Phase 62.2.1-62.2.5) — Phase 58 設計済み実装:

| Task | 実装 |
|------|------|
| 62.2.1 | `PostToolUse.updatedToolOutput` opt-in handler (allowlist 方式 + audit ledger) |
| 62.2.2 | agent permissionMode reaffirmation test (Phase 59.2.3 方針を test で固定) |
| 62.2.3 | `skill_activated.invocation_trigger` telemetry (local-only ledger + privacy-first) |
| 62.2.4 | `CLAUDE_CODE_SESSION_ID` env policy doc + test (4 経路の使い分け) |
| 62.2.5 | `skillOverrides` 3 mode governance doc |

Tier 3 (= `C: 自動継承`):

UI 改善・性能改善・OAuth fix・terminal/clipboard fix 等は Harness 側変更不要。

## なぜ B: 書いただけ を 0 件にしたか

`.claude/rules/cc-update-policy.md` で `B: 書いただけ` 項目はマージブロックされる。
Phase 62 ではすべての upstream item を以下のいずれかに分類:

- 実装または test 追加 (`A`) — Tier 1 + Tier 2 の 10 タスクが該当
- CC 自動継承 (`C`) — UX / 性能 / fix 系
- 既存 Phase で対応済み (Phase 53 / 56 / 58 等)

実装にもテストにもならない upstream item は `C` (自動継承) として理由を 1 行で固定した。
これにより「Feature Table に行を足しただけ」状態を防ぐ。

## User 手動操作 follow-up

`.claude-plugin/settings.json` の `sandbox.network.deniedDomains` は Harness self-protection
guardrail (`Edit/Write(.claude-plugin/settings*) deny`) で edit されない。
template (`templates/claude/settings.security.json.template`) と同期するために、
user は手動で以下 6 件を追加する:

```json
"deniedDomains": [
  "169.254.169.254",
  "metadata.google.internal",
  "metadata.azure.com",
  "pastebin.com",     // 追加
  "transfer.sh",       // 追加
  "0x0.st",            // 追加
  "paste.ee",          // 追加
  "termbin.com",       // 追加
  "ix.io"              // 追加
]
```

`tests/test-settings-baseline.sh` は不一致を WARN として記録 (FAIL ではなく許容)、
user 手動同期を促すメッセージを出力する。

## 関連 doc

- Phase 56 snapshot: `docs/upstream-update-snapshot-2026-04-25.md`
- Phase 58 snapshot: `docs/upstream-update-snapshot-2026-05-03.md`
- Phase 62 follow-up doc: なし (本 snapshot で実装まで完了)
- Phase 62 task entries: `Plans.md` Phase 62.1.1-62.3.1
