# Release Notes Format

Rules for converting the `## [X.Y.Z]` section of a CHANGELOG into GitHub Release notes.

## Language

- **GitHub Release notes: English** (standard for public repositories)
- **CHANGELOG.md: Japanese** (when the project's primary language is Japanese)

When CHANGELOG is written in Japanese, English translation is needed when creating a GitHub Release.
The skill calls Claude to generate a draft and has the user confirm it at the Confirmation Gate.

## Required elements

```markdown
## What's Changed

**<1-line value summary>**

### Before / After

| Before | After |
|--------|-------|
| <previous UX> | <new UX> |

---

### Added
- <item>

### Changed
- <item>

### Fixed
- <item>

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## How to generate elements

### "What's Changed" summary

Extract from the `### Theme` line in the CHANGELOG `[X.Y.Z]` section.
If absent, summarize in one sentence from the first item in Added/Changed/Fixed.

### Before / After table

Extract from "before / after" descriptions in CHANGELOG.
If absent, infer from:
- Fixed items → `<bug description>` vs `Fixed`
- Added items → `<feature> was not available` vs `Now available`
- Changed items → `<old behavior>` vs `<new behavior>`

### Added / Changed / Fixed

Translate and transfer the relevant sections from CHANGELOG directly.

### Footer

Fixed: `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

## GitHub Release creation command

```bash
gh release create "v$NEW_VERSION" \
  --title "v$NEW_VERSION - <1-line summary>" \
  --notes "$(cat <<'EOF'
<release notes body>
EOF
)"
```

## Draft confirmation

Present the following at the Confirmation Gate:

```
GitHub Release Preview:
━━━━━━━━━━━━━━━━━━━━━━
Title: v4.0.4 - Fix CI validation gap
Body (first 20 lines):

  ## What's Changed

  **Fixed a gap in validate-plugin.sh ...**
  ...

(Full body: 45 lines)
━━━━━━━━━━━━━━━━━━━━━━
```

If the user says "fix: ...", regenerate.

## Validation

Before `gh release create`, check that Release Notes satisfy the following:

1. `## What's Changed` section exists
2. **Bold summary** line exists
3. `### Before / After` table exists
4. Footer `Generated with [Claude Code]` exists

If not satisfied, return to Gate and prompt for correction.

## How to handle multiple changes

When the CHANGELOG `[X.Y.Z]` contains 2 or more features:

- Title: represent with the most important one (or "Multiple fixes and improvements")
- Body: divide each feature with `### N. <feature name>` and translate

Releasing multiple versions on the same day is not recommended (versioning.md). Batch release them.
