# Implementation Guide

This guide is the short implementation map for Claude Code Harness
contributors. It complements `README.md`, `AGENTS.md`, and `CLAUDE.md`.

## Current Architecture

Claude Code Harness v4 is Go-first.

- Runtime entrypoint: `bin/harness`
- Go source: `go/`
- Plugin manifest: `.claude-plugin/plugin.json`
- Hook configuration: `hooks/hooks.json` and `.claude-plugin/hooks.json`
- Primary skills: `skills/`
- Public mirrors: `.agents/skills/`, `codex/.codex/skills/`, `opencode/skills/`
- Templates: `templates/`
- Tests and validators: `tests/`, `scripts/ci/`

Older TypeScript `core/` assumptions are not part of the current required
runtime surface. Validators should check the Go runtime and shipped plugin
surfaces instead.

## Implementation Flow

1. Read `Plans.md` and identify the exact task scope.
2. Keep changes narrow and update only the owning files.
3. For skill changes, update `skills/` first.
4. Run `bash scripts/sync-skill-mirrors.sh` after skill changes.
5. Add or update focused tests for the changed behavior.
6. Run the validation commands below before handing off.

## Skill And Mirror Rules

`skills/` is the source of truth for shared skills.

After editing skills, mirror them with:

```bash
bash scripts/sync-skill-mirrors.sh
bash scripts/sync-skill-mirrors.sh --check
```

Codex-specific behavior belongs in `skills-codex/` when the Codex workflow
needs a different instruction surface. Do not add Codex-only behavior to the
shared skill unless it also applies to Claude Code.

## Agent Frontmatter Rules

Plugin subagents do not carry Claude Code runtime-only settings such as:

- `permissionMode`
- top-level `hooks`
- `mcpServers`

Safety is enforced through plugin hooks, Go guardrails, settings, and the
parent session permission model. See `docs/agent-frontmatter-policy.md`.

## Template Rules

All `templates/**/*.template` files must be registered in
`templates/template-registry.json`.

Tracked Markdown templates should include frontmatter:

```markdown
---
_harness_template: "path/from/templates"
_harness_version: "x.y.z"
---
```

Locale-specific templates may share the same output path when they include a
distinct `locale` value in the registry.

## Validation Commands

Use these for broad local validation:

```bash
bash tests/validate-plugin.sh
bash tests/validate-skills.sh
bash scripts/ci/check-consistency.sh
bash scripts/ci/check-template-registry.sh
cd go && go build ./cmd/harness/ && go test ./... && go vet ./...
```

For a full shell-test sweep:

```bash
while IFS= read -r test_file; do
  bash "$test_file" < /dev/null
done < <(find tests -maxdepth 1 -type f \( -name 'test-*.sh' -o -name 'validate-*.sh' \) | sort)
```

## Release Boundaries

Normal implementation work should not edit `VERSION` or
`.claude-plugin/plugin.json` version fields.

Version changes belong to release work and should use the release scripts and
release validation flow documented in `skills/harness-release/`.

