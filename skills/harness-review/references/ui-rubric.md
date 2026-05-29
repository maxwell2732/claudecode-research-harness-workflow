# UI Rubric Reviewer Profile

Review profile specialized in visual quality, activated by `harness-review --ui-rubric`.
Rather than ending UI quality assessment with vague impressions, score 4 axes from 0-10 to reach a verdict.

---

## The 4 axes

### 1. Design Quality

- What to check: Information organization, whitespace, visual flow, readability
- Likely low scores: Text is too cramped, priority of elements is unclear
- Likely high scores: What to look at is conveyed naturally

### 2. Originality

- What to check: Distinctiveness, intentional personality, choice of expression
- Likely low scores: Using a generic template layout as-is
- Likely high scores: A unique presentation approach suited to the brand or challenge

### 3. Craft

- What to check: Attention to detail, alignment, spacing, typography, state transitions
- Likely low scores: Subtle misalignments, uneven spacing, rough hover/active states
- Likely high scores: Consistently refined to the detail level, minimal roughness

### 4. Functionality

- What to check: Usability without confusion, main flows work, UI is practically viable
- Likely low scores: Button or form intent is unclear, main flow is broken
- Likely high scores: Users know what to do next without confusion

---

## Anchor examples (0 / 5 / 10)

| Axis | 0 points | 5 points | 10 points |
|------|----------|----------|----------|
| Design Quality | Unclear what is being shown; hard to read | Minimum readability but organization is weak | Information priority and visual flow are clear |
| Originality | Looks like a stock template as-is | Some creativity but weak impression | Has personality suited to the challenge; memorable |
| Craft | Alignment and spacing are off; details are rough | No major breakdowns but finishing is loose | Spacing, text, and state transitions are carefully refined |
| Functionality | Main flow is unclear and hard to use | Main operations work but there are moments of confusion | Main flow is natural and operates without confusion |

---

## Verdict method

1. Score each of the 4 axes from 0-10
2. If `review.rubric_target` exists, use its values as per-axis thresholds
3. If `review.rubric_target` is absent, use default threshold=6 for all 4 axes
4. If any axis is below threshold → `REQUEST_CHANGES`
5. If all axes meet threshold → `APPROVE`

### `rubric_target` example

```json
{
  "design": 7,
  "originality": 6,
  "craft": 8,
  "functionality": 9
}
```

---

## Output format

- Always set `reviewer_profile` to `"ui-rubric"`
- In `observations`, write the reason for score reduction in terms understandable to non-experts
- Include at least 1 "what to fix to raise the score" item per axis

### Output example

```json
{
  "reviewer_profile": "ui-rubric",
  "verdict": "REQUEST_CHANGES",
  "ui_rubric": {
    "scores": {
      "design": 7,
      "originality": 5,
      "craft": 8,
      "functionality": 8
    },
    "targets": {
      "design": 6,
      "originality": 6,
      "craft": 6,
      "functionality": 6
    }
  }
}
```

---

## Verdict notes

- Do not award high scores for flashiness alone
- Do not over-score Originality for "unusual" alone
- When usability is broken, prioritize Functionality and evaluate strictly
- Judge based on **intent and completeness**, not design preference
