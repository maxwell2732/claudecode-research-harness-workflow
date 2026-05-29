# Skill Catalog

Reference document for skill hierarchy, all skill categories, and development skills.

## Skill Evaluation Flow

> For heavy tasks (parallel review, CI fix loops), skills launch subagents from `agents/` in parallel using the Task tool.

**Before starting any work, always follow this flow:**

1. **Evaluate**: Check available skills and determine whether any match the current request
2. **Invoke**: If a matching skill exists, invoke it with the Skill tool before starting work
3. **Execute**: Follow the skill's steps to carry out the work

```
User request
    ↓
Evaluate skills (is there a matching one?)
    ↓
YES → Invoke with Skill tool → Follow skill steps
NO  → Handle with normal reasoning
```

## Skill Hierarchy

Skills are organized in a hierarchy of **parent skills (categories)** and **child skills (specific functions)**.

```
skills/
├── impl/                  # Implementation (feature addition, test creation)
├── harness-review/        # Review (quality, security, performance)
├── verify/                # Verification (build, error recovery, fix application)
├── setup/                 # Integrated setup hub (project initialization, tool configuration, 2-Agent, harness-mem, Codex CLI, rule localization)
├── memory/                # Memory management (SSOT, decisions.md, patterns.md, SSOT promotion, memory search)
├── troubleshoot/          # Diagnostics and repair (errors, including CI failures)
├── principles/            # Principles and guidelines (VibeCoder, diff editing)
├── auth/                  # Authentication and payments (Clerk, Supabase, Stripe)
├── deploy/                # Deployment (Vercel, Netlify, analytics)
├── ui/                    # UI (components, feedback)
├── handoff/               # Workflow (handoff, auto-fix)
├── notebookLM/            # Documentation (NotebookLM, YAML)
└── maintenance/           # Maintenance (cleanup)
```

**How to use:**
1. Invoke a parent skill with the Skill tool
2. The parent skill routes to the appropriate child skill (doc.md) based on user intent
3. Follow the child skill's steps to execute the work

## Full Skill Category List

| Category | Purpose | Trigger examples |
|---------|------|-----------|
| work | Task implementation (automatic scope determination, --codex support) | "implement this", "do everything", "/work" |
| breezing | Fully automated execution with Agent Teams (--codex support) | "run as a team", "breezing" |
| impl | Implementation, feature addition, test creation | "implement this", "add feature", "write code" |
| harness-review | Code review, quality check | "review this", "security", "performance" |
| verify | Build verification, error recovery | "build", "error recovery", "verify" |
| setup | Integrated setup hub (project initialization, tool configuration, 2-Agent, harness-mem, Codex CLI, rule localization) | "setup", "CLAUDE.md", "initialize", "CI setup", "2-Agent", "Cursor config", "harness-mem", "codex-setup" |
| memory | SSOT management, memory search, SSOT promotion, Cursor-linked memory | "SSOT", "decisions.md", "merge", "SSOT promotion", "memory search", "harness-mem" |
| principles | Development principles, guidelines | "principles", "VibeCoder", "safety" |
| auth | Authentication, payment features | "login", "Clerk", "Stripe", "payment" |
| deploy | Deployment, analytics | "deploy", "Vercel", "GA" |
| ui | UI component generation | "component", "hero", "form" |
| handoff | Handoff, auto-fix | "handoff", "report to PM", "auto-fix" |
| notebookLM | Document generation | "document", "NotebookLM", "slides" |
| troubleshoot | Diagnostics and repair (including CI failures) | "not working", "error", "CI failed" |
| maintenance | File organization | "organize", "cleanup" |
| harness-plan-brief | Pre-start Plan Brief HTML generation (Phase 65.1) | "plan brief", "plan overview", "plan review" |
| harness-accept | Acceptance Demo HTML generation at handoff (Phase 65.2) | "acceptance decision", "ship/wait/reject", "acceptance review" |
| harness-progress | Progress Tracker HTML generation + auto-regeneration (Phase 65.4) | "check progress", "progress board", "dashboard" |

## Development Skills (Non-public)

The following skills are for development and experimentation only and are not included in the repository (excluded via .gitignore):

```
skills/
├── test-*/      # Test skills
└── x-promo/     # X post creation skill (for development)
```

These skills are for use in individual development environments only and must not be included in plugin distributions.

## Related Documents

- [CLAUDE.md](../CLAUDE.md) - Project development guide (overview)
- [docs/CLAUDE-feature-table.md](./CLAUDE-feature-table.md) - Claude Code new feature utilization table
- [docs/CLAUDE-commands.md](./CLAUDE-commands.md) - Key commands list
- [.claude/rules/skill-editing.md](../.claude/rules/skill-editing.md) - Skill file editing rules
