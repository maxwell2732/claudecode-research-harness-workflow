# Sandbox Allowlist Recipe (for Firecrawl / Web Scraping)

A solution recipe for when Firecrawl, tech blog fetching, or external API calls in other projects using claude-code-harness are blocked with `HTTP/2 403 / x-deny-reason: host_not_allowed`.

> **TL;DR**: The CC sandbox defaults to **empty allowlist = deny all**. The correct path is to add `sandbox.network.allowedDomains` to `~/.claude/settings.json` at the user global level. Since AI-driven rewrites are denied by the self-audit guard, this requires **manual user editing**.

## Symptoms

Firecrawl CLI / WebFetch / curl returns 403 / connection refused in external projects. The Bash subprocess log shows:

```
HTTP/2 403
x-deny-reason: host_not_allowed
```

Or:

```
curl: (6) Could not resolve host: api.firecrawl.dev
```

## Cause

The Claude Code sandbox (macOS Seatbelt / Linux bubblewrap) uses an **allowlist default**. No `sandbox.network.allowedDomains` in `~/.claude/settings.json` = no outbound communication to any host.

Checking the Firecrawl plugin `SKILL.md` shows `allowed-tools: Bash(firecrawl *)`. This means the Firecrawl CLI runs as a Bash subprocess and is directly affected by the sandbox (it is not an MCP server).

## Fix: Merge sandbox settings into `~/.claude/settings.json`

**Important**: There are 2 cases depending on whether **an existing `sandbox` key already exists** in `~/.claude/settings.json`. Accidentally overwriting an existing sandbox will erase existing guardrails like `failIfUnavailable` / `filesystem.denyRead` / `network.deniedDomains`.

### Step 0: Check for existing sandbox key

```bash
jq 'has("sandbox")' ~/.claude/settings.json
# false → Case A (new addition)
# true  → Case B (inner merge)
```

### Case A: No existing `sandbox` key (new addition)

Add one `sandbox` key at the **same level (top-level)** as existing `permissions` / `hooks` / `enabledPlugins` / `mcpServers` etc. Do not touch existing keys:

```json
{
  "permissions": { /* preserve existing */ },
  "hooks": { /* preserve existing */ },
  "enabledPlugins": { /* preserve existing */ },
  "mcpServers": { /* preserve existing */ },
  /* ... preserve all other existing top-level keys ... */

  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": [
      "docker", "docker-compose", "watchman",
      "systemctl", "launchctl", "brew services"
    ],
    "network": {
      "allowedDomains": [
        "github.com", "api.github.com", "raw.githubusercontent.com",
        "codeload.github.com", "objects.githubusercontent.com",
        "registry.npmjs.org", "api.anthropic.com",
        "pypi.org", "files.pythonhosted.org",
        "proxy.golang.org", "sum.golang.org",
        "crates.io", "static.crates.io", "rubygems.org",
        "api.firecrawl.dev", "firecrawl.dev",
        "techblog.zozo.com", "note.com", "assets.st-note.com",
        "zenn.dev", "qiita.com", "dev.to", "medium.com",
        "cdn-ak.f.st-hatena.com",
        "engineering.dena.com", "developers.cyberagent.co.jp",
        "tech.uzabase.com", "engineer.crowdworks.jp", "tech.smarthr.jp"
      ],
      "deniedDomains": [
        "169.254.169.254", "metadata.google.internal", "metadata.azure.com",
        "pastebin.com", "transfer.sh", "0x0.st",
        "paste.ee", "termbin.com", "ix.io"
      ]
    }
  }
}
```

### Case B: Existing `sandbox` key present (inner merge)

**While preserving** existing `sandbox.failIfUnavailable` / `sandbox.filesystem` / `sandbox.network.deniedDomains` etc., add/integrate fields inside. **Replacing the entire `sandbox` block is prohibited** (would destroy existing guardrails).

Merge rules:

| Field | Operation | Note |
|-------|-----------|------|
| `sandbox.enabled` | Set to `true` | Preserve if already `true` |
| `sandbox.autoAllowBashIfSandboxed` | Set to `true` | New addition |
| `sandbox.failIfUnavailable` | **Preserve existing** | Do not touch |
| `sandbox.excludedCommands` | If array: **union (merge deduped)**; if absent: new addition | Do not remove existing items |
| `sandbox.network.allowedDomains` | **Existing array + 29 from this recipe as union** | Do not remove existing hosts |
| `sandbox.network.deniedDomains` | **Existing array + 9 from this recipe as union** | Keep existing blocked hosts |
| `sandbox.filesystem` | **Preserve existing** | Touch forbidden (denyRead/allowRead etc. would be lost) |

### Auto-merge jq one-liner (works for both Case A and B)

Manual merging in an editor risks duplicates and guardrail erasure. The following jq one-liner is safe for both cases:

```bash
SETTINGS=~/.claude/settings.json

# 1. Save original file mode (handles cases where file is protected as 600 etc. due to containing tokens)
#    Cross-platform stat: try Linux GNU stat -c first, fall back to macOS BSD stat -f
#    (Order matters: BSD stat -f on Linux misinterprets as filesystem-status flag)
MODE=$(stat -c '%a' "$SETTINGS" 2>/dev/null || stat -f '%Lp' "$SETTINGS")

# 2. Backup (cp -p preserves mode/ownership)
cp -p "$SETTINGS" "${SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"

# 3. Merge (preserve existing sandbox.filesystem / failIfUnavailable; union arrays)
jq '
  .sandbox.enabled = true |
  .sandbox.autoAllowBashIfSandboxed = true |
  .sandbox.excludedCommands = (((.sandbox.excludedCommands // []) + [
    "docker", "docker-compose", "watchman",
    "systemctl", "launchctl", "brew services"
  ]) | unique) |
  .sandbox.network.allowedDomains = (((.sandbox.network.allowedDomains // []) + [
    "github.com", "api.github.com", "raw.githubusercontent.com",
    "codeload.github.com", "objects.githubusercontent.com",
    "registry.npmjs.org", "api.anthropic.com",
    "pypi.org", "files.pythonhosted.org",
    "proxy.golang.org", "sum.golang.org",
    "crates.io", "static.crates.io", "rubygems.org",
    "api.firecrawl.dev", "firecrawl.dev",
    "techblog.zozo.com", "note.com", "assets.st-note.com",
    "zenn.dev", "qiita.com", "dev.to", "medium.com",
    "cdn-ak.f.st-hatena.com",
    "engineering.dena.com", "developers.cyberagent.co.jp",
    "tech.uzabase.com", "engineer.crowdworks.jp", "tech.smarthr.jp"
  ]) | unique) |
  .sandbox.network.deniedDomains = (((.sandbox.network.deniedDomains // []) + [
    "169.254.169.254", "metadata.google.internal", "metadata.azure.com",
    "pastebin.com", "transfer.sh", "0x0.st",
    "paste.ee", "termbin.com", "ix.io"
  ]) | unique)
' "$SETTINGS" > "${SETTINGS}.tmp" \
  && chmod "$MODE" "${SETTINGS}.tmp" \
  && mv "${SETTINGS}.tmp" "$SETTINGS"

# 4. Verify mode was preserved (should match original mode)
#    Same order as MODE retrieval: Linux GNU stat -c → macOS BSD stat -f fallback
stat -c '%a' "$SETTINGS" 2>/dev/null || stat -f '%Lp' "$SETTINGS"
```

> **Why `chmod "$MODE"` is needed**: The `>` redirect + `mv` pattern creates the tmp file with umask (typically `022` → 644). If the original `~/.claude/settings.json` was `600` (strong permission protection due to containing tokens/secrets), the merge would cause a **security regression by broadening read access**. Explicitly restoring the original mode with `chmod "$MODE"` keeps files containing tokens safe.

> **Why this jq cannot be run by AI**: `~/.claude/settings.json` is protected from AI self-tampering (`Edit/Write(.claude/settings*)` deny + auto mode classifier also blocks Bash bypass). This recipe is intended to be **run by the user themselves in a terminal**.

### Verification

```bash
# JSON syntax
jq -e '.' ~/.claude/settings.json > /dev/null && echo "VALID JSON"

# Count allowedDomains
# Case A (no existing sandbox): exactly 29
# Case B (existing sandbox): 29 or more (union with existing)
jq '.sandbox.network.allowedDomains | length' ~/.claude/settings.json

# Count deniedDomains
# Case A: exactly 9 / Case B: 9 or more
jq '.sandbox.network.deniedDomains | length' ~/.claude/settings.json

# Check required hosts are included (minimum condition common to Case A/B)
# Note: jq array `contains` does substring match on strings, so "www.firecrawl.dev"
# would false-positive match "firecrawl.dev". Use any(. == "...") for exact match
# (any() does not include ! so no zsh history expansion conflict)
jq -e '
  (.sandbox.network.allowedDomains | any(. == "api.firecrawl.dev")) and
  (.sandbox.network.allowedDomains | any(. == "firecrawl.dev")) and
  (.sandbox.network.deniedDomains | any(. == "169.254.169.254")) and
  (.sandbox.network.deniedDomains | any(. == "pastebin.com"))
' ~/.claude/settings.json && echo "REQUIRED HOSTS PRESENT"

# Case B only: verify existing filesystem section is not destroyed
jq '.sandbox.filesystem // "no filesystem section (Case A)"' ~/.claude/settings.json

# Verify existing enabledPlugins are intact (common to Case A/B)
jq '.enabledPlugins | length' ~/.claude/settings.json
# → Should maintain existing count
```

### Restart CC

Sandbox settings are **read only at session start**. After merging, fully restart CC (cmd+Q → restart) to initialize.

## Configuration intent

3-layer pre-allow design:

| Layer | Domains | Purpose |
|-------|---------|---------|
| **Dev core** (14) | `github.com` / `api.github.com` / `raw.githubusercontent.com` / `codeload.github.com` / `objects.githubusercontent.com` / `registry.npmjs.org` / `api.anthropic.com` / `pypi.org` / `files.pythonhosted.org` / `proxy.golang.org` / `sum.golang.org` / `crates.io` / `static.crates.io` / `rubygems.org` | npm install / pip install / go mod / cargo / git clone |
| **Firecrawl** (2) | `api.firecrawl.dev` / `firecrawl.dev` | Firecrawl API endpoints |
| **Scrape targets** (13) | `techblog.zozo.com` / `note.com` / `assets.st-note.com` / `zenn.dev` / `qiita.com` / `dev.to` / `medium.com` / `cdn-ak.f.st-hatena.com` / `engineering.dena.com` / `developers.cyberagent.co.jp` / `tech.uzabase.com` / `engineer.crowdworks.jp` / `tech.smarthr.jp` | Japanese/English tech blogs and article scraping |

The 9 `deniedDomains` (cloud metadata endpoints and pastebin-type services) are maintained as **SSRF + information leak path blocking**. Even if allowed in `allowedDomains`, these take priority and are denied.

## Meaning of each sandbox option

| Key | Value | Meaning |
|-----|-------|---------|
| `enabled` | `true` | Sandbox is ON from CC startup. Manual `/sandbox` command is not needed |
| `autoAllowBashIfSandboxed` | `true` | Bash subprocesses confined to the sandbox are auto-allowed without permission dialogs. Autonomous sessions don't get stuck |
| `excludedCommands` | `docker / docker-compose / watchman / systemctl / launchctl / brew services` | OS-level commands that cannot run inside sandbox are routed to run outside |
| `network.allowedDomains` | 29 entries | Hosts permitted for outbound communication |
| `network.deniedDomains` | 9 entries | Denied even if on allowlist (takes priority) |

## Outbound communication smoke test (requires `FIRECRAWL_API_KEY`)

Verify actual connectivity through the sandbox:

```bash
firecrawl scrape "https://techblog.zozo.com/" -o /tmp/test.md
# → Success: /tmp/test.md will be written as markdown
# → Failure (HTTP/2 403 / x-deny-reason: host_not_allowed):
#   Sandbox settings are not yet effective (possibly forgot to restart CC)
```

## Why AI does not automatically edit this

`~/.claude/settings.json` is a security boundary that constrains CC itself. To prevent AI from loosening its own constraints (self-tampering), CC's auto mode classifier and `Edit(.claude/settings*)` / `Write(.claude/settings*)` deny rule **doubly** block it. Bash-based bypasses are also denied by the classifier as "User Deny Rules circumvention."

Therefore:
- AI side: **only presents** the patch JSON
- User side: manually applies + verifies

This is the Harness **responsibility boundary**. AI is not granted autonomous authority to change security settings.

## Troubleshooting

### Still getting 403 after editing

1. Possible JSON syntax error. Verify with `jq -e '.' ~/.claude/settings.json`
2. **Fully restart CC** (cmd+Q → restart). Sandbox settings are read at session start
3. `FIRECRAWL_API_KEY` env var may not be set. Check `.zshrc`

### Need a different domain

Just add it to the `allowedDomains` array. In CC 2.1.113+, `*.example.com` wildcards are also supported, but **explicit enumeration is recommended for leak visibility**.

### Want to temporarily disable sandbox

Set `"enabled": false`. Or launch with `--no-sandbox` flag. This is a security regression, so limit to temporary use only.

## Related

- `templates/sandbox-settings.json.template` — Harness reference configuration. **Fully synced with this recipe's 29-domain allowlist + 9-domain denylist**. For new projects (= no existing sandbox = Case A), copying the entire `sandbox` section from the template is reliable. **For Case B (existing sandbox), use jq merge** (copying the template wholesale destroys existing `filesystem` / `failIfUnavailable`)
- `CLAUDE.md` Permission Boundaries — sandbox settings form a multi-layer defense with AI self-tampering prevention
- `.claude/rules/cross-repo-handoff.md` — Layer 1 (server-side) / Layer 2/3 (client-side) redaction design
- CC v2.1.108+ sandbox spec: official docs `sandbox` section

## History

- 2026-05-21: Initial version. Documented following a case where Firecrawl returned 403 in an external project
