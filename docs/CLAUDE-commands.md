# Key Commands Reference

A reference list of commands and handoffs used during Claude harness development.

## Key Commands (used during development)

| Command | Purpose |
|---------|---------|
| `/plan-with-agent` | Add improvement tasks to Plans.md |
| `/work` | Implement tasks (auto scope detection, --codex support) |
| `/breezing` | Full parallel execution with Agent Teams (--codex support) |
| `/reload-plugins` | Immediate reflection after skill/hook edits (no restart required) |
| `/harness-review` | Review changes |
| `/validate` | Plugin validation |
| `/remember` | Record learnings |

## Handoffs

| Command | Purpose |
|---------|---------|
| `/handoff-to-cursor` | Completion report when working in Cursor |

**Skills (auto-triggered in conversation)**:
- `handoff-to-impl` - "Pass to implementer" → PM → Impl handoff request
- `handoff-to-pm` - "Report completion to PM" → Impl → PM completion report

## Related Documents

- [CLAUDE.md](../CLAUDE.md) - Project development guide
- [docs/CLAUDE-skill-catalog.md](./CLAUDE-skill-catalog.md) - Skill catalog
- [docs/CLAUDE-feature-table.md](./CLAUDE-feature-table.md) - New feature utilization table
