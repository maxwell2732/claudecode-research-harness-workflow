---
name: session-control
description: "Controls session resume/fork(branch) for /work based on --resume/--fork flags. Updates session.json and session.events.jsonl. Internal workflow use only. Do NOT load for: user session management, login state, app state handling."
description-en: "Controls session resume/fork(branch) for /work based on --resume/--fork flags. Updates session.json and session.events.jsonl. Internal workflow use only. Do NOT load for: user session management, login state, app state handling."
allowed-tools: ["Read", "Bash", "Write", "Edit"]
user-invocable: false
disable-model-invocation: true
---

# Session Control Skill

Switches session state in response to `/work` `--resume` / `--fork` flags.

## Feature Details

| Feature | Details |
|---------|---------|
| **Session Resume/Fork** | See [references/session-control.md](${CLAUDE_SKILL_DIR}/references/session-control.md) |

## Execution Steps

1. Check variables passed from workflow
2. Run `scripts/session-control.sh` with appropriate arguments
3. Verify updates to `session.json` and `session.events.jsonl`
