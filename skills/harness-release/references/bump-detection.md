# Bump Level Detection

Logic for estimating the bump level (patch/minor/major) from the contents of the `[Unreleased]` section.

## Determination rules

Scan all `### <category>` headings directly under `[Unreleased]` and determine in the following priority order:

```
1. Contains "### Breaking Changes"             → major
2. Contains "### Removed"                      → major
3. Contains "### Added" (without above)        → minor
4. Contains "### Deprecated" (without above)   → minor
5. Only "### Fixed" / "### Changed" / "### Security" → patch
6. No subsections (empty)                      → error
```

## Implementation

```python
import re

def detect_bump(changelog_text: str) -> str:
    """Return 'major' | 'minor' | 'patch'. Raises on empty [Unreleased]."""
    # Extract the [Unreleased] section
    m = re.search(
        r"## \[Unreleased\]\s*\n(.*?)(?=\n## \[|\Z)",
        changelog_text,
        re.S,
    )
    if not m:
        raise RuntimeError("[Unreleased] section not found")
    body = m.group(1).strip()
    if not body:
        raise RuntimeError("[Unreleased] is empty. No release candidates.")

    # Collect headings
    headings = set(re.findall(r"^### (.+?)\s*$", body, re.M))

    if "Breaking Changes" in headings or "Removed" in headings:
        return "major"
    if "Added" in headings or "Deprecated" in headings:
        return "minor"
    if headings & {"Fixed", "Changed", "Security"}:
        return "patch"
    raise RuntimeError(f"No recognizable subsections found in [Unreleased]: {headings}")
```

## Why is Deprecated classified as minor?

Per the Keep a Changelog specification, Deprecated is "an announcement that something will be Removed in the future."
It has the same user impact as a feature addition/change, so it is treated as minor.
The actual bump to major happens when Removed occurs.

## User override

When `/release patch|minor|major` is explicitly specified, skip this automatic determination and use the specified value.
However, **even when overridden, abort if the bump target section is empty** (since there is no release content).

## Heading variations are not supported

The following are not recognized:

| Commonly written variation | Correct heading |
|-----------------|-----------|
| `### Features` | `### Added` |
| `### Bug Fixes` / `### Fix` | `### Fixed` |
| `### BREAKING CHANGE` / `### Breaking` | `### Breaking Changes` |
| `### Enhancements` | `### Changed` or `### Added` |

Align headings to KaCL standards before calling `/release`.
If unrecognized headings are detected before the gate, show a warning and prompt the user to fix them.

## Handling pre-release / build metadata

When the current version has a pre-release suffix such as `1.0.0-alpha.1`, this skill:

1. Calculates bump while ignoring the suffix (`1.0.0-alpha.1` → patch → `1.0.1`)
2. Discards the suffix (does not produce `1.0.1-alpha.1`)

The behavior does not change even if you specify a bump override when you want to bump with the pre-release intact.
Projects that intentionally want to continue pre-release are not supported by this skill.

## Handling an empty [Unreleased]

When `/release` is called with an empty [Unreleased], suggest the following:

- "No release candidates. Please add `### Fixed`, etc., to `[Unreleased]`, or if you want a maintenance release with only markers, consider the `--empty` flag."

The `--empty` flag is not supported by this skill (empty releases are not created in principle).
