---
name: ui-skills-summary
description: "UI Skills constraint set summary (implementation quality first)"
---

# UI Skills Summary

A constraint set to prevent common UI implementation pitfalls.

## Stack
- MUST: Use Tailwind CSS default values (exception only for existing customizations or explicit requests)
- MUST: Use `motion/react` when JavaScript animation is needed
- SHOULD: Use `tw-animate-css` for Tailwind entry/minor animations
- MUST: Use `cn` (`clsx` + `tailwind-merge`) for class control

## Components
- MUST: Use accessible primitives for keyboard/focus behavior
- MUST: Prefer existing primitives
- NEVER: Mix primitives on the same interaction surface
- SHOULD: Prefer Base UI when compatible
- MUST: Add `aria-label` to icon-only buttons
- NEVER: Hand-implement keyboard/focus behavior (unless explicitly requested)

## Interaction
- MUST: Use AlertDialog for destructive operations
- SHOULD: Use structural skeletons for loading states
- NEVER: Use `h-screen`; use `h-dvh` instead
- MUST: Account for `safe-area-inset` for fixed elements
- MUST: Show errors near the relevant control
- NEVER: Block paste in input/textarea

## Animation
- NEVER: Do not add animations unless explicitly requested
- MUST: Animate only `transform` / `opacity`
- NEVER: Animate `width/height/top/left/margin/padding`
- SHOULD: Animate `background/color` only for small, localized UI
- SHOULD: Use `ease-out` for entrances
- NEVER: Feedback must not exceed 200ms
- MUST: Stop loops when off-screen
- SHOULD: Respect `prefers-reduced-motion`
- NEVER: Custom easing is prohibited unless explicitly requested
- SHOULD: Avoid animation on large images / full-bleed areas

## Typography
- MUST: Use `text-balance` for headings
- MUST: Use `text-pretty` for body text
- MUST: Use `tabular-nums` for numbers
- SHOULD: Use `truncate` or `line-clamp` for dense UI
- NEVER: Do not arbitrarily change `tracking-*`

## Layout
- MUST: Use a fixed `z-index` scale (avoid arbitrary `z-*`)
- SHOULD: Use `size-*` for squares

## Performance
- NEVER: Do not animate large `blur()` / `backdrop-filter`
- NEVER: Do not constantly apply `will-change`
- NEVER: Write logic in `useEffect` that could be written at render time

## Design
- NEVER: No gradients unless explicitly requested
- NEVER: No purple/multi-color gradients
- NEVER: Do not use glow for primary affordances
- SHOULD: Use Tailwind's default shadow scale
- MUST: Provide one "next action" for empty states
- SHOULD: Limit to one accent color
- SHOULD: Prefer existing theme/tokens over new colors

## Sources
- https://www.ui-skills.com/
- https://agent-skills.xyz/skills/baptistearno-typebot-io-ui-skills
