# Claude Code Setup: MCP, Telemetry, Provider Guidance

Last updated: 2026-05-05

An operational guide for setup / MCP / telemetry / provider areas that have grown since Claude Code 2.1.120.

## In a Nutshell

Harness guides users through new Claude Code features without replacing the meaning of official settings.
MCP always-load, telemetry, providers, Windows shell, and deferred tools should each be opted into in small, purpose-specific increments.

## Analogy

Claude Code is the toolbox; Harness is the work procedure guide.
Rather than replacing the contents of the toolbox, Harness guides users on "which tools to have ready for this task."

## Setup checklist

| Item | Harness guidance |
|------|------------------|
| `${CLAUDE_EFFORT}` | Use only to reference the current effort level within a skill body. Leave the effort decision to the caller |
| MCP `alwaysLoad` | Set `true` only for a small number of core tools needed every turn. Keep large servers deferred |
| `claude plugin prune` | Cleanup for orphaned dependencies after plugin uninstall. Run `--dry-run` first |
| `claude project purge` | Strong cleanup that deletes project state. Run `--dry-run` or `--interactive` first |
| `ANTHROPIC_BEDROCK_SERVICE_TIER` | Only set by Bedrock users in provider environments. Do not include in Harness defaults |
| `claude_code.skill_activated.invocation_trigger` | In telemetry, distinguish the reason a skill was activated |
| PowerShell primary shell | On Windows, guide based on PowerShell primary and avoid Bash-only examples |
| Forked skills / subagents deferred tools | For workflows that need deferred tools on the first turn, write them so tool discovery can be done explicitly |

## Effort guidance

`${CLAUDE_EFFORT}` is a variable for referencing the current effort level from within a skill body.
This is not for "the skill to decide its own effort," but for "using the current effort level in explanations and branching."

Acceptable uses:

```md
Current effort: `${CLAUDE_EFFORT}`.
If effort is low, keep the review to confirmed blockers.
If effort is xhigh, include adversarial checks.
```

Patterns to avoid:

- Requiring "always change to xhigh" within the skill body
- Ignoring the effort specified by the user / parent workflow
- Treating an empty `${CLAUDE_EFFORT}` as a failure

## MCP `alwaysLoad`

MCP tool search uses lazy-loading of tool schemas to save context.
`alwaysLoad: true` excludes a server from this lazy loading, making its tools visible from session start.

When to use:

- Small core tool servers used every turn
- Servers that are required on the very first step of a workflow
- A small number of servers whose discovery via tool search would degrade work quality

When to avoid:

- Servers with many tools
- Integrations that are only occasionally used
- Database / observability servers with large schemas

Example:

```json
{
  "mcpServers": {
    "core-tools": {
      "type": "http",
      "url": "https://mcp.example.com/mcp",
      "alwaysLoad": true
    }
  }
}
```

## Plugin cleanup

`claude plugin prune` is a cleanup command that removes plugins that were auto-installed as plugin dependencies but are no longer needed.
It is not intended to remove plugins that the user installed directly.

Recommended:

```bash
claude plugin prune --dry-run
claude plugin prune -y
```

In Harness setup, present this as guidance after an uninstall.
Do not run it unconditionally during initial setup or release procedures.

## Project state cleanup

`claude project purge [path]` is a strong cleanup command that deletes transcripts, tasks, file history, and config entries that Claude Code holds for a project.

Recommended:

```bash
claude project purge . --dry-run
claude project purge . --interactive
```

When to use:

- Archiving a project
- Clearing old local state before a team handoff
- When the project path / owner has changed and old state is getting in the way

When to avoid:

- When work is still in progress
- When transcripts or task queues need to be preserved as an audit trail
- When you just want to "lighten things up" without reviewing what will be deleted

## Provider guidance

`ANTHROPIC_BEDROCK_SERVICE_TIER` should be treated as an environment variable related to provider-side tuning when using Bedrock.
Do not include it as a default value in Harness plugin defaults, templates, or shared project settings.

Reasons:

- Not needed by users who don't use Bedrock
- The correct value varies by team / account / region
- Provider settings are close to the responsibility boundary of the user / organization

Bedrock guidance must not mix Claude Code's `CLAUDE_CODE_USE_BEDROCK` / `ANTHROPIC_*` environment variables with Codex-side provider settings.

## Telemetry guidance

`claude_code.skill_activated.invocation_trigger` is a telemetry attribute for seeing how a skill was activated.

Representative values:

| Value | Meaning |
|----|------|
| `user-slash` | User explicitly launched as a slash command |
| `claude-proactive` | Claude launched proactively from context |
| `nested-skill` | Launched internally from another skill / workflow |

In Harness, ensure that `user-invocable: false` skills such as media / announcement types do not default to assuming `claude-proactive` activation.
The expected activation types are `user-slash` or `nested-skill`.

## Windows shell guidance

On Windows, treat PowerShell as the primary shell when the PowerShell tool is enabled.
Avoid guidance that assumes Git Bash exclusively.

Writing guidelines:

- Include `pwsh` / PowerShell-based examples
- Do not end with POSIX shell-only `export` commands
- Be mindful of differences in path separators and quoting

## Forked skills / subagents and deferred tools

`context: fork` skills and subagents may also need deferred tools.
In workflow bodies, do not leave the tools needed on the first turn ambiguous — explicitly document tool discovery if needed.

Examples:

- If WebFetch is needed, include it in allowed-tools / tools
- If an MCP tool is needed, specify the server name and its purpose
- Write steps for searching and confirming tools, assuming they may not be visible on the first turn

This reduces the risk of incorrectly concluding "the tool I need isn't available" at the start of a forked context's first decision.

## Sources

- Claude Code changelog: https://code.claude.com/docs/en/changelog
- Claude Code MCP docs: https://code.claude.com/docs/en/mcp
- Claude Code plugins reference: https://code.claude.com/docs/en/plugins-reference
