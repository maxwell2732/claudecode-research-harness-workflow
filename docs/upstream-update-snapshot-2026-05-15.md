# Claude Code upstream snapshot - 2026-05-15

この snapshot は、Phase 62 で追従済みの `2.1.112`-`2.1.132` 以降に公開された
**`2.1.133`-`2.1.142`** (合計 10 バージョン) を Phase 69 として確認し、
Harness の Tier 1 5 件 + Tier 2 5 件として実装した記録です。

確認日:

- 2026-05-15 (Asia/Tokyo)

ローカル確認:

- `claude --version`: `2.1.142 (Claude Code)` 想定
- (CHANGELOG は GitHub 公式ソースで確認)

既存 Harness の追従済み地点:

- Claude Code `2.1.112`-`2.1.132` (Phase 62, `docs/upstream-update-snapshot-2026-05-07.md`)

一次情報:

- Claude Code GitHub CHANGELOG: <https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md>
- Claude Code docs CHANGELOG: <https://code.claude.com/docs/en/changelog>

分類:

- `A: 検証強化`: 今回の Phase 69 で snapshot / Feature Table / CHANGELOG / tests / 実装で固定。
- `C: 自動継承`: Claude Code 本体の修正をそのまま受ける。Harness wrapper を重ねない。
- `P: Plans 化`: Harness に活用価値があるが、この snapshot では runtime 実装せず後続 task に切る。
- `B: 書いただけ`: **0 件** (この snapshot では `B` を作らない)。すべて `A` / `C` / `P` に分類した。

## Version-by-version breakdown

| Version | Upstream item | どうよくなる | Category | Harness surface | Harness action |
|---------|---------------|--------------|----------|-----------------|----------------|
| Claude Code `2.1.133` | `worktree.baseRef` setting (`fresh` \| `head`) | `--worktree` / `EnterWorktree` / agent-isolation worktree の起点を明示できる | A | `templates/claude/settings.security.json.template` (`.claude-plugin/settings.json` は self-protect deny のため operator が手動適用) | Phase 69.1.1 で template に `fresh` を baseline として明示。breezing / Worker isolation の base ref を `origin/<default>` で固定し、unpushed commits を新 worktree に持ち込みたい team には `head` を opt-in として提示。Plugin 本体 `.claude-plugin/settings.json` は CLAUDE.md Permission Boundaries の self-write deny により agent から書換不可なので、operator が release 時に手動でマージする運用 |
| Claude Code `2.1.133` | `sandbox.bwrapPath` / `sandbox.socatPath` managed settings | Linux/WSL で bwrap/socat の実体を明示できる | C | sandbox runtime | Harness 側に固定値を持たない。CC 本体の解決ロジックに任せる |
| Claude Code `2.1.133` | `parentSettingsBehavior` admin-tier key | SDK `managedSettings` を policy merge に opt-in できる | P | docs (admin governance) | 個人開発者向け Harness では merge を強制しない。enterprise context が来たら docs 化 |
| Claude Code `2.1.133` | Hooks receive `effort.level` JSON + `$CLAUDE_EFFORT` env | hook が現在の effort を見て分岐できる | A | `scripts/hook-handlers/*.sh`, `.claude/rules/hooks-2.1.139-plus.md` | Phase 69.1.2 で `$CLAUDE_EFFORT` を opt-in な分岐軸として明文化。任意の hook が見られるよう rules に記述し、Bash 内でも `$CLAUDE_EFFORT` を参照できる前提を統一 |
| Claude Code `2.1.133` | parallel sessions credential race / `Edit`/`Write` allow-rule on drive root / `--add-dir` mapped drives etc. | runtime bug fix | C | runtime | 自動継承 |
| Claude Code `2.1.133` | `/effort` cross-session leak fix | session 間の effort が独立する | C | runtime | 自動継承 |
| Claude Code `2.1.133` | Subagents 不発見 Skill 修正 / `claude --help` `--remote-control` 追記 | runtime fix | C | runtime | 自動継承 |
| Claude Code `2.1.134` | (no changelog entries) | --- | C | --- | 自動継承 |
| Claude Code `2.1.135` | (no changelog entries) | --- | C | --- | 自動継承 |
| Claude Code `2.1.136` | `settings.autoMode.hard_deny` 無条件ブロックルール | Auto Mode classifier が「許可意図に関わらず必ず deny」を扱える | A | `templates/claude/settings.security.json.template` (`.claude-plugin/settings.json` は self-protect deny のため operator が手動適用) | Phase 69.1.3 で template に baseline 7 件 (`Bash(sudo:*)` / `Bash(rm -rf:*)` / `Bash(rm -fr:*)` / `Bash(git push -f:*)` / `Bash(git push --force:*)` / `Bash(git reset --hard:*)` / `mcp__codex__*`) を hard_deny として明文化。Plugin 本体 `.claude-plugin/settings.json` は release 時に operator が手動マージする |
| Claude Code `2.1.136` | `CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL` | OTEL 経由でフィードバック取得 | C | OTel | Harness は OTel pipeline を強制しない。enterprise が opt-in する時に CC 本体が解釈 |
| Claude Code `2.1.136` | MCP server `/clear` 消失修正 / OAuth refresh race fix / extended thinking redaction 400 fix | runtime stabilization | C | MCP / auth | 自動継承 |
| Claude Code `2.1.136` | `--resume`/`--continue` underscore path / plan mode `Edit(...)` allow 阻害 / WSL2 image paste / `SessionStart` `CLAUDE_ENV_FILE` 再注入 | runtime fix | C | runtime | 自動継承 |
| Claude Code `2.1.136` | 視覚整合性 (slash dialog 統一, markdown 色, CJK ellipsis, jump-to-bottom artifact 等) | UX 改善 | C | UX | 自動継承 |
| Claude Code `2.1.137` | VSCode 拡張 activation Windows 修正 | runtime | C | IDE | 自動継承 |
| Claude Code `2.1.138` | Internal fixes | runtime | C | runtime | 自動継承 |
| Claude Code `2.1.139` | Agent view (`claude agents`) Research Preview | 全 CC session を 1 画面で監視できる | A | `agents/worker.md`, `agents/team-composition.md`, `docs/agent-view-policy.md` | Phase 69.2.2 で `claude agents` を breezing teammate と独立した 1st-class operator entrypoint として policy 化。Harness 内 spawn は引き続き Lead 限定 |
| Claude Code `2.1.139` | `/goal` command | 完了条件を turn 超えで保持 | A | `docs/codex-plugin-workflows-policy.md`, `skills/harness-plan/SKILL.md`, `skills/harness-work/SKILL.md` | Phase 69.2.1 で CC native `/goal` も Codex `/goal` と同様に **session continuation memo 用途に限定**。`Plans.md` / DoD は唯一の task SSOT のまま。`/goal` と Plans.md を二重化させない grep gate を rules に追加 |
| Claude Code `2.1.139` | `/scroll-speed` | mouse wheel UX | C | UX | 自動継承 |
| Claude Code `2.1.139` | `claude plugin details <name>` | plugin の component 内訳と token cost を可視化 | A | `scripts/ci/check-consistency.sh`, `docs/plugin-managed-settings-policy.md` | Phase 69.2.4 で `claude plugin details` の出力を `bin/harness doctor` / consistency check の補助情報に位置付け、token cost が 1 plugin で session 予算の閾値を越えた場合の対応 step を docs 化 |
| Claude Code `2.1.139` | Transcript view navigation (`?`, `{`/`}`, `v`) | UX | C | UX | 自動継承 |
| Claude Code `2.1.139` | Hook `args: string[]` (exec form) | shell 経由を介さず command を直接 spawn できる | A | `.claude/rules/hooks-2.1.139-plus.md` | Phase 69.1.4 で exec form の利用条件を rules 化: path placeholder が含まれる hook では exec form を優先、shell metacharacter 展開が必要な場合のみ既存 `type: "command"` を維持 |
| Claude Code `2.1.139` | Hook `continueOnBlock` for PostToolUse | hook の rejection reason を Claude に返して turn 継続できる | A | `.claude/rules/hooks-2.1.139-plus.md` | Phase 69.1.4 で `continueOnBlock` を「安全な diagnostic feedback」用途に限定する rule を追加。deny 必須の guard rail (R01-R13) には `continueOnBlock: false` を維持 |
| Claude Code `2.1.139` | MCP stdio receives `CLAUDE_PROJECT_DIR` | MCP server が project dir を解決できる | C | MCP | 自動継承 |
| Claude Code `2.1.139` | Compaction prompt が user instructions を保持 | session 中の rule が compaction で消えにくい | C | compaction | 自動継承 |
| Claude Code `2.1.139` | `x-claude-code-agent-id` / `parent-agent-id` headers + OTEL `agent_id` attrs | subagent 監視性が上がる | C | OTel/telemetry | 自動継承 |
| Claude Code `2.1.139` | `ANTHROPIC_API_KEY` set 時に Remote Control 等 disable | enterprise auth boundary が明確 | C | auth | 自動継承 |
| Claude Code `2.1.139` | hook が terminal 書き込みで prompt corruption → no terminal access | hook 安定化 | C | runtime | 自動継承 |
| Claude Code `2.1.139` | `Skill(name *)` wildcard prefix match | permission rule の expressive power | C | permission | 自動継承 |
| Claude Code `2.1.140` | `subagent_type` case-/separator-insensitive matching | agent 名表記揺れに耐性 | C | agent | 自動継承 |
| Claude Code `2.1.140` | Updated agent color palette | UX | C | UX | 自動継承 |
| Claude Code `2.1.140` | `/goal` 無音 hang fix on `disableAllHooks` | runtime fix | C | runtime | 自動継承 |
| Claude Code `2.1.140` | Settings hot-reload symlink fix / `/loop` redundant wakeups / Windows where.exe stall | runtime fix | C | runtime | 自動継承 |
| Claude Code `2.1.140` | Plugins warn when default folder silently ignored | plugin lifecycle visibility | C | plugin | 自動継承 |
| Claude Code `2.1.141` | `terminalSequence` field for hook JSON output | hook が controlling terminal なしで desktop 通知 / window title / bell を発火できる | A | `scripts/hook-handlers/webhook-notify.sh`, `scripts/hook-handlers/notification-handler.sh`, `.claude/rules/hooks-2.1.139-plus.md` | Phase 69.1.5 で `HARNESS_TERMINAL_NOTIFY` env (0/1/`bell`/`title`/`osc9`) opt-in を実装し、`task-completed` 系 hook が外部 webhook 不要で local notification を出せるようにする |
| Claude Code `2.1.141` | `CLAUDE_CODE_PLUGIN_PREFER_HTTPS` | SSH key なし環境で plugin clone 可能 | C | plugin | 自動継承 |
| Claude Code `2.1.141` | `ANTHROPIC_WORKSPACE_ID` (workload identity federation) | token scoping | P | enterprise auth | docs/plugin-managed-settings-policy.md 経由で enterprise context が出てきたら docs 化 |
| Claude Code `2.1.141` | `claude agents --cwd <path>` | session list を directory scope できる | A | `docs/agent-view-policy.md` | Phase 69.2.2 と同梱: agent view を project ごとに分離する運用を docs 化 |
| Claude Code `2.1.141` | `/feedback` includes recent sessions | session 跨ぎの bug report | C | feedback | 自動継承 |
| Claude Code `2.1.141` | Rewind "Summarize up to here" | context compression 中間状態保持 | C | session | 自動継承 (`.claude/rules/commit-safety.md` の `/undo` policy と整合) |
| Claude Code `2.1.141` | Auto mode dialog が `permissions.ask` 由来を説明 | permission UX | C | permission | 自動継承 |
| Claude Code `2.1.141` | IDE diff view restore on file-edit permission prompt | IDE | C | IDE | 自動継承 |
| Claude Code `2.1.141` | Background agents preserve permission mode | `/bg` / `←←` で起動した agent が default に戻らない | A | `agents/worker.md`, `agents/team-composition.md`, `docs/agent-view-policy.md` | Phase 69.2.3 で breezing teammate / Worker isolation worktree の permission mode 期待値を明示 |
| Claude Code `2.1.141` | `claude agents` Completed state for background-shell-leaking sessions | agent view 表示 | C | agent | 自動継承 |
| Claude Code `2.1.141` | Spinner 10s amber warm-up / plugin menu nav / 多数の hooks / MCP / Remote Control / SDK / Bedrock / VSCode 修正 | runtime fix | C | runtime | 自動継承 |
| Claude Code `2.1.141` | hooks が `EnterWorktree` 後の `transcript_path` 失効修正 | runtime fix | C | hook | 自動継承 (Harness 側で `transcript_path` を信用する箇所がないことを確認) |
| Claude Code `2.1.142` | `claude agents` 新フラグ群 (`--add-dir`, `--settings`, `--mcp-config`, `--plugin-dir`, `--permission-mode`, `--model`, `--effort`, `--dangerously-skip-permissions`) | dispatched background session の構成が宣言的 | A | `docs/agent-view-policy.md`, `agents/team-composition.md` | Phase 69.2.2 と同梱: 各フラグの利用条件と Harness deny ルールとの衝突 (例: `--dangerously-skip-permissions` は protected branch では使わない) を rule に落とす |
| Claude Code `2.1.142` | Fast mode Opus 4.7 default + `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE` | fast mode が常に Opus 4.7 で動く | C | model | 自動継承 (既に Opus 4.7 を default として扱っているため Harness 側は変更不要) |
| Claude Code `2.1.142` | Plugins with root-level `SKILL.md` and no `skills/` subdir surfaced | 単一 SKILL plugin が認識される | C | plugin | 自動継承 (Harness は `skills/` 配下を SSOT としているため影響なし) |
| Claude Code `2.1.142` | `/plugin` details + `claude plugin details` now show LSP servers | LSP visibility | C | plugin | 自動継承 |
| Claude Code `2.1.142` | `/web-setup` warns before replacing GitHub App connection | safety | C | web setup | 自動継承 |
| Claude Code `2.1.142` | `MCP_TOOL_TIMEOUT` raises per-request fetch timeout for HTTP/SSE | MCP long-running call が機能する | C | MCP | 自動継承 |
| Claude Code `2.1.142` | Background sessions が pre-existing worktree を認識 / macOS sleep/wake / daemon binary upgrade cleanup / Chrome extension shim 等多数 fix | runtime stabilization | C | runtime | 自動継承 |
| Claude Code `2.1.142` | Hook config error: SessionStart/Setup/SubagentStart で prompt/agent 型 hook はエラー化 | hook config error を早期に検出 | A | `.claude/rules/hooks-2.1.139-plus.md` | Phase 69.1.4 と同じ rule 内で「SessionStart/Setup/SubagentStart は command 型のみ」を明文化し、Harness hooks.json の対応箇所を grep-able にする |
| Claude Code `2.1.142` | Improved reactive compaction (first summarize seeds from overflow size) | compaction efficiency | C | session | 自動継承 |
| Claude Code `2.1.142` | Removed stale `/model claude-sonnet-4-20250514` suggestion | UX | C | runtime | 自動継承 |

---

## Tier 1 (Phase 69.1.1-69.1.5) - 設定 / hooks / rules を直接更新

| ID | Phase | 内容 | 主要 artifact |
|----|-------|------|---------------|
| 69.1.1 | settings | `templates/claude/settings.security.json.template` に `worktree.baseRef: "fresh"` を明示 (plugin 本体 settings は operator が手動適用) | `templates/claude/settings.security.json.template` |
| 69.1.2 | hooks | `effort.level` JSON + `$CLAUDE_EFFORT` env の参照ポリシーを rules に明文化 | `.claude/rules/hooks-2.1.139-plus.md` |
| 69.1.3 | settings | `autoMode.hard_deny` の baseline 7 件を template の baseline に追加 (plugin 本体 settings は operator が手動適用) | `templates/claude/settings.security.json.template` |
| 69.1.4 | hooks | hook `args:` exec form / `continueOnBlock` / `SessionStart`/`Setup`/`SubagentStart` の command-only 制約を rules 化 | `.claude/rules/hooks-2.1.139-plus.md` |
| 69.1.5 | hooks | `terminalSequence` を `webhook-notify.sh` / `notification-handler.sh` に opt-in 実装 (`HARNESS_TERMINAL_NOTIFY`) | `scripts/hook-handlers/webhook-notify.sh`, `scripts/hook-handlers/notification-handler.sh` |

## Tier 2 (Phase 69.2.1-69.2.5) - policy / docs / agent contract を更新

| ID | Phase | 内容 | 主要 artifact |
|----|-------|------|---------------|
| 69.2.1 | docs | CC native `/goal` を「session continuation memo 限定」として policy 化 (Codex `/goal` と同方針) | `docs/codex-plugin-workflows-policy.md` (rename or augment) |
| 69.2.2 | docs | `claude agents` operator entrypoint + 新フラグ群の Harness 安全運用 policy | `docs/agent-view-policy.md` (新規) |
| 69.2.3 | agent | Background agent permission mode 保持の期待値を Worker / team composition に明示 | `agents/worker.md`, `agents/team-composition.md` |
| 69.2.4 | ci | `claude plugin details` 出力の利用例を `scripts/ci/check-consistency.sh` の note に追加 | `scripts/ci/check-consistency.sh` |
| 69.2.5 | rules | Phase 69 rule SSOT を新設し、`opus-4-7-prompt-audit.md` の checklist にも追記 | `.claude/rules/hooks-2.1.139-plus.md` |

## Test 追加 / 期待

| Test | 場所 | 期待 |
|------|------|------|
| settings baseline | `tests/validate-plugin.sh` のセクション 4 (settings) | `worktree.baseRef` と `autoMode.hard_deny` の存在を assert |
| hook terminalSequence | `tests/test-terminal-notify.sh` (新規) | `HARNESS_TERMINAL_NOTIFY=osc9` で `terminalSequence` フィールドが出力される |
| rule grep gate | `tests/test-rule-presence.sh` (新規 or 既存 extend) | `.claude/rules/hooks-2.1.139-plus.md` の必須 anchors 5 件が存在 |
| `/goal` SSOT gate | `tests/test-rule-presence.sh` | `docs/codex-plugin-workflows-policy.md` または同等 doc に「`/goal` (CC native) を Plans.md SSOT に使わない」記述が存在 |

## Rollback notes

- `worktree.baseRef: "fresh"` は CC 2.1.133 の default と一致。`head` を選びたい team は project-level settings で上書きする。
- `autoMode.hard_deny` の baseline は既存 `permissions.deny` の super-set ではなく **必須コア 7 件のみ**。auto mode を使わない project では参照されず、影響ゼロ。
- `HARNESS_TERMINAL_NOTIFY` は未設定なら disable。既存 `HARNESS_WEBHOOK_URL` と独立。
- `.claude/rules/hooks-2.1.139-plus.md` は新規 rule。既存 rules に変更を加えない (orthogonal addition)。

## Operator action item (.claude-plugin/settings.json 手動適用)

Harness の self-write guardrail (`.claude/rules/self-audit.md`、CLAUDE.md Permission Boundaries) により、
plugin 本体 `.claude-plugin/settings.json` は agent から書換できない。
release 時に operator が次のブロックを手動で追加する:

```json
"worktree": {
  "baseRef": "fresh"
},
"autoMode": {
  "hard_deny": [
    "Bash(sudo:*)",
    "Bash(rm -rf:*)",
    "Bash(rm -fr:*)",
    "Bash(git push -f:*)",
    "Bash(git push --force:*)",
    "Bash(git reset --hard:*)",
    "mcp__codex__*"
  ]
}
```

template (`templates/claude/settings.security.json.template`) には既に baseline として書込済み。
新規 project setup 時に `harness setup` で template が project に展開される際は自動反映される。

## 関連 docs

- `docs/upstream-update-snapshot-2026-05-07.md` (Phase 62, 2.1.112-2.1.132)
- `docs/upstream-update-snapshot-2026-05-10.md` (Phase 67, Codex 0.130.0)
- `.claude/rules/hooks-2.1.139-plus.md` (Phase 69 で新設)
- `docs/agent-view-policy.md` (Phase 69 で新設)
- `.claude/rules/cc-update-policy.md` (3 カテゴリ分類の SSOT)
