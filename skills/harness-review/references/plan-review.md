# Plan Review

## In a nutshell

Plan Review checks whether `Plans.md` has implementation-ready granularity and order.

## Checkpoints

- Each task is one completion unit
- DoD is verifiable
- Depends has no circular dependencies
- Status matches reality
- Tasks requiring a spec source of truth have `spec_path` or a task to create one
- Implementation order does not defer high-risk parts to later
- Closeout for review / release / mirror / docs is not missing

## Verdict

| State | Verdict |
|-------|---------|
| DoD is measurable, Depends is valid, scope is clear | APPROVE |
| DoD is vague, dependencies broken, spec needed but missing | REQUEST_CHANGES |
| Scope change requires user decision | decision_needed |

## Output

Plan Review prioritizes file:line.
Use the relevant `Plans.md` line, docs, and spec source of truth as evidence.
