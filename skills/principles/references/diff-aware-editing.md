---
name: core-diff-aware-editing
description: "Edit files with minimal diff to minimize impact on existing code."
allowed-tools: ["Read", "Edit"]
---

# Diff-Aware Editing

A skill for making changes to files with minimal diffs.
Prevents breaking existing code and produces changes that are easy to review.

---

## Core Principles

### 1. Read Before Edit

**Always read the target file before editing**

```
❌ Bad: Overwrite the entire file with the Write tool
✅ Good: Read → review contents → use Edit to change only necessary parts
```

### 2. Prefer Minimal Diffs

Keep changes to the minimum necessary:

- Maintain existing indentation and formatting
- Leave existing comments intact
- Follow the style already in use

### 3. Change One Meaningful Unit at a Time

```typescript
// ❌ Bad: Mix unrelated changes
// Adding a function + changing formatting + organizing imports

// ✅ Good: Focus on one change
// Adding the function only
```

---

## How to Use the Edit Tool

### Pattern 1: Simple Replacement

```
old_string: "const value = 1"
new_string: "const value = 2"
```

### Pattern 2: Adding a Code Block

```
old_string: "// TODO: implement feature"
new_string: "// Feature implemented
const feature = () => {
  // implementation
}"
```

### Pattern 3: Modifying a Function

```
old_string: "function getData() {
  return []
}"
new_string: "function getData() {
  const data = fetchData()
  return data
}"
```

---

## Patterns to Avoid

### 1. Rewriting an Entire File

```
❌ Use the Write tool to completely rewrite a 100-line file
✅ Use the Edit tool to fix only the 5 lines that need changing
```

### 2. Mixing in Formatting Changes

```
❌ Change indentation while adding a feature
✅ Add the feature only. Handle formatting in a separate commit
```

### 3. Adding Unnecessary Blank Lines or Comments

```
❌ Impose your own style
✅ Follow the existing style
```

---

## Pre-Edit Checklist

1. [ ] Confirmed the target file with Read
2. [ ] Identified the parts that need to change
3. [ ] Understood the existing style (indentation, naming conventions)
4. [ ] Confirmed the change is within paths.allowed_modify
5. [ ] Can visualize the expected behavior after the change

---

## Post-Edit Verification

```bash
# Review the diff
git diff

# Check line count (is it too large?)
git diff --stat

# Check for syntax errors
npm run build 2>&1 | head -20
# or
npx tsc --noEmit
```

---

## Editing Multiple Files

When editing multiple files:

1. **Dependency order**: Type definitions → Implementation → Tests
2. **Maintain consistency**: Make related changes together
3. **Keep build passing**: Ensure the build passes after each edit

---

## Handling Errors

If an error occurs during editing:

1. **Re-check the original code**: Use Read to verify current state
2. **Verify old_string match**: Check whitespace and newlines exactly
3. **Split and retry**: Break large changes into smaller pieces
