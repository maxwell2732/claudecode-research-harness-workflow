# Scope Review

## In a nutshell

Scope Review checks whether required work is missing, and conversely whether unnecessary work has been included.

## Checkpoints

- User request and diff match
- Task DoD is satisfied
- No unrelated refactoring is mixed in
- Required scope for docs / tests / mirror / changelog is complete
- Verified that no new public surfaces have been added
- Migration / release / permission boundaries have not been changed without authorization

## Scope creep

Scope creep is "work scope expanding beyond what is needed."
For example, starting to change release scripts during a docs fix task is dangerous.

When scope creep is found, split into one of:

- Required for current DoD: document explicitly in plan and proceed
- Not required for current DoD: cut out as a separate task

## Verdict

| State | Verdict |
|-------|---------|
| Request and diff match | APPROVE |
| DoD not met or unnecessary changes mixed in | REQUEST_CHANGES |
| Business decision needed for scope change | decision_needed |
