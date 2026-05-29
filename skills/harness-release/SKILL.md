---
name: harness-release
description: "Generic release automation for projects using Keep a Changelog + GitHub. Single confirmation gate then end-to-end automation: bump detection, CHANGELOG promotion, PR/main merge, tag, GitHub Release. Trigger: release, version bump, publish. Do NOT load for: implementation, review, planning, setup."
description-en: "Generic release automation for projects using Keep a Changelog + GitHub. Single confirmation gate then end-to-end automation: bump detection, CHANGELOG promotion, PR/main merge, tag, GitHub Release. Trigger: release, version bump, publish. Do NOT load for: implementation, review, planning, setup."
description-ja: "汎用リリース自動化スキル。Keep a Changelog と GitHub を使うあらゆるプロジェクトで動作。単一確認ゲートで bump 判定・CHANGELOG 昇格・PR/main 反映・タグ・GitHub Release まで全自動実行する。リリース、バージョンバンプ、タグ作成、公開で起動。実装・コードレビュー・プランニング・セットアップには使わない。"
kind: workflow
purpose: "Release projects through changelog, version, PR/main merge, tag, and GitHub Release gates"
trigger: "release, version bump, publish"
shape: workflow
role: orchestrator
pair: harness-review
owner: harness-core
since: "2026-05-05"
allowed-tools: ["Read", "Write", "Edit", "Bash", "AskUserQuestion", "Skill"]
argument-hint: "[patch|minor|major|--dry-run]"
context: fork
effort: high
user-invocable: true
---

# Harness Release (Generic)

Generic release automation skill for **any project** using Keep a Changelog + GitHub.

**Design principle**: Single confirmation gate. The user sees and approves the full plan once. After approval, execution continues uninterrupted: file rewrite → commit → branch push → PR create/update → merge to default branch → tag on default branch → GitHub Release.

**Definition of release complete**: A release is not complete just by "creating a tag and GitHub Release." Complete means: the target work and release bump are merged into the default branch (usually `main`), the release tag points to a commit reachable from the default branch, and the GitHub Release is published against that tag.

> **Literal invocation note**: The entry point for this skill uses literal commands as-is: `harness-release`, `/release`, `/release patch`, `/release --dry-run`.

## Bare invocation contract

if $ARGUMENTS == "":
  → Interpret as "commit work done so far and complete through PR/main merge before releasing," and run Review Gate detection
  → Auto-proceed to Step 0 (Review Gate) only when exactly one target work can be determined
  → When target is unclear or no review state exists, present options with AskUserQuestion before proceeding

Always output the following literal marker in the first response on bare invocation:

`RELEASE_AUTOSTART: target=<work-summary>, base_ref=<ref>, mode=<patch|minor|major|auto>`

Prohibited responses: "Task is unclear," "Waiting for instructions," "No tasks," "Waiting for additional instructions."

<!-- Above block is AUTO-START CONTRACT. Compliant with skill-editing.md "within first 3 lines" rule. patterns.md P27 solution triple (machine-readable condition + prohibited action literal + AUTOSTART marker) -->

### Output Contract (P35: "appears stuck" UX countermeasure)

The **last line** of skill output must always include this literal:

`↑Claude will summarize this result. Press Enter to continue, or enter a new prompt for a different instruction.`

This is an explicit instruction for the UX problem where text displayed via `<local-command-stdout>` makes users feel it has "stopped" (patterns.md P35).

`harness-release` / `/release` alone means **"commit work done so far and release through PR/main merge."**
The older phrasing **"commit work done so far and release"** has the same intent, but the completion condition must always include PR/main merge.
Do not stop with "No tasks" or "Waiting for instructions."

On bare release, run the **Review Gate** and **Work Commit Gate** before the normal release preflight.

1. Check `git status --porcelain` and `git log @{upstream}..HEAD` / `main..HEAD` to identify the target "work done so far"
2. Check `.claude/state/review-result.json` and `.claude/state/review-approved.json` to verify whether the target work has an `APPROVE`d review
3. When no APPROVEd review exists, confirm with `AskUserQuestion`
4. When user selects "Start from review," launch `harness-review` and do not proceed to release until `APPROVE` is returned
5. When `harness-review` returns `REQUEST_CHANGES`, hold the release, fix with `harness-work`, then re-run `harness-review`. Loop until `APPROVE`.
6. After `harness-review` returns `APPROVE`, create a work commit for the working tree
7. After the working tree is clean, proceed to normal release preflight / confirmation gate / PR merge / tag / GitHub Release

### Review Gate AskUserQuestion

When running `harness-release` and review approval cannot be confirmed, do not release by guessing.
Present the following Ask:

```text
question: "harness-release will commit work done so far and release, but no APPROVE review was found for this work. How would you like to proceed?"
options:
  - label: "Start from review (Recommended)"
    description: "Run harness-review and proceed to commit/release only if APPROVE is returned."
  - label: "release dry-run"
    description: "No file changes; check only the release plan and missing gates."
  - label: "Cancel"
    description: "Stop without review or release."
```

When user selects "Start from review," start `harness-review` in the same session.
Target determination in `harness-review` follows `harness-review`'s own bare review contract.
If review is `APPROVE`, return to the `harness-release` Work Commit Gate.
If review is `REQUEST_CHANGES`, hold release, fix with `harness-work`, then re-run `harness-review`.
This post-fix re-review loop continues until `APPROVE`.

Only return to the user in these cases:

1. Fix requires decisions about spec source of truth / Plans.md / API / permission / migration / billing etc., and `AskUserQuestion` is needed
2. Multiple fix approaches exist where choice affects user value or compatibility
3. User selected `release dry-run` or `Cancel` in Ask

Do not use `REQUEST_CHANGES` alone as a final stop reason.

### Work Commit Gate

On bare release, when there are uncommitted changes in the working tree, create a reviewed work commit separately from the release version bump commit first.

```bash
git status --short
git diff --stat
git add <reviewed files>
git commit -m "<type>: <summary>"
```

Generate commit message briefly from review summary / Plans.md task / branch name.
When unclear, present 2-3 commit message candidates with `AskUserQuestion`.
After creating the work commit, verify or update `commit_hash` in `.claude/state/review-result.json`, then proceed to release preflight.

After entering normal release preflight, treat dirty working tree as failure as before.
Do not proceed to version bump / tag / GitHub Release with a dirty tree.

## Quick Reference

```bash
/release              # Review gate → commit → PR/main merge → release work done so far
/release patch        # Explicitly specify bump as patch
/release minor        # Explicitly specify bump as minor
/release major        # Explicitly specify bump as major
/release --dry-run    # Display plan only, do not execute
```

## Prerequisites

Projects where this skill operates must satisfy:

1. `CHANGELOG.md` in [Keep a Changelog](https://keepachangelog.com/) format
2. `[Unreleased]` section exists
3. Has one of the following version files:
   - `VERSION` (standalone file)
   - `package.json` (npm)
   - `pyproject.toml` (Python, `[project]` or `[tool.poetry]`)
   - `Cargo.toml` (Rust, `[package]`)
4. `gh` CLI installed and authenticated
5. Git remote `origin` points to GitHub
6. For Claude Code plugin projects: `claude` CLI supports `plugin tag`

When these are not met, Preflight detects and aborts.

`prUrlTemplate` multi-host review URL is recognized as a future candidate, but this skill's release automation still uses `gh` CLI and GitHub remote as the primary path. Auto-retrieval of owner / branch / release asset / CI metadata has large host-by-host differences, so Phase 56.2.3 remains docs-only.

## Single gate flow

```
[Bare release only: work review/commit pre-step]
  ↓
  0. Review Gate (AskUserQuestion → harness-review if no review)
  0.5 Work Commit Gate (commit review-APPROVEd work separately from release bump)
  ↓
[Pre-Gate: information collection only, no file changes]
  ↓
  1. Preflight (working tree clean / CHANGELOG / gh etc. checks)
  2. Version file auto-detection
  3. Read current version
  4. Claude plugin tag preflight (plugin projects only)
  5. Parse [Unreleased] content → estimate bump level
  6. Calculate new version
  7. Create CHANGELOG diff draft (in memory)
  8. Create GitHub Release notes draft (in memory)

★━━━━━━ Single Confirmation Gate ━━━━━━★
  Present full plan to user once:
    - Detected version file
    - Current version → new version
    - Bump determination reason (e.g., "minor because ### Added is in [Unreleased]")
    - CHANGELOG change preview
    - GitHub Release notes draft
    - Files to commit
    - Final actions (branch push + PR merge + tag + release publish)

  User response:
    "yes"              → Proceed to Post-Gate
    "<fix instruction>" → Regenerate draft per instruction, re-confirm
    "cancel/no"        → Do nothing and exit
★━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━★
  ↓
[Post-Gate: after approval, no interruption]

  9. Rewrite version file
  10. Rewrite CHANGELOG.md ([Unreleased] → [X.Y.Z] promotion + compare link)
  11. git add + commit
  12. Release branch push
  13. PR create/update
  14. Merge to default branch
  15. Fetch/checkout default branch; verify release commit is reachable
  16. Claude plugin tag validation + tag (plugin projects only)
  17. GitHub Release semver tag (only for projects that need it)
  18. git push origin <default-branch> --tags
  19. gh release create vX.Y.Z
  20. Completion report
```

## Pre-Gate details

### 1. Preflight

```bash
# Required tools
command -v gh >/dev/null || { echo "gh CLI not found"; exit 1; }
command -v python3 >/dev/null || { echo "python3 required"; exit 1; }

# Working tree
if [ -n "$(git status --porcelain)" ]; then
  echo "Uncommitted changes in working tree"; exit 1;
fi

# CHANGELOG
[ -f CHANGELOG.md ] || { echo "CHANGELOG.md not found"; exit 1; }
grep -q "^## \[Unreleased\]" CHANGELOG.md || { echo "[Unreleased] section not found"; exit 1; }

# plugin/mirror projects
scripts/release-preflight.sh
```

This working tree clean check is the gate for normal release preflight.
When wanting to commit "work done so far" on bare release, complete the Review Gate and Work Commit Gate before this check.
Do not abort and finish just because of an unreviewed dirty tree at this check.

`scripts/release-preflight.sh` also detects mirror drift in `opencode/`, `skills-codex/`, `codex/.codex/skills/` before tag creation. When `node scripts/build-opencode.js` generates a diff, stop the release, commit that diff, then proceed to tag.

### 2. Version file auto-detection

Search in this priority order; use the first found as authoritative:

```python
import os, json, re
import tomllib  # Python 3.11+

def detect_version_file():
    if os.path.exists("VERSION"):
        with open("VERSION") as f:
            return ("VERSION", f.read().strip(), None)
    if os.path.exists("package.json"):
        with open("package.json") as f:
            data = json.load(f)
        return ("package.json", data["version"], None)
    if os.path.exists("pyproject.toml"):
        with open("pyproject.toml", "rb") as f:
            data = tomllib.load(f)
        if "project" in data:
            return ("pyproject.toml", data["project"]["version"], "[project]")
        if "tool" in data and "poetry" in data["tool"]:
            return ("pyproject.toml", data["tool"]["poetry"]["version"], "[tool.poetry]")
    if os.path.exists("Cargo.toml"):
        with open("Cargo.toml", "rb") as f:
            data = tomllib.load(f)
        return ("Cargo.toml", data["package"]["version"], "[package]")
    raise RuntimeError("No supported version file found")
```

Details: [version-files.md](${CLAUDE_SKILL_DIR}/references/version-files.md)

### 3. Claude Plugin Tag Preflight

For projects with `.claude-plugin/plugin.json`, create a Claude plugin release tag separately from the normal GitHub Release tag.

In short: before assembling `git tag -a` manually, pass Claude Code's own plugin validation and then create the `{plugin-name}--v{version}` tag.

Pre-Gate does not rewrite files; verify the following. Read version sync with structured parser, not `grep`/`sed`:

```bash
command -v claude >/dev/null || { echo "claude CLI not found"; exit 1; }
claude plugin validate .claude-plugin/plugin.json

HARNESS_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
python3 "${HARNESS_PLUGIN_ROOT}/scripts/check-release-version-sync.py" --root .

claude plugin tag .claude-plugin --dry-run
```

`${HARNESS_PLUGIN_ROOT}/scripts/check-release-version-sync.py` reads all existing release surfaces and determines canonical in the order `VERSION > package.json > .claude-plugin/plugin.json > .codex-plugin/plugin.json`.
Then it does not proceed to tag/release if any of the following have mismatches or are missing:

- `VERSION`
- `package.json` `.version`
- `.claude-plugin/plugin.json` `.version`
- `.codex-plugin/plugin.json` `.version`
- `.claude-plugin/marketplace.json` `.metadata.version`
- `.claude-plugin/marketplace.json` `.plugins[].version` (each plugin entry in the array)

On mismatch, show which surface differs from canonical or which field is missing/invalid.
Use `--json` for machine processing or CI:

```bash
python3 "${HARNESS_PLUGIN_ROOT}/scripts/check-release-version-sync.py" --root . --json
```

This check prevents 3 accidents:

- Cutting a tag with `VERSION` and `.claude-plugin/plugin.json` version out of sync
- Proceeding to release workflow with stale `package.json` / marketplace entry version
- Getting stuck on plugin install/update side after skipping plugin manifest/marketplace entry validation

`--dry-run` shows the tag name `claude plugin tag` would create and the internal `git tag -a` / push equivalent command. Include the command shown here in the Confirmation Gate plan.

### 4. Bump auto-estimation

Parse headings directly under `[Unreleased]` to determine bump level:

| Headings in [Unreleased] | Estimated bump |
|--------------------------|---------------|
| Contains `### Breaking Changes` or `### Removed` | **major** |
| Contains `### Added` (no Removed/Breaking) | **minor** |
| Only `### Fixed` / `### Changed` / `### Security` | **patch** |
| Empty section | **error: no release target** |

When user explicitly specifies `/release patch|minor|major`, that takes priority.
Details: [bump-detection.md](${CLAUDE_SKILL_DIR}/references/bump-detection.md)

### 5. CHANGELOG draft creation (in memory)

Calculate the following; do not write yet:

1. Cut out body of `## [Unreleased]`
2. Create the form with `## [<new>] - YYYY-MM-DD` inserted between `## [Unreleased]` and `## [<previous>]`
3. Trailing compare link:
   - `[Unreleased]: .../compare/v<prev>...HEAD` → `v<new>...HEAD`
   - Add `[<new>]: .../compare/v<prev>...v<new>`
4. Dynamically extract repo URL from existing `[Unreleased]: ` line

### 6. Release notes draft creation (in memory)

Generate GitHub Release markdown from the `## [<new>]` section content:

```markdown
## What's Changed

**<release theme (1 line)>**

### Before / After
<table>

### Added / Changed / Fixed / Removed
<copy applicable sections>

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Details: [release-notes.md](${CLAUDE_SKILL_DIR}/references/release-notes.md)

## Confirmation Gate

When all drafts are ready, present to user once:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Release Plan: v<old> → v<new> (<bump>)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Version file: <detected file>
 Bump reason:  <why this level was chosen>

 CHANGELOG changes:
   <N> changes detected in [Unreleased]
   Confirmed as [<new>] - YYYY-MM-DD
   Compare link added

 GitHub Release notes preview:
   <first 10 lines>
   ...

 Files to modify:
   - <version file>
   - CHANGELOG.md

 Final actions:
   - git commit -m "chore: release v<new>"
   - git push origin <release-branch>
   - gh pr create/update + gh pr merge into <default-branch>
   - git fetch origin <default-branch> && git checkout <default-branch>
   - claude plugin tag .claude-plugin --push --remote origin  # plugin projects only; run on default branch
   - git tag -a v<new>                                        # GitHub Release semver tag if needed; create on default branch
   - git push origin <default-branch> --tags
   - gh release create v<new>

Proceed? [yes / cancel / <fix instruction>]
```

## Post-Gate details

Execute without interruption after approval. On failure, follow this policy:

| Failure point | Recovery |
|---------------|---------|
| File rewrite failure | Abort there; local is left dirty for human judgment |
| Commit failure | Hook rejection etc. Present cause to user and prompt for fix |
| PR create/merge failure | Stop as incomplete release; do not proceed to tag/GitHub Release |
| Plugin tag validation failure | Fix `VERSION` / `.claude-plugin/plugin.json` / marketplace entry mismatch; do not proceed to tag creation |
| Push failure | Remote-side issue. Local commit/tag remains. |
| `gh release create` failure | Tag is already pushed; existing release.yml safety net may fire, or run `gh release create` manually |

### PR / Main Merge Gate

After the release commit in Post-Gate, merge the GitHub PR to the default branch before creating the tag.

```bash
release_branch="$(git branch --show-current)"
default_branch="${HARNESS_RELEASE_DEFAULT_BRANCH:-main}"

git push -u origin "$release_branch"
gh pr create --base "$default_branch" --head "$release_branch" --title "chore: release v<new>" --body "<release summary>"
gh pr merge --merge --delete-branch=false

git fetch origin "$default_branch" --tags
git checkout "$default_branch"
git pull --ff-only origin "$default_branch"
git merge-base --is-ancestor "<release-commit>" "origin/$default_branch"
```

When an existing PR exists, update its body and merge without creating a new one. When repository policy requires squash merge, verify that release bump content (version files + CHANGELOG + source commits) is included in the default branch — not just the release commit hash.

Create the tag after this Gate is complete, against HEAD of the default branch or a commit reachable from the release commit. Do not create a GitHub Release with a tag pointing to a commit that exists only on the release branch.

### Claude plugin project tag creation

For projects with `.claude-plugin/plugin.json`, verify version sync on the default branch once more after PR/main merge, then create the plugin tag:

```bash
HARNESS_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
python3 "${HARNESS_PLUGIN_ROOT}/scripts/check-release-version-sync.py" --root .

claude plugin tag .claude-plugin --dry-run
claude plugin tag .claude-plugin --push --remote origin
```

The tag `claude plugin tag` creates is in `{plugin-name}--v{version}` format. For projects where existing GitHub Release workflows assume a `vX.Y.Z` tag, also create `git tag -a v<new>` separately from the plugin tag. Let `claude plugin tag` handle distribution tags; treat the GitHub Release semver tag as a compatible release automation surface.

## `--dry-run` mode

Run all Pre-Gate steps and display content through Confirmation Gate, but **stop at the gate without proceeding to Post-Gate**.

For Claude plugin projects, even in dry-run, execute `python3 "${HARNESS_PLUGIN_ROOT}/scripts/check-release-version-sync.py" --root .` and `claude plugin tag .claude-plugin --dry-run` to show the actual plugin tag name to be created and push targets. If any version surfaces in `VERSION` / `package.json` / `.claude-plugin/plugin.json` / `.codex-plugin/plugin.json` / `.claude-plugin/marketplace.json` are mismatched or missing, stop at dry-run time.

## Environment variables

For per-project adjustments:

| Variable | Description |
|----------|-------------|
| `HARNESS_RELEASE_PROJECT_ROOT` | Repository root (default: `$(pwd)`) |
| `HARNESS_RELEASE_BRANCH` | Branch to push (default: current branch) |
| `HARNESS_RELEASE_DEFAULT_BRANCH` | Default branch for PR merge target (default: `main`) |
| `HARNESS_RELEASE_HEALTHCHECK_CMD` | Additional command to run in Preflight |
| `HARNESS_RELEASE_SKIP_GH` | `1` skips GitHub Release creation |

## CHANGELOG writing rules

The `[Unreleased]` section must always have one of these subsections:

```markdown
## [Unreleased]

### Added       ← minor
### Changed     ← patch
### Deprecated  ← minor
### Removed     ← major
### Fixed       ← patch
### Security    ← patch
### Breaking Changes  ← major (non-standard in KaCL but common)
```

This skill parses these headings mechanically, so heading variations (`### Fix` / `### Bug Fixes` etc.) cannot be recognized. Use standard KaCL headings.

## Related skills

- `harness-release-internal` - Harness-specific preflight/finalization run additionally for claude-code-harness itself (not distributed)
- `harness-plan` - Plans.md management
- `harness-review` - Code review before release

## Design philosophy

- **Single gate**: User makes one judgment per release. Multiple mini-confirmations become rubber-stamps and lose meaning.
- **Draft everything upfront**: No "reconsideration" after entering Post-Gate. Assemble all drafts before the gate.
- **Main merge is the completion condition**: Release tag / GitHub Release only created after default branch merge. Branch-only releases are treated as incomplete.
- **Failures are transparent**: On mid-execution failure, do not attempt auto-rollback; present the current state to the user for judgment.
- **Project-independent**: No assumptions about VERSION file format, mirrors, residue checks etc. specific to certain environments. Harness-specific processing for the main harness is separated into `harness-release-internal`.
