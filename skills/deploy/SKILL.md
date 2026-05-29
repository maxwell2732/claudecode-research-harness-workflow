---
name: deploy
description: "Deploy to Vercel/Netlify. One-way ticket to production arranged. Use when user mentions deployment, Vercel, Netlify, analytics, or health checks. Do NOT load for: implementation work, local development, reviews, or setup."
description-en: "Deploy to Vercel/Netlify. One-way ticket to production arranged. Use when user mentions deployment, Vercel, Netlify, analytics, or health checks. Do NOT load for: implementation work, local development, reviews, or setup."
allowed-tools: ["Read", "Write", "Edit", "Bash", "Monitor"]
disable-model-invocation: true
user-invocable: false
argument-hint: "[vercel|netlify|health]"
context: fork
---

# Deploy Skills

A set of skills responsible for deployment and monitoring configuration.

## Feature Details

| Feature | Details |
|---------|---------|
| **Deployment Setup** | See [references/deployment-setup.md](${CLAUDE_SKILL_DIR}/references/deployment-setup.md) |
| **Analytics** | See [references/analytics.md](${CLAUDE_SKILL_DIR}/references/analytics.md) |
| **Environment Diagnostics** | See [references/health-checking.md](${CLAUDE_SKILL_DIR}/references/health-checking.md) |

## Execution Steps

1. Classify the user's request
2. Read the appropriate reference file from "Feature Details" above
3. Configure following its instructions
