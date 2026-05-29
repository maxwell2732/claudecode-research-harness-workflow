---
name: ci
description: "CI red? Call us. Pipeline fire brigade deploys. Use when user mentions CI failures, build errors, test failures, or pipeline issues. Do NOT load for: local builds, standard implementation work, reviews, or setup."
description-en: "CI red? Call us. Pipeline fire brigade deploys. Use when user mentions CI failures, build errors, test failures, or pipeline issues. Do NOT load for: local builds, standard implementation work, reviews, or setup."
allowed-tools: ["Read", "Grep", "Bash", "Task", "Monitor"]
user-invocable: true
context: fork
argument-hint: "[analyze|fix|run]"
---

# CI/CD Skills

A set of skills for resolving CI/CD pipeline issues.

---

## Trigger Conditions

- "CI failed", "GitHub Actions failure"
- "Build error", "Tests won't pass"
- "Fix the pipeline"

---

## Feature Details

| Feature | Details | Trigger |
|---------|---------|---------|
| **Failure Analysis** | See [references/analyzing-failures.md](${CLAUDE_SKILL_DIR}/references/analyzing-failures.md) | "Read the log", "Investigate the cause" |
| **Test Fixing** | See [references/fixing-tests.md](${CLAUDE_SKILL_DIR}/references/fixing-tests.md) | "Fix the test", "Suggest a fix" |

---

## Execution Steps

1. **Test vs. Implementation determination** (Step 0)
2. Classify user intent (analyze or fix)
3. Assess complexity (see below)
4. Read the appropriate reference file from "Feature Details" above, or launch the ci-cd-fixer sub-agent
5. Review results and re-run if necessary

### Step 0: Test vs. Implementation Determination (Quality Gate)

When a CI failure occurs, first triage the cause:

```
CI failure reported
    ↓
┌─────────────────────────────────────────┐
│       Test vs. Implementation           │
├─────────────────────────────────────────┤
│  Analyze the cause:                     │
│  ├── Implementation is wrong → Fix impl │
│  ├── Test is outdated → Confirm w/ user │
│  └── Environment issue → Fix env        │
└─────────────────────────────────────────┘
```

#### Prohibited Actions (Anti-tampering)

```markdown
⚠️ Prohibited actions when CI fails

The following "solutions" are prohibited:

| Prohibited | Example | Correct approach |
|------------|---------|------------------|
| Skipping tests | `it.skip(...)` | Fix the implementation |
| Removing assertions | Delete `expect()` | Verify expected values |
| Bypassing CI checks | `continue-on-error` | Fix the root cause |
| Relaxing lint rules | `eslint-disable` | Fix the code |
```

#### Decision Flow

```markdown
🔴 CI is failing

**A decision is needed**:

1. **Implementation is wrong** → Fix the implementation ✅
2. **Test expected value is outdated** → Ask user for confirmation
3. **Environment issue** → Fix the environment configuration

⚠️ Tampering with tests (skipping, removing assertions) is prohibited

Which applies here?
```

#### When Approval Is Needed

If changes to tests/configuration are unavoidable:

```markdown
## 🚨 Approval Request for Test/Config Change

### Reason
[Why this change is necessary]

### Change Content
[Diff]

### Alternatives Considered
- [ ] Confirmed that fixing the implementation cannot resolve this

Waiting for explicit user approval
```

### Using Extended Git Log Flags (CC 2.1.49+)

Use structured logs to identify the commit that caused the CI failure.

#### Identifying the Culprit Commit

```bash
# Analyze commits with structured format
git log --format="%h|%s|%an|%ad" --date=short -10

# Analyze chronologically with topological order
git log --topo-order --oneline -20

# Link changed files to causes
git log --raw --oneline -5
```

#### Key Use Cases

| Use | Flag | Effect |
|-----|------|--------|
| **Identify failure cause** | `--format="%h|%s"` | Structured commit list |
| **Chronological tracking** | `--topo-order` | Track considering merge order |
| **Understand change impact** | `--raw` | Detailed file change display |
| **Exclude-merge analysis** | `--cherry-pick --no-merges` | Extract only real commits |

#### Sample Output

```markdown
🔍 CI Failure Cause Analysis

Recent commits (structured):
| Hash | Subject | Author | Date |
|------|---------|--------|------|
| a1b2c3d | feat: update API | Alice | 2026-02-04 |
| e4f5g6h | test: add tests | Bob | 2026-02-03 |

Changed files (--raw):
├── src/api/endpoint.ts (Modified) ← type error here
├── tests/api.test.ts (Modified)
└── package.json (Modified)

→ Commit a1b2c3d is likely the cause
  Type error: src/api/endpoint.ts:42
```

## Sub-agent Integration

Launch ci-cd-fixer via the Task tool when the following conditions are met:

- Fix → re-run → fail loop has occurred **2 or more times**
- Or the error spans multiple files in a complex case

**Launch pattern:**

```
Task tool:
  subagent_type="ci-cd-fixer"
  prompt="Please diagnose and fix the CI failure. Error log: {error_log}"
```

ci-cd-fixer operates with safety first (default dry-run mode).
See `agents/ci-cd-fixer.md` for details.

---

## For VibeCoder

```markdown
🔧 How to talk about broken CI

1. **"CI failed" / "It went red"**
   - Automated tests are failing

2. **"Why is it failing?"**
   - Investigate the cause

3. **"Fix it"**
   - Attempt automatic repair

💡 Important: Fixes that "cheat" tests are prohibited
   - ❌ Deleting or skipping tests
   - ✅ Properly fixing the code

If you think "the test seems wrong",
confirm first before deciding on a course of action
```
