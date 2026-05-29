# Plugin and Managed Settings Policy

Last updated: 2026-05-03

This document fixes Harness setup guidance for operational decisions around plugin / managed settings / managed sandbox additions in Claude Code `2.1.117–2.1.126`.

## In a nutshell

Harness supports safe operation of the plugin marketplace through documentation, but does not replace Claude Code's own resolver or managed settings enforcement.

## Analogy

Think of Harness as a directory sign in an office that tells employees "which entrance to use." The actual turnstile that checks ID badges is Claude Code itself. If the sign builds its own turnstile, the rules become duplicated and it becomes unclear which one is correct.

## Official references

- Claude Code changelog: <https://code.claude.com/docs/en/changelog>
- Claude Code settings: <https://code.claude.com/docs/en/settings>
- Claude Code plugin dependency versions: <https://code.claude.com/docs/en/plugin-dependencies>
- Claude Code plugin install guide: <https://code.claude.com/docs/en/discover-plugins>

## Items and decisions

| Item | Purpose | Harness decision |
|------|---------|-----------------|
| Plugin `themes/` directory | Bundle visual themes with the plugin | `themes/` directory is P (future task) for now. Harness is an operational support plugin and does not bundle themes at this stage |
| `DISABLE_AUTOUPDATER` | Stop auto-updates | Use for adjusting personal/team update timing. Do not stop until manual update is needed |
| `DISABLE_UPDATES` | Stop all update paths | Use only in managed environments. `DISABLE_UPDATES` stops even manual `claude update` |
| `blockedMarketplaces` | Block specific marketplace sources | For managed settings only. Do not include in normal user defaults |
| `strictKnownMarketplaces` | Allow only permitted marketplace sources | For managed settings only. Do not include in normal user defaults |
| `extraKnownMarketplaces` | Guide/register marketplace for team use | Prioritize this for normal team onboarding |
| Plugin dependency auto-resolve / missing dependency hints | Auto-resolve dependent plugins with error guidance | Do not add a Harness-specific dependency resolver. Delegate to Claude Code itself |
| `wslInheritsWindowsSettings` | Inherit Windows managed settings into WSL | For enterprise environments with both Windows and WSL. Do not include in Harness defaults |
| `allowManagedDomainsOnly` / `allowManagedReadPathsOnly` | Align allowed sandbox boundaries with admin settings | Managed settings only. Do not include in Harness normal templates / plugin defaults / harness.toml; do not override Claude Code precedence |

## Update controls

`DISABLE_AUTOUPDATER` is an env var for stopping auto-updates.
Use when you want to stop auto-updates for Claude Code itself and plugins.

`DISABLE_UPDATES` is a stronger management env var.
It stops not only auto-updates but also manual `claude update`.
This is for environments where enterprises distribute only validated versions.

| Purpose | Use | Notes |
|---------|-----|-------|
| Prevent personal unwanted updates | `DISABLE_AUTOUPDATER=1` | Manual updates remain possible |
| IT admin wants to fully close update paths | `DISABLE_UPDATES=1` | Manual `claude update` is also stopped; prepare separate distribution/update procedures |
| Stop Claude Code auto-update but keep plugin auto-update | `DISABLE_AUTOUPDATER=1` + `FORCE_AUTOUPDATE_PLUGINS=1` | Confirm plugin-side dependency constraints and marketplace policy first |

Harness policy:
- Do not include `DISABLE_UPDATES` as a default in `.claude-plugin/settings.json` or project templates.
- For enterprise distribution, set via managed settings or device management env vars.
- Even when stopping updates, maintain the `harness-release` version sync / plugin tag / validate flow.

## Marketplace policy

`blockedMarketplaces` and `strictKnownMarketplaces` are managed settings for admins to control marketplace sources.
They are not for normal user or open-source project defaults.

| Setting | What it does | Best for |
|---------|-------------|---------|
| `blockedMarketplaces` | Blocks specified marketplace sources | Explicitly stopping dangerous/deprecated marketplaces |
| `strictKnownMarketplaces` | Only sources on the allowlist can be added | Enterprises that want to restrict to vetted marketplaces only |
| `extraKnownMarketplaces` | Guide/register marketplaces | Distributing recommended marketplaces to teams |

`strictKnownMarketplaces` is a policy gate.
It only decides what to allow; it does not auto-register the marketplace.
When you also want everyone to register it, combine `strictKnownMarketplaces` and `extraKnownMarketplaces` in managed settings.

Example:

```json
{
  "strictKnownMarketplaces": [
    { "source": "github", "repo": "acme-corp/approved-plugins" }
  ],
  "extraKnownMarketplaces": {
    "acme-tools": {
      "source": {
        "source": "github",
        "repo": "acme-corp/approved-plugins"
      }
    }
  }
}
```

Harness policy:
- Do not include `blockedMarketplaces` / `strictKnownMarketplaces` in normal user defaults.
- Harness setup guides `extraKnownMarketplaces` for team onboarding.
- In enterprise managed environments, defer to the top-priority managed settings.
- Do not implement a Harness-specific marketplace allowlist/blocklist evaluator.

## Dependency resolution

Claude Code reads plugin `dependencies` and auto-resolves dependent plugins during installation.
Even if dependencies become missing later, they are resolved from configured marketplaces via `/reload-plugins`, background plugin auto-update, re-running `claude plugin install`, or `claude plugin marketplace add`.

When dependencies cannot be resolved, the correct entry point is Claude Code's plugin UI, `/doctor`, or `errors` in `claude plugin list --json`.
Do not add a Harness-specific dependency resolver.

What Harness does:
- Guide in setup docs to follow Claude Code's hints for missing dependencies.
- In release docs, use `claude plugin tag` and version constraints to create tags that are easy to dependency-resolve.
- If a marketplace is not registered, guide to use `/plugin marketplace add` or `claude plugin marketplace add` first.

What Harness does NOT do:
- Do not search for plugins from other marketplaces and install them without authorization.
- Do not independently interpret `dependencies` and directly rewrite cache.
- Do not create a resolver that bypasses `blockedMarketplaces` / `strictKnownMarketplaces`.

## Plugin prune

`claude plugin prune` is a cleanup command that removes auto-installed dependency plugins that are no longer needed.
It targets plugins that Claude Code installed to satisfy another plugin's `dependencies` — it is not for removing plugins that the user installed directly.

Harness policy:
- Use as cleanup guidance after plugin uninstall.
- First guide `claude plugin prune --dry-run`.
- Use `-y` only when running in non-interactive CI.
- Do not run unconditionally in release/setup.
- If there is state to keep in `${CLAUDE_PLUGIN_DATA}`, consider `--keep-data` on the uninstall side.

Recommended:

```bash
claude plugin prune --dry-run
claude plugin prune -y
```

## Project purge

`claude project purge [path]` is a strong cleanup command that deletes transcripts, tasks, file history, and config entries that Claude Code holds for a project.

Harness policy:
- Only guide when there is a clear reason to delete local Claude state, such as archiving, handoff, or path/owner changes.
- Use `--dry-run` or `--interactive` first.
- Do not use when in-progress tasks, review evidence, or handoff records are needed.
- Do not treat as a substitute for `Plans.md` or git history cleanup.

Recommended:

```bash
claude project purge . --dry-run
claude project purge . --interactive
```

## Plugin-bundled hooks

Plugins can bundle hooks, but Harness avoids designs where "installing the plugin immediately triggers strong side effects."

Harness policy:
- Bundled hooks are opt-in by default.
- Writes, pushes, deploys, external sends, and tool output modification are disabled by default.
- When using `PostToolUse.hookSpecificOutput.updatedToolOutput`, follow `docs/output-governance.md`.
- Hook stdout must follow JSON contract; human-readable logs go to stderr.

Reason:
Plugins are close to the trust boundary.
If the project's behavior changes significantly just by a user enabling it, root cause analysis and safety verification become difficult.

## Themes decision

In Claude Code `2.1.118`, `/theme` allows creation and switching of named custom themes, and plugins can bundle a `themes/` directory.

Current decision:
- Harness does not bundle themes at this time.
- Keep as `P: future task` in Phase 53.
- The reason is that Harness's primary value is operational safety of Plan / Work / Review, and distributed themes require separate review for branding, accessibility, and terminal compatibility.

If themes are added in the future, these conditions must be met first:

1. Readable in both light and dark terminals.
2. `/plugin` badges and warning text are not obscured.
3. Consistent with Harness docs / screenshots / release copy.
4. Features work completely even without themes.

## Windows / WSL managed settings

`wslInheritsWindowsSettings` is for enterprise environments that want to inherit Windows managed settings into WSL.
For companies using Claude Code on both Windows and WSL, it reduces the overhead of managing settings twice.

Harness policy:
- Do not include in Harness defaults.
- Only organizations managing Windows/WSL device configurations should consider this.
- Since an unintended strong policy entering WSL can affect development experience, confirm the active settings source with `/status` before operating.

## Managed sandbox precedence

In Claude Code `2.1.126`, precedence hardening was added for `allowManagedDomainsOnly` and `allowManagedReadPathsOnly`.

This is a safety-side change to prevent project-local templates or plugin defaults from loosening sandbox boundaries that an admin has defined.

Harness policy:
- Treat `allowManagedDomainsOnly` / `allowManagedReadPathsOnly` as managed settings only.
- Do not include as defaults in Harness normal distributions: `harness.toml`, `.claude-plugin/settings.json`, `templates/claude/settings.security.json.template`, `templates/sandbox-settings.json.template`.
- For enterprise managed environments, use device management or Claude Code managed settings as the source of truth.
- Harness does not create its own managed sandbox resolver.
- `scripts/ci/check-consistency.sh` regression-checks that these managed-only keys have not leaked into normal templates.

## Why this approach

The plugin marketplace and managed settings are the trust boundary itself.
A trust boundary is the line defining "what to treat as safe from this point on."
This line should be handled by Claude Code itself, through managed settings precedence and pre-install checks.

Harness adds work quality and guardrails for Plan / Work / Review on top of that.
Therefore, rather than building its own settings inspector, the policy is to document correct operation using official mechanisms and prevent explanation drift with necessary tests.
