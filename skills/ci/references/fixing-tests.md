---
name: ci-fix-failing-tests
description: "Guide for fixing tests that fail in CI. Use when attempting automatic fixes after identifying the cause of a CI failure."
allowed-tools: ["Read", "Edit", "Bash"]
---

# CI Fix Failing Tests

A skill for fixing tests that fail in CI.
Fixes either the test code or the implementation code.

---

## Inputs

- **Failing test info**: Test name, error message
- **Test file**: Source of the failing test
- **Code under test**: The implementation being tested

---

## Outputs

- **Fixed code**: Corrected tests or implementation
- **Confirmation that tests pass**

---

## Execution Steps

### Step 1: Identify the Failing Test

```bash
# Run tests locally
npm test 2>&1 | tail -50

# Test a specific file
npm test -- {{test-file}}
```

### Step 2: Classify the Error Type

#### Type A: Assertion Failure

```
Expected: "expected value"
Received: "actual value"
```

→ The implementation differs from expectations, or the expected value in the test is wrong

#### Type B: Timeout

```
Timeout - Async callback was not invoked within the 5000ms timeout
```

→ Async processing does not complete, or takes too long

#### Type C: Type Error

```
TypeError: Cannot read properties of undefined
```

→ Accessing null/undefined, or an initialization problem

#### Type D: Mock-related

```
expected mockFn to have been called
```

→ Mock not set up properly, or function was not called

### Step 3: Determine Fix Strategy

```markdown
## Fix Approach

1. **If the test is correct** → Fix the implementation
2. **If the implementation is correct** → Fix the test
3. **Both need fixing** → Prioritize implementation

Decision criteria:
- Which is correct according to specs/requirements?
- What was recently changed?
- Impact on other tests
```

### Step 4: Apply the Fix

#### Fixing Assertion Failures

```typescript
// If the expected value in the test is wrong
it('calculates correctly', () => {
  // Before fix
  expect(calculate(2, 3)).toBe(5)
  // After fix (if spec requires multiplication)
  expect(calculate(2, 3)).toBe(6)
})

// If the implementation is wrong
// → Fix the implementation file
```

#### Fixing Timeouts

```typescript
// Extend timeout
it('fetches data', async () => {
  // ...
}, 10000)  // Extend to 10 seconds

// Or use async/await correctly
it('fetches data', async () => {
  await waitFor(() => {
    expect(screen.getByText('Data')).toBeInTheDocument()
  })
})
```

#### Fixing Mock Issues

```typescript
// Add mock setup
vi.mock('../api', () => ({
  fetchData: vi.fn().mockResolvedValue({ data: 'mock' })
}))

// Reset in beforeEach
beforeEach(() => {
  vi.clearAllMocks()
})
```

### Step 5: Verify After Fix

```bash
# Re-run the failing test
npm test -- {{test-file}}

# Run all tests (regression check)
npm test
```

---

## Fix Patterns

### Updating Snapshots

```bash
# Update snapshots
npm test -- -u

# Specific test only
npm test -- {{test-file}} -u
```

### Fixing Async Tests

```typescript
// Use findBy (auto-waits)
const element = await screen.findByText('Text')

// Use waitFor
await waitFor(() => {
  expect(mockFn).toHaveBeenCalled()
})
```

### Updating Mock Data

```typescript
// Update mocks to match implementation changes
const mockData = {
  id: 1,
  name: 'Test',
  createdAt: new Date().toISOString()  // New field
}
```

---

## Post-Fix Checklist

- [ ] The previously failing test now passes
- [ ] No other tests are broken
- [ ] The fix aligns with the implementation's intent
- [ ] Tests have not been made excessively permissive

---

## Completion Report Format

```markdown
## ✅ Test Fix Complete

### Changes Made

| Test | Problem | Fix |
|------|---------|-----|
| `{{test name}}` | {{problem}} | {{fix applied}} |

### Verification Results

```
Tests: {{passed}} passed, {{total}} total
```

### Next Action

"Commit" or "Re-run CI"
```

---

## Notes

- **Do not delete tests**: Deletion is a last resort
- **skip is temporary only**: Permanent skips are prohibited
- **Identify the root cause**: Avoid surface-level fixes
