# Skill Overrides Policy (Phase 62.2.5)

> **Status**: Active (2026-05-07)
> **Scope**: Claude Code `2.1.129` added support for 3 modes in `skillOverrides`: `off` / `user-invocable-only` / `name-only`. This document clarifies the relationship with Harness skill governance and establishes appropriate defaults for enterprise and individual use.

## In a nutshell

The 3 `skillOverrides` modes define **whether the model is allowed to override skills**.
Harness sets **nothing by default** (= CC default behavior), but recommends `name-only` for enterprise governance.

## Analogy

A policy deciding how much a chef (model) is allowed to adapt a recipe (skill):
- `off`: No adaptation (only default skills run)
- `user-invocable-only`: Only user-specified adaptations allowed
- `name-only`: Only name-matched adaptations allowed; no spontaneous pulling of other recipes
- Unset: CC default = some adaptation allowed

## 3 mode meanings

| Mode | Meaning | Use case |
|------|---------|----------|
| `off` | Fully disables model-driven skill activation | Advanced enterprise environments; when skill behavior must be fully fixed |
| `user-invocable-only` | Only skills explicitly invoked by the user via `/<skill>` are allowed; model auto-invocation is blocked | Avoiding implicit model-driven skill calls |
| `name-only` | Only activation by matching the skill `name` field is allowed (description-based auto-trigger suppressed) | Preventing unexpected skill activation from fuzzy description matching |
| Unset (default) | CC default behavior. All activations including description-based auto-trigger are enabled | Individual development, Harness default |

## Harness default policy

| Environment | Recommended mode | Reason |
|-------------|-----------------|--------|
| Individual / solo dev | Unset (CC default) | Description-based auto-trigger is convenient |
| Team (small) | Unset + skill manifest audit | Use `scripts/generate-skill-manifest.sh` to visualize skill list |
| Enterprise governance | **`name-only`** | Suppresses fuzzy description matching; only explicit skill invocations allowed |
| Education / training session | `user-invocable-only` | Prevents model auto-invocation; forces learners to actively choose skills |

`harness-init`-generated templates **do not include a default** (= respects CC default).
Enterprise users set this explicitly in `.claude/settings.json` or `.claude/settings.local.json`.

## Relationship with skill manifest

In Phase 59.1.2, `scripts/generate-skill-manifest.sh` was updated to output machine-readable metadata including `kind` / `purpose` / `trigger` / `shape` / `role` / `base` / `pair` / `owner`.

In `skillOverrides: name-only` environments, CC matches only on the skill **name**.
Description-based auto-trigger is disabled.
Therefore skill names should be **semantically explicit** (`harness-work` / `harness-review` etc., verb + noun).

| Skill name | Behavior in name-only mode |
|-----------|---------------------------|
| `harness-work` | Explicit invocation is OK (`/harness-work`) |
| `breezing` (alias) | Explicit invocation is OK (`/breezing`) |
| `harness-loop` | Explicit invocation is OK (`/harness-loop`) |
| Abstract / generic names (e.g., `helper`) | Avoid — risk of name collision |

## Configuration examples

### Enterprise governance (`.claude/settings.json`)

```json
{
  "skillOverrides": "name-only"
}
```

### Individual disable (specific environments only)

```json
{
  "skillOverrides": "off"
}
```

This completely stops implicit skill invocation in automated batch execution.

### Default (not recommended to set explicitly)

There is no mode to explicitly set `default`, so leave it unset to keep CC default.

## Handling in tests / `harness-init`

- `tests/test-settings-baseline.sh` (considered for Phase 62.1.4) **tolerates but does not enforce** the presence of `skillOverrides` (so it does not block `default` in individual development)
- `harness-init` does **not** include `skillOverrides` in the generated settings
- When enterprise governance is needed during porting / customization, refer to this document

## Acceptance criteria (Phase 62.2.5 DoD)

- [x] 3 mode meanings documented in a table
- [x] Recommended defaults fixed per environment (individual / team / enterprise / education)
- [x] Enterprise governance use case documented
- [x] Relationship with Phase 59.1.2 skill manifest documented
- [x] Decision on whether `harness-init` includes defaults recorded (= does not include)

## Related docs

- Phase 59.1.2 (`scripts/generate-skill-manifest.sh`) — skill metadata automation
- Phase 58.2.3 (`docs/upstream-followups-phase58-2026-05-03.md`) — treatment as setup / docs candidate
- Claude Code 2.1.129 CHANGELOG: `skillOverrides` setting now works with `off`, `user-invocable-only`, `name-only` options
