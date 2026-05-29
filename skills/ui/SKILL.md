---
name: ui
description: "Explicit helper for UI components, hero sections, forms, feedback, and contact surfaces. Do NOT load for: authentication, backend implementation, database work, or business logic."
description-en: "Explicit helper for UI components, hero sections, forms, feedback, and contact surfaces. Do NOT load for: authentication, backend implementation, database work, or business logic."
allowed-tools: ["Read", "Write", "Edit", "Bash"]
user-invocable: false
disable-model-invocation: true
---

# UI Skills

A set of skills responsible for generating UI components and forms.

## Constraint Priority and Applicability

1. By default, apply the constraints in `${CLAUDE_SKILL_DIR}/references/ui-skills.md` with highest priority.
2. Apply `${CLAUDE_SKILL_DIR}/references/frontend-design.md` **only when "sharp/distinctive/expressive/brand-focused"** is **explicitly** requested.
3. UI Skills MUST/NEVER rules are maintained in principle. However, the following exceptions are allowed **only when the user explicitly requests them**:
   - Gradients, glow effects, strong decorations
   - Animations (additions/extensions)
   - Custom easing

## Feature Details

| Feature | Details |
|---------|---------|
| **Constraint Set** | See [references/ui-skills.md](${CLAUDE_SKILL_DIR}/references/ui-skills.md) / [references/frontend-design.md](${CLAUDE_SKILL_DIR}/references/frontend-design.md) |
| **Component Generation** | See [references/component-generation.md](${CLAUDE_SKILL_DIR}/references/component-generation.md) |
| **Feedback Forms** | See [references/feedback-forms.md](${CLAUDE_SKILL_DIR}/references/feedback-forms.md) |

## Execution Steps

1. **Apply constraint set** (follow priority order)
2. **Quality gate** (Step 0)
3. Classify the user's request
4. Read the appropriate reference file from "Feature Details" above
5. Generate following its instructions

### Step 0: Quality Gate (Accessibility Checklist)

When generating UI components, ensure accessibility:

```markdown
♿ Accessibility Checklist

It is recommended that the generated UI meets the following:

### Required
- [ ] Set alt attributes on images
- [ ] Associate labels with form elements
- [ ] Keyboard operable (Tab to move focus)
- [ ] Focus state is visually apparent

### Recommended
- [ ] Information not conveyed by color alone
- [ ] Contrast ratio 4.5:1 or higher (text)
- [ ] Appropriate use of aria-label / aria-describedby
- [ ] Heading structure (h1 → h2 → h3) is logical

### Interactive Elements
- [ ] Buttons have appropriate labels (e.g., "View product details" not just "Details")
- [ ] Focus trap in modals/dialogs
- [ ] Error messages are read by screen readers
```

### For VibeCoder

```markdown
♿ Making designs usable by everyone

1. **Add descriptions to images**
   - "Red sneakers, front view" not just "Product image"

2. **Make clickable areas keyboard-accessible too**
   - Move with Tab key, confirm with Enter

3. **Don't rely on color alone**
   - Not just red=error; also use icon + text
```
