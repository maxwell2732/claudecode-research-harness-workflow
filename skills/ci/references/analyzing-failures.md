---
name: ci-analyze-failures
description: "Analyze CI failure logs to identify root causes. Use when tests or builds fail in a CI/CD pipeline."
allowed-tools: ["Read", "Grep", "Bash"]
---

# CI Analyze Failures

A skill for analyzing CI/CD pipeline failures and identifying root causes.
Interprets logs from GitHub Actions, GitLab CI, and similar systems.

---

## Inputs

- **CI logs**: Logs from the failed job
- **run_id**: CI run identifier (if available)
- **Repository context**: CI configuration files

---

## Outputs

- **Root cause identification**: Specific cause of the failure
- **Fix suggestions**: Proposed remediation steps

---

## Execution Steps

### Step 1: Check CI Status

```bash
# For GitHub Actions
gh run list --limit 5

# Check the latest failure
gh run view --log-failed
```

### Step 2: Retrieve Failure Logs

```bash
# Logs for a specific run
gh run view {{run_id}} --log

# Failed steps only
gh run view {{run_id}} --log-failed
```

### Step 3: Analyze Error Patterns

#### Build Errors

```
Pattern: "error TS\d+:" or "Build failed"
Possible causes:
- TypeScript type errors
- Missing dependencies
- Syntax errors
```

#### Test Errors

```
Pattern: "FAIL" or "✕" or "AssertionError"
Possible causes:
- Test failures
- Test timeouts
- Mock mismatches
```

#### Dependency Errors

```
Pattern: "npm ERR!" or "Could not resolve"
Possible causes:
- package.json inconsistency
- Authentication for private packages
- Version conflicts
```

#### Environment Errors

```
Pattern: "not found" or "undefined"
Possible causes:
- Missing environment variables
- Missing secrets
- Path issues
```

### Step 4: Output Analysis Results

```markdown
## 🔍 CI Failure Analysis

**Run ID**: {{run_id}}
**Failure time**: {{timestamp}}
**Failed step**: {{step_name}}

### Root Cause

**Error type**: {{Build / Test / Dependency / Environment}}

**Error message**:
```
{{core error content}}
```

**Cause analysis**:
{{Specific explanation of the cause}}

### Related Files

| File | Relevance |
|------|-----------|
| `{{path}}` | {{related content}} |

### Fix Suggestions

1. {{Specific fix step 1}}
2. {{Specific fix step 2}}

### Auto-fix Feasibility

- Auto-fix: {{Possible / Not possible}}
- Reason: {{reason}}
```

---

## Error Pattern Dictionary

### TypeScript Errors

| Error code | Meaning | Typical fix |
|------------|---------|-------------|
| TS2304 | Name not found | Add import |
| TS2322 | Type mismatch | Fix type |
| TS2345 | Wrong argument type | Fix argument |
| TS7006 | Implicit any | Add type annotation |

### npm Errors

| Error | Meaning | Typical fix |
|-------|---------|-------------|
| ERESOLVE | Dependency resolution failure | Delete package-lock & reinstall |
| ENOENT | File not found | Check path |
| EACCES | Permission error | Check CI configuration |

### Jest/Vitest Errors

| Error | Meaning | Typical fix |
|-------|---------|-------------|
| Timeout | Test timeout | Extend timeout or fix async |
| Snapshot | Snapshot mismatch | `npm test -- -u` |

---

## Priority Order for Multiple Errors

1. **Build errors**: Fix with highest priority
2. **Dependency errors**: Resolve before building
3. **Test errors**: Address after build succeeds
4. **Lint errors**: Address last

---

## Connecting to Next Actions

After analysis is complete:

> 📊 **Analysis complete**
>
> **Cause**: {{summary of cause}}
>
> **Next actions**:
> - "Fix it" → Attempt automatic fix
> - "More details" → Further detailed analysis
> - "Skip" → Switch to manual handling

---

## Notes

- **Logs can be large**: Extract the important parts
- **Watch for cascading errors**: Find the first error
- **Environment differences**: Consider differences between local and CI
