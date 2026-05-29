---
name: agent-browser
description: "Browser automation through the repo agent-browser CLI. Explicit helper for navigation, forms, screenshots, scraping, and web-app checks. Prefer Browser Use or Playwright when available. Do NOT load for: sharing URLs, embedding links, or editing screenshot files."
description-en: "Browser automation through the repo agent-browser CLI. Explicit helper for navigation, forms, screenshots, scraping, and web-app checks. Prefer Browser Use or Playwright when available. Do NOT load for: sharing URLs, embedding links, or editing screenshot files."
allowed-tools: ["Bash", "Read"]
user-invocable: false
disable-model-invocation: true
context: fork
argument-hint: "[url] [--headless]"
---

# Agent Browser Skill

A skill for browser automation. Uses the agent-browser CLI to perform UI debugging, verification, and automated interaction.

---

## Trigger Phrases

This skill is automatically invoked by the following phrases:

- "Open this page", "Check the URL"
- "Click on", "Type into", "Fill the form"
- "Take a screenshot"
- "Check the UI", "Test the screen"
- "open this page", "click on", "fill the form", "screenshot"

---

## Features

| Feature | Details |
|---------|---------|
| **Browser Automation** | See [references/browser-automation.md](${CLAUDE_SKILL_DIR}/references/browser-automation.md) |
| **AI Snapshot Workflow** | See [references/ai-snapshot-workflow.md](${CLAUDE_SKILL_DIR}/references/ai-snapshot-workflow.md) |

## Execution Steps

### Step 0: Verify agent-browser

```bash
# Check installation
which agent-browser

# If not installed
npm install -g agent-browser
agent-browser install
```

### Step 1: Classify the User's Request

| Request Type | Action |
|--------------|--------|
| Open a URL | `agent-browser open <url>` |
| Click an element | Snapshot → `agent-browser click @ref` |
| Fill a form | Snapshot → `agent-browser fill @ref "text"` |
| Check state | `agent-browser snapshot -i -c` |
| Take screenshot | `agent-browser screenshot <path>` |
| Debug | `agent-browser --headed open <url>` |

### Step 2: AI Snapshot Workflow (Recommended)

For most operations, first **take a snapshot** and then interact using element references:

```bash
# 1. Open the page
agent-browser open https://example.com

# 2. Take a snapshot (AI-optimized, interactive elements only)
agent-browser snapshot -i -c

# Sample output:
# - link "Home" [ref=e1]
# - button "Login" [ref=e2]
# - input "Email" [ref=e3]
# - input "Password" [ref=e4]
# - button "Submit" [ref=e5]

# 3. Interact via element references
agent-browser click @e2           # Click Login button
agent-browser fill @e3 "user@example.com"
agent-browser fill @e4 "password123"
agent-browser click @e5           # Submit
```

### Step 3: Verify the Result

```bash
# Check current state via snapshot
agent-browser snapshot -i -c

# Or check the URL
agent-browser get url

# Take a screenshot
agent-browser screenshot result.png
```

---

## Quick Reference

### Basic Operations

| Command | Description |
|---------|-------------|
| `open <url>` | Open a URL |
| `snapshot -i -c` | AI-optimized snapshot |
| `click @e1` | Click an element |
| `fill @e1 "text"` | Fill a form |
| `type @e1 "text"` | Type text |
| `press Enter` | Press a key |
| `screenshot [path]` | Take a screenshot |
| `close` | Close the browser |

### Navigation

| Command | Description |
|---------|-------------|
| `back` | Go back |
| `forward` | Go forward |
| `reload` | Reload |

### Retrieving Information

| Command | Description |
|---------|-------------|
| `get text @e1` | Get text |
| `get html @e1` | Get HTML |
| `get url` | Current URL |
| `get title` | Page title |

### Waiting

| Command | Description |
|---------|-------------|
| `wait @e1` | Wait for element |
| `wait 1000` | Wait 1 second |

### Debugging

| Command | Description |
|---------|-------------|
| `--headed` | Show browser |
| `console` | Console logs |
| `errors` | Page errors |
| `highlight @e1` | Highlight element |

---

## Session Management

Manage multiple tabs/sessions in parallel:

```bash
# Specify a session
agent-browser --session admin open https://admin.example.com
agent-browser --session user open https://example.com

# List sessions
agent-browser session list

# Operate in a specific session
agent-browser --session admin snapshot -i -c
```

---

## Choosing Between agent-browser and MCP Browser Tools

| Tool | Recommendation | Use Case |
|------|---------------|----------|
| **agent-browser** | ★★★ | First choice. Powerful AI-optimized snapshots |
| chrome-devtools MCP | ★★☆ | When Chrome is already open |
| playwright MCP | ★★☆ | Complex E2E testing |

**Principle**: Try agent-browser first; use MCP tools only if it doesn't work.

---

## Notes

- agent-browser runs in headless mode by default
- Use `--headed` to show the browser
- Sessions persist until explicitly `close`d
- Use sessions for sites requiring authentication
