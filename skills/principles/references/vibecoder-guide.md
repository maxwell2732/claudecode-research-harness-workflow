---
name: vibecoder-guide
description: "A skill for guiding VibeCoder (non-technical users) to progress development using natural language. Use when providing guidance for non-technical users."
allowed-tools: ["Read"]
---

# VibeCoder Guide

A skill for enabling VibeCoder (non-technical users) to progress development using only natural language.
Automatically responds to questions like "What should I do?" or "What's next?".

---

## Trigger Phrases

This skill is automatically invoked by the following phrases:

- "What should I do?", "What do I do?"
- "What should I work on next?", "What's next?"
- "What can I do?", "What should I do?"
- "I'm stuck", "I don't understand", "Help"
- "Tell me how to use this"
- "what should I do?", "what's next?", "help"

---

## Overview

VibeCoder allows you to know the next action just by asking naturally,
without needing to know technical commands or workflows.

---

## Response Patterns

### Pattern 1: No Project Exists

> **Let's start a project first!**
>
> **Example phrases:**
> - "I want to create a blog"
> - "I want to build a task management app"
> - "I want to make a portfolio site"
>
> A rough idea is fine. Tell me what you want to do.

### Pattern 2: Plans.md Exists but No In-Progress Tasks

> **There's a plan. Let's get to work!**
>
> **Current plan:**
> - Phase 1: Foundation building
> - Phase 2: Core features
> - ...
>
> **Example phrases:**
> - "Start Phase 1"
> - "Do the first task"
> - "Do everything"

### Pattern 3: Task In Progress

> **Working now**
>
> **Current task:** {{task name}}
> **Progress:** {{completed}}/{{total}}
>
> **Example phrases:**
> - "Continue"
> - "Next task"
> - "How far along are we?"

### Pattern 4: After Phase Completion

> **Phase complete!**
>
> **What you can do next:**
> - "Verify it works" → Start development server
> - "Review it" → Code quality check
> - "On to the next phase" → Start next work
> - "Commit" → Save changes

### Pattern 5: Error Occurred

> **A problem occurred**
>
> **Situation:** {{error summary}}
>
> **Example phrases:**
> - "Fix it" → Attempt automatic repair
> - "Explain it" → Explain the problem in detail
> - "Skip it" → Move to next task

---

## Common Phrase Reference

| What you want to do | How to say it |
|--------------------|---------------|
| Start a project | "I want to create ○○" |
| View the plan | "Show me the plan", "What's the current status?" |
| Start work | "Start", "Build it", "Do Phase 1" |
| Continue | "Continue", "Next" |
| Verify it works | "Run it", "Show me" |
| Review code | "Review it", "Check it" |
| Save | "Commit", "Save" |
| When stuck | "What should I do?", "Help" |
| Delegate everything | "Do everything", "I'll leave it to you" |

---

## Context Determination

This skill checks the following to select the appropriate response:

1. **Existence of AGENTS.md** → Whether the project is initialized
2. **Contents of Plans.md** → Whether a plan exists, progress status
3. **Current task state** → Whether `cc:WIP` marker is present
4. **Recent errors** → Whether a problem has occurred

---

## Implementation Notes

When this skill is invoked:

1. Analyze current state
2. Select the appropriate pattern
3. Present concrete "example phrases"
4. Wait for the user's next action

**Important**: Avoid technical jargon; explain in plain language
