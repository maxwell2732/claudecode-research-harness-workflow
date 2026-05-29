# Skill Routing Rules (Reference)

Reference document for routing rules between skills.

> **SSOT location**: The `description` field of each skill is the SSOT for routing.
> This file is a reference providing detailed explanations and examples; actual routing depends on each skill's description.
>
> **Important**: Each skill's description and the "Do NOT Load For" table in the body must match exactly.

## Codex-related routing

### harness-review (includes Codex review functionality)

**Purpose**: Provides second-opinion reviews with Codex CLI (`codex exec`) (integrated from `codex-review` in v3)

**Trigger keywords** (quoted from description):
- "review", "code review", "plan review"
- "scope analysis", "security", "performance"
- "quality checks", "PRs", "diffs"
- "/harness-review"

**Exclusion keywords** (quoted from description):
- "implementation", "new features", "bug fixes"
- "setup", "release"

### harness-work --codex (includes Codex implementation functionality)

**Purpose**: Use Codex as an implementation engine (integrated in v3)

**Trigger keywords**:
- "implement", "execute", "/work"
- "breezing", "team run"
- "--codex", "--parallel"

**Exclusion keywords** (quoted from description):
- "planning", "code review", "release"
- "setup", "initialization"

**Invocation**: Run with `/harness-work --codex`

## Routing decision flow (reference)

> This section describes Claude Code's internal behavior and is not an additional keyword definition.
> Actual routing is determined solely by keywords listed in each skill's description.

```
User input
    │
    ├── Matches trigger keywords in description → Load matching skill
    ├── Matches exclusion keywords in description → Exclude matching skill
    └── Neither → Normal skill matching
```

## Priority rules (reference)

Priority when keywords match multiple skills:

1. **Exclusion takes highest priority**: Skills matching exclusion keywords are never loaded
2. **More specific keywords take priority**: Exact match > partial match

> **Note**: "Context-based judgment" is not used because it creates ambiguity. Routing is determined decisively by description keywords.

## Update rules

1. **description = SSOT**: The `description` field of each skill is the official definition for routing
2. **Must match body**: Each skill's "Do NOT Load For" table must exactly match the description
3. **Role of this file**: Reference for detailed explanations and decision flow (not SSOT)
4. **Maintain complete list**: List specific keywords explicitly; do not use generic expressions like "~~ in general"
