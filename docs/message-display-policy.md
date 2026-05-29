# MessageDisplay Hook Policy (Claude Code 2.1.152+)

The `MessageDisplay` hook event was added in CC `2.1.152`.
The hook can transform or hide text immediately before an assistant message is displayed.

Harness limits its use to **audit-backed opt-in display assistance** and prohibits silent modification of assistant output.

## Scope

| Target | Policy |
|--------|--------|
| Harness-distributed hooks (`.claude-plugin/hooks.json`, `hooks/hooks.json`) | **Do not add MessageDisplay hooks** as of Phase 80 |
| Operator / project custom hooks | Opt-in only when following this policy |
| Codex | Out of scope (Claude Code hook surface only) |

## Permitted uses (opt-in)

- **Non-security** display formatting for local locale (e.g., replacing known status markers with user-facing labels)
- Hiding duplicate footers / debug banners (**do not hide guard rail or deny reasons**)
- Notification formatting under `HARNESS_MESSAGE_DISPLAY=1` explicitly enabled by the operator

## Prohibited

- Hiding or rewriting: permission deny/ask reasons, R01-R13 guard rail output, secret values, `.env` contents
- Transforming **audit-trail messages** such as Reviewer `REQUEST_CHANGES` or Worker `advisor-request`
- Semantic changes to assistant answers not approved by the user (rewrites that omit facts from summaries)
- Hiding auto mode classifier output to conceal risk

## Audit requirements

When adding a MessageDisplay hook to a project:

1. Record the hook script name and trigger condition in `.claude/rules/hooks-2.1.152-plus.md` or project rules in one line
2. Log before/after transforms to a jsonl file, or make it verifiable via `/doctor` that the hook is registered
3. Limit hide targets to an allowlist (fixed prefixes / known debug tags)

## Relationship to Auto mode consent

Even if upstream removes opt-in consent for Auto mode, Harness will not use `MessageDisplay` as an alternative mechanism to enable Auto mode.
It will also not be used as a reason to default `--auto-mode` or to relax `autoMode.hard_deny`.

## Related

- `docs/upstream-adoption-plan-2026-05-27.md`
- `.claude/rules/hooks-2.1.152-plus.md`
- `templates/claude/settings.security.json.template` (`autoMode.hard_deny`)
