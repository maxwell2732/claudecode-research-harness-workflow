---
name: harness-setup
description: "HAR: Project init, tool setup, agent config, memory setup, skill mirror sync. Trigger: setup, init, new project, CI/Codex setup, harness-mem, mirror. Do NOT load for: implementation, review, release, planning."
description-en: "HAR: Project init, tool setup, agent config, memory setup, skill mirror sync. Trigger: setup, init, new project, CI/Codex setup, harness-mem, mirror. Do NOT load for: implementation, review, release, planning."
description-ja: "HAR:プロジェクト初期化・ツール設定・エージェント構成・メモリ設定・skill mirror 同期を担当。セットアップ、初期化、新規プロジェクト、CI/Codex CLI セットアップ、harness-mem、mirror で起動。実装・レビュー・リリース・プランニングには使わない。"
kind: workflow
purpose: "Initialize and repair Harness project configuration"
trigger: "setup, init, new project, CI/Codex setup, harness-mem, mirror"
shape: workflow
role: generator
pair: harness-sync
owner: harness-core
since: "2026-05-05"
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
argument-hint: "[init|ci|codex|harness-mem|mirrors|agents|localize]"
user-invocable: true
effort: medium
---

# Harness Setup

Integrated Harness setup skill.
Consolidates the following legacy skills:

- `setup` — Integrated setup hub
- `harness-init` — Project initialization
- `harness-update` — Harness updates
- `maintenance` — File organization and cleanup

## Quick Reference

| Subcommand | Action |
|------------|--------|
| `/harness-setup init` | New project initialization (CLAUDE.md + Plans.md + hooks + sync + doctor) |
| `/harness-setup ci` | CI/CD pipeline configuration |
| `/harness-setup codex` | Codex CLI install and configuration |
| `/harness-setup harness-mem` | harness-mem integration and memory setup |
| `/harness-setup mirrors` | Update skills/ → public mirror bundle |
| `/harness-setup agents` | agents/ agent configuration |
| `/harness-setup localize` | Localize CLAUDE.md rules |

> **Built-in slash discovery (CC 2.1.108+)**:
> Built-in slash commands like `/init` are also discovered.
> Use `/harness-setup init` only when Harness-specific bootstrap is needed.

> **Claude Code setup guidance (CC 2.1.120+)**:
> MCP `alwaysLoad`, `${CLAUDE_EFFORT}`, `claude plugin prune`, `claude project purge`,
> `ANTHROPIC_BEDROCK_SERVICE_TIER`, `claude_code.skill_activated.invocation_trigger`,
> Windows PowerShell primary shell, and deferred tools for forked skills/subagents are
> handled with `docs/claude-code-setup-mcp-telemetry-provider.md` as the source of truth.

> **Codex plugin workflows**:
> Do not dual-manage Codex `/goal` and `Plans.md`.
> Plugin-bundled hooks are opt-in; external agent imports require explicit ownership declaration;
> MultiAgentV2 / `agents.max_threads = 8` is treated as an upper limit;
> sticky environments / app-server artifacts prioritize safe defaults.
> For Codex `0.130.0` stable: `codex remote-control`, large thread pagination,
> selected-environment `view_image`, live app-server config refresh,
> accurate turn diffs, plugin details bundled hooks, sharing discoverability controls —
> use `docs/codex-plugin-workflows-policy.md` as the source of truth.

## Subcommand details

### init — Project initialization

Introduces Harness to a new project.

**Generated files**:
```
project/
├── CLAUDE.md            # Project configuration
├── Plans.md             # Task management (empty template)
├── .claude/
│   ├── settings.json    # Claude Code settings
│   └── hooks.json       # Hook configuration (Go binary)
└── hooks/
    ├── pre-tool.sh      # Thin shim (→ core/src/index.ts)
    └── post-tool.sh     # Thin shim (→ core/src/index.ts)
```

**Flow**:
1. Detect project type (Node.js/Python/Go/Rust/Other)
2. Generate minimal CLAUDE.md
3. Generate Plans.md template
4. Place hooks.json
5. **Go binary verification**: Confirm binary is available with `harness version` (Node.js not required since v4.0)
6. **Plugin file sync**: Sync files under `.claude-plugin/` to latest with `harness sync`
7. **Health check**: Pass all check items with `harness doctor`; present fix suggestions if issues found

### Go binary verification

```bash
# Confirm binary exists and works
harness version
# Example: harness v4.0.0 (go1.22.0, darwin/arm64)
```

Since v4.0, the Harness core engine has migrated to a Go binary.
Node.js is not required. The binary uses `bin/harness` (or `harness` on PATH).

### Plugin file sync

```bash
# Sync files under .claude-plugin/ to latest
harness sync

# Check sync contents only (no changes)
harness sync --dry-run
```

`harness sync` propagates changes from the `skills/` SSOT to each mirror (`codex/.codex/skills/`, `opencode/skills/`).
Always run after init.

### Health check

```bash
# Run all check items
harness doctor
```

`harness doctor` verifies:

| Check item | Content |
|------------|---------|
| Binary | Does `harness version` return normally? |
| Plugin config | Is `.claude-plugin/plugin.json` format correct? |
| Hooks placement | Do hooks exist at the correct paths? |
| Mirror sync | Do `skills/` and mirror contents match? |
| CLAUDE.md | Do required sections exist? |

If issues are detected, fix commands are presented.

### ci — CI/CD configuration

Configures GitHub Actions workflows.

```yaml
# Example .github/workflows/ci.yml generation
name: CI
on:
  push:
    branches: [main]
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm test
```

### codex — Codex CLI configuration

```bash
# Confirm installation (Codex CLI is Node.js based; separate from Harness itself)
which codex || npm install -g @openai/codex

# Check timeout command (macOS)
TIMEOUT=$(command -v timeout || command -v gtimeout || echo "")
# macOS: brew install coreutils
```

> **Note**: Harness v4.0 itself (`harness` command) is a Node.js-free Go binary.
> Codex CLI (`codex` command) is a separate tool and still requires Node.js.

### Codex provider / model metadata policy (0.123.0+ / 0.130.0)

For Codex `0.123.0`+ provider/model guidance and Codex `0.130.0` stable Bedrock `aws login` guidance,
use `docs/codex-provider-setup-policy.md` as the source of truth.

Key points:

- For Bedrock, use Codex built-in provider `amazon-bedrock`.
- Place AWS profile in user/project Codex config under `[model_providers.amazon-bedrock.aws]`.
- Treat AWS console-login credentials from `aws login` profiles as AWS-side profile material.
- Harness does not write AWS credentials, console-login cache, or provider endpoints.
- Do not fix `model = "gpt-5.4"` as the setup default in Harness distribution Codex config.
- Do not fix `model_provider = "amazon-bedrock"` as the setup default in Harness distribution Codex config.
- Treat `gpt-5.4` as Codex's current model metadata; do not leave old `gpt-5.2-codex` etc. as recommended samples.
- Do not mix Claude Code's `CLAUDE_CODE_USE_BEDROCK` / `ANTHROPIC_DEFAULT_*` / `modelOverrides` guidance with Codex's `model_provider = "amazon-bedrock"`.

Only users/projects using Bedrock add the following as needed:

```toml
model_provider = "amazon-bedrock"

[model_providers.amazon-bedrock.aws]
profile = "codex-bedrock"
```

For Claude Code provider/MCP/telemetry guidance, refer to `docs/claude-code-setup-mcp-telemetry-provider.md`.
In particular, `ANTHROPIC_BEDROCK_SERVICE_TIER` is only for Bedrock users' provider environments and must not be included in Harness plugin defaults/templates/shared project settings.

### Codex app-server / plugin workflow policy (0.130.0)

For Codex `0.130.0` stable app-server/plugin workflow guidance,
use `docs/codex-plugin-workflows-policy.md` as the source of truth.

Key points:

- `codex remote-control` is the explicit launch entrypoint for headless remotely controllable app-server. Harness setup does not write remote-control defaults to config.
- App-server clients can page large threads. Check the required page range for long loop/Breezing transcripts.
- `view_image` can resolve files via selected environments in multi-environment sessions. Include environment/workdir in artifact reports.
- Live app-server threads pick up config changes without restart. Handle secret/provider/hook policy changes with diff and verification.
- Turn diffs stay accurate across `apply_patch` including partial failures. Confirm with `git diff` and tests.
- Plugin details now show bundled hooks. Check bundled hooks before install/share; keep Harness bundled hooks opt-in.
- Plugin sharing exposes link metadata and discoverability controls. Confirm scope and metadata as release surface.
- Configurable OpenTelemetry trace metadata is limited to debugging/triage assistance; do not include personal info, customer info, or secrets.
- Built-in MCPs are first-class runtime servers. Treat as Codex runtime-owned surface; do not mix owners with plugin-provided MCPs.
- `CODEX_HOME` environments TOML provider is a user-level environment source. Report selected environment; fix write turns to one primary environment.
- Do not rely on "remove skills list extra roots"; explicitly use Harness mirror install or `[[skills.config]]` path-based loading.

### Codex MCP diagnostics / plugin loading (0.123.0+)

For Codex `0.123.0`+ MCP diagnostics/plugin MCP loading guidance,
use `docs/codex-mcp-diagnostics.md` as the source of truth.

Key points:

- In the Codex TUI, normally check only server status lightly with `/mcp`.
- Use `/mcp verbose` only when an MCP server is not visible, resources are not showing, or resource templates cannot be read.
- With `/mcp verbose`, check diagnostics/resources/resource templates.
- Guide on the assumption that plugin `.mcp.json` accepts both `mcpServers` format and top-level server map format.
- For new plugins, prefer the more shareable `mcpServers` format.
- For existing plugins in top-level server map format, use Codex's improved loading and avoid unnecessary rewrites.
- Do not mix with Claude Code's `claude mcp ...`, `.claude/mcp.json`, hook `type: "mcp_tool"` guidance.

`mcpServers` format:

```json
{
  "mcpServers": {
    "docs": {
      "command": "node",
      "args": ["server.js"]
    }
  }
}
```

Top-level server map format:

```json
{
  "docs": {
    "command": "node",
    "args": ["server.js"]
  }
}
```

### Codex sandbox / execution policy (0.123.0+)

For Codex `0.123.0`+ `remote_sandbox_config` and `codex exec` shared flags guidance,
use `docs/codex-sandbox-execution-policy.md` as the source of truth.

Key points:

- Guide `remote_sandbox_config` as host-specific sandbox policy in `requirements.toml`.
- Decide by comparing `allowed_sandbox_modes` per remote environment, such as remote devbox / ephemeral CI runner / shared host.
- Host matching is a convenient classification but not strong device authentication. Avoid broad wildcards in high-risk environments.
- Do not write organization-specific `remote_sandbox_config` in Harness distribution `codex/.codex/config.toml`.
- Since Codex `0.123.0`, `codex exec` inherits root-level shared flags, so do not add duplicate `--approval-policy` / `--sandbox` pairs on the wrapper side.
- `scripts/codex-companion.sh task --write` adding `--sandbox workspace-write` is translating Harness's "write task" intent to exec-local, not duplicating root shared flags.
- `scripts/codex/codex-exec-wrapper.sh`'s `--full-auto` is maintained in 53.2.4. If changed, add regression tests for approval/sandbox behavior in a separate task.

Requirements example:

```toml
allowed_sandbox_modes = ["read-only"]

[[remote_sandbox_config]]
hostname_patterns = ["devbox-*.corp.example.com"]
allowed_sandbox_modes = ["read-only", "workspace-write"]
```

**Usage patterns** (via official plugin):
```bash
bash scripts/codex-companion.sh task --write "task description"
# Or via stdin
cat /tmp/prompt.md | bash scripts/codex-companion.sh task --write
```

### harness-mem — Memory setup

Configure Unified Harness Memory.

```bash
# Create memory directories
mkdir -p .claude/agent-memory/claude-code-harness-worker
mkdir -p .claude/agent-memory/claude-code-harness-reviewer

# Place MEMORY.md template
cat > .claude/agent-memory/claude-code-harness-worker/MEMORY.md << 'EOF'
# Worker Agent Memory

## Project Context
[Project overview]

## Patterns
[Learned patterns]
EOF
```

### mirrors — Public skill bundle sync

On Windows with `core.symlinks=false`, repository symlinks become regular files and `harness-*` skills may not appear in the command list. Public bundles are synced as real directory mirrors.

```bash
./scripts/sync-skill-mirrors.sh
./scripts/sync-skill-mirrors.sh --check
```

Update targets:

- `skills/`
- `codex/.codex/skills/`
- `opencode/skills/`

### agents — Agent configuration

Configure the 3-agent setup in agents/.

```
agents/
├── worker.md      # Implementation agent (task-worker + codex-implementer + error-recovery)
├── reviewer.md    # Review agent (code-reviewer + plan-critic)
└── scaffolder.md  # Scaffolding agent (project-analyzer + scaffolder)
```

### localize — Rule localization

Adapt rules in `.claude/rules/` to the current project.

```bash
# Check rule list
ls .claude/rules/

# Add project-specific rules
cat >> .claude/rules/project-rules.md << 'EOF'
# Project-Specific Rules
[Project-specific rules]
EOF
```

## Plugin install (v2.1.71+ Marketplace)

Marketplace stability was significantly improved in v2.1.71.
For plugin/managed settings policy since Claude Code 2.1.117-2.1.118,
use `docs/plugin-managed-settings-policy.md` as the source of truth.

### Recommended install method

```bash
# Pin version with @ref format (recommended)
claude plugin install owner/repo@v4.0.0

# Latest version
claude plugin install owner/repo
```

The `owner/repo@vX.X.X` format is recommended. With the `@ref` parser fix, tags, branches, and commit hashes all resolve accurately.

### Updates

```bash
claude plugin update owner/repo
```

Update merge conflicts were fixed in v2.1.71, enabling stable updates.

### Other improvements

- MCP server deduplication: Automatically prevents duplicate registration of the same MCP server
- `/plugin uninstall` uses `settings.local.json`: Accurately reflected in user-local settings

### Managed marketplace / dependency policy (v2.1.117+)

For controlling plugin marketplace in enterprise use, use Claude Code's own managed settings.
Harness does not layer its own marketplace resolver or dependency resolver on top.

| Item | Purpose | Harness handling |
|------|---------|-----------------|
| `extraKnownMarketplaces` | Guide/register recommended marketplace for team | Prioritize this for normal onboarding |
| `blockedMarketplaces` | Block specific marketplace sources | Managed settings only; do not include in normal user defaults |
| `strictKnownMarketplaces` | Allow only permitted marketplace sources | Managed settings only; do not include in normal user defaults |
| Plugin dependency auto-resolve | Auto-install `dependencies` / missing dependency hints | Delegate to Claude Code itself; do not add Harness-specific resolver |
| Plugin `themes/` directory | Plugin distributes themes | P: Future task for now; Harness does not bundle themes |

`DISABLE_AUTOUPDATER` stops auto-updates.
`DISABLE_UPDATES` stops even manual `claude update`, so it's for enterprises running fixed versions.
Neither is included in Harness project defaults; organizations that need them configure via managed settings or device management.

When dependencies are missing, first check Claude Code's `/plugin` Errors, `/doctor`, `claude plugin list --json`.
If an unregistered marketplace is the cause, register with `/plugin marketplace add` or `claude plugin marketplace add` and let the built-in auto-resolve handle it.

## Maintenance — File organization

Regular maintenance tasks:

| Task | Command |
|------|---------|
| Delete old logs | `find .claude/logs -mtime +30 -delete` |
| Compress Plans.md | Move completed tasks to archive section |
| Delete old traces | `tail -1000 .claude/state/agent-trace.jsonl > /tmp/trace && mv /tmp/trace .claude/state/agent-trace.jsonl` |

## Related skills

- `harness-plan` — Create project plan after setup
- `harness-work` — Execute tasks after setup
- `harness-review` — Review setup configuration
