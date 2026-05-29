# Typical Workflow Examples

Actual flow of the 2-agent workflow.

---

## Example 1: New Feature Development

### Phase 1: PM (Cursor) Creates a Task

```markdown
# Plans.md

## 🟡 Not Started

- [ ] User profile editing feature `pm:requested`
  - Edit name, email, and avatar image
  - With validation
  - Save change history
```

**PM says**: "Please implement the profile editing feature in Claude Code"

---

### Phase 2: Claude Code Begins Work

```bash
# Run in Claude Code
/work
```

**Claude Code's work**:
1. Load Plans.md
2. Detect `pm:requested` task
3. Update marker to `cc:WIP`
4. Begin implementation
5. Quality review with `/harness-review`
6. If issues found, fix → re-review (loop, up to 3 times)
7. Review OK → Auto-commit

```markdown
# Plans.md (after update)

## 🔴 In Progress

- [ ] User profile editing feature `cc:WIP`
  - Edit name, email, and avatar image
  - With validation
  - Save change history
  - Related files:
    - `src/components/ProfileForm.tsx`
    - `src/lib/api/profile.ts`
```

---

### Phase 3: Claude Code Reports Completion (2-Agent only)

After review OK and auto-commit complete, in 2-agent mode run `/handoff-to-cursor` to report to PM.

> **Handoff is not needed in Solo mode** — Review OK → Auto-commit completes /work.

```bash
# Run in Claude Code (2-Agent mode only)
/handoff-to-cursor
```

**Generated report**:

```markdown
## 📋 Completion Report: User Profile Editing Feature

### Implementation
- Created ProfileForm component
- Profile API endpoint
- Validation with Zod
- Added change history table

### Changed Files
- src/components/ProfileForm.tsx (+150 lines)
- src/lib/api/profile.ts (+80 lines)
- src/lib/validations/profile.ts (+25 lines)
- prisma/schema.prisma (+10 lines)

### Review Results
✅ harness-review APPROVE (no Critical/High issues)

### Test Results
✅ All tests passed (12/12)

### Next Actions
- [ ] Verify on staging environment
- [ ] Design review
```

---

### Phase 4: PM Confirms

```markdown
# Plans.md (after PM update)

## 🟢 Completed

- [x] User profile editing feature `pm:confirmed` (2024-01-15)
```

---

## Example 2: Emergency Bug Fix

### Urgent Request from PM

```markdown
## 🟡 Not Started

- [ ] 🔥 [URGENT] Fix login error `pm:requested`
  - Symptom: Specific users cannot log in
  - Error: "Invalid token format"
  - Priority: Highest
```

### Claude Code's Response

1. Start with `/work`
2. Investigate error logs
3. Identify and fix the cause
4. Add tests
5. Review with `/harness-review` (if issues found, fix → re-review)
6. Review OK → Auto-commit
7. Completion report with `/handoff-to-cursor` (2-Agent only; omit in Solo)

---

## Example 3: CI Auto-Fix

### CI Fails

```
GitHub Actions: ❌ Build failed
- TypeScript error in src/utils/date.ts:45
```

### Claude Code's Automatic Response

1. Detect error
2. Fix type error
3. Re-commit and push

**If it fails 3 times**:

```markdown
## ⚠️ CI Escalation

Attempted to fix 3 times but could not resolve.

### Fixes Tried
1. Added type annotation → failed
2. Updated type definition file → failed
3. Adjusted tsconfig → failed

### Estimated Cause
Possibly outdated type definitions in external library

### Recommended Actions
- [ ] Update @types/xxx to latest version
- [ ] Check the library version itself
```

---

## Example 4: Parallel Task Execution

### When Multiple Tasks Exist

```markdown
## 🟡 Not Started

- [ ] Refactor header component `cc:TODO`
- [ ] Refactor footer component `cc:TODO`
- [ ] Add tests: utility functions `cc:TODO`
```

### When /work Runs

Claude Code determines whether parallel execution is possible:
- Independent tasks → Parallel execution
- Dependent tasks → Sequential execution

```
🚀 Parallel execution started
├─ Agent 1: Header refactoring
├─ Agent 2: Footer refactoring
└─ Agent 3: Add tests
```
