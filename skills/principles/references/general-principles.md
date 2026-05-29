---
name: core-general-principles
description: "Provides core development principles and safety rules. Basic guidelines that apply to all tasks."
---

# General Principles

Core principles for using claude-code-harness. These apply to all workflows.

---

## Safety Principles

### 1. Check Before Changing

Before editing a file, always verify:

- **Review contents with the Read tool**: Understand existing code before making changes
- **Understand the impact scope**: Consider the effect on other files
- **Consider backups**: Check git status before important changes

### 2. Prefer Minimal Diffs

```
❌ Bad: Rewrite the entire file
✅ Good: Use the Edit tool to change only the necessary parts
```

### 3. Respect Configuration Files

Follow the settings in `claude-code-harness.config.json`:

- `safety.mode`: dry-run / apply-local / apply-and-push
- `paths.protected`: Do not modify protected paths
- `paths.allowed_modify`: Only modify permitted paths

---

## Work Principles

### 1. Always Update Plans.md

- When starting a task: `cc:TODO` → `cc:WIP`
- When completing a task: `cc:WIP` → `cc:done`
- When blocked: Add `blocked` and note the reason

### 2. Proceed Incrementally

```
1. Investigate/understand → 2. Plan → 3. Implement → 4. Verify → 5. Report
```

### 3. Handling Errors

- Up to 3 automatic retries
- If unresolved, escalate (report)
- Clearly document the error and remediation steps tried

---

## Communication Principles

### VibeCoder Support

So that those without technical knowledge can understand:

- **Avoid jargon**: Or provide explanations alongside
- **Present next actions**: "Please say ○○ next"
- **Make progress visible**: Clearly show what is done and what remains

### Collaboration with PM (Cursor)

- **Share state via Plans.md**: Maintain as single source of truth
- **Report completion with `/handoff-to-cursor`**: Follow the format
- **Stay within scope**: Confirm before working outside the requested scope

---

## Prohibited Actions

1. **Direct deploy to production** (up to staging only)
2. **Hardcoding sensitive information** (use .env)
3. **Modifying protected paths** (.github/, secrets/, etc.)
4. **Destructive operations without user confirmation** (rm -rf, etc.)
