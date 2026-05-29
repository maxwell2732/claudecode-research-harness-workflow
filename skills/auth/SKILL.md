---
name: auth
description: "Explicit helper for authentication and payment implementation with Clerk, Supabase Auth, or Stripe. Do NOT load for: general UI work, database design, or non-auth features."
description-en: "Explicit helper for authentication and payment implementation with Clerk, Supabase Auth, or Stripe. Do NOT load for: general UI work, database design, or non-auth features."
allowed-tools: ["Read", "Write", "Edit", "Bash"]
user-invocable: false
disable-model-invocation: true
---

# Auth Skills

A set of skills responsible for implementing authentication and payment features.

## Feature Details

| Feature | Details |
|---------|---------|
| **Authentication** | See [references/authentication.md](${CLAUDE_SKILL_DIR}/references/authentication.md) |
| **Payments** | See [references/payments.md](${CLAUDE_SKILL_DIR}/references/payments.md) |

## Execution Steps

1. **Quality gate** (Step 0)
2. Classify the user's request (authentication or payments)
3. Read the appropriate reference file from "Feature Details" above
4. Implement following its instructions

### Step 0: Quality Gate (Security Checklist)

Since authentication and payment features always carry high security risk, always display the following before starting work:

```markdown
🔐 Security Checklist

This work is security-critical. Please confirm the following:

### Authentication
- [ ] Passwords are hashed (bcrypt/argon2)
- [ ] Session management is secure (HTTPOnly Cookie)
- [ ] CSRF protection is implemented
- [ ] Rate limiting (brute-force protection)

### Payments
- [ ] Sensitive data (card numbers, etc.) is not stored on the server
- [ ] Stripe/payment provider SDK is used correctly
- [ ] Webhook signature verification
- [ ] Amount tampering prevention (amount finalized server-side)

### Common
- [ ] Error messages are not overly detailed (prevent information leakage)
- [ ] Sensitive information is not written to logs
```

### Security Severity Display

```markdown
⚠️ Caution Level: 🔴 High

This feature carries the following risks:
- Credential exposure
- Unauthorized access
- Fraudulent payment manipulation

Expert review is recommended.
```

### For VibeCoder

```markdown
🔐 Building login and payment features safely

1. **"Hash" passwords**
   - Store passwords in a form that cannot be reversed
   - Safe even if data is leaked

2. **Do not store card information on your server**
   - Delegate to a dedicated service like Stripe
   - Never store anything on your own server

3. **Keep error messages vague**
   - Use "Authentication failed" instead of "Password is incorrect"
   - Don't give hints to malicious actors
```
