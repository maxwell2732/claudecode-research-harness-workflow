# Cleanup Reference

Detailed execution steps, thresholds, and archive destinations for each `/maintenance` subcommand.

## Common: Environment Variables (same SSOT as auto-cleanup-hook)

| Variable | Default | Source |
|----------|---------|--------|
| `PLANS_MAX_LINES` | 200 | `scripts/auto-cleanup-hook.sh` |
| `SESSION_LOG_MAX_LINES` | 500 | Same |
| `CLAUDE_MD_MAX_LINES` | 100 | Same |
| `ARCHIVE_AFTER_DAYS` | 7 | Age threshold for completed tasks in Plans.md |
| `LOGS_RETAIN_DAYS` | 30 | Retention period for `.claude/logs/` |

If the user specifies a different threshold in free text, that value takes priority.

---

## plans — Plans.md Archiving

### Prerequisites

1. If the `.claude/state/.ssot-synced-this-session` flag does not exist → Prompt to run `/memory sync`
2. Lines with `cc:WIP`, `pm:requested`, `cursor:requested` tags **must never be moved**

### Steps

```bash
PLANS="Plans.md"
cp "$PLANS" "$PLANS.bak.$(date +%s)"

# 1. Measure current state
wc -l "$PLANS"
grep -c '\[x\].*pm:confirmed\|cursor:confirmed' "$PLANS" || true

# 2. Extract lines completed more than 7 days ago (individually via Edit tool)
#    Targets: `- [x] ... (YYYY-MM-DD) ... pm:confirmed|cursor:confirmed`
#    Exceptions: Exclude lines containing cc:WIP / pm:requested / cursor:requested

# 3. Append extracted lines to the "## 📦 Archive" section
#    Create the section at the end if it doesn't exist
```

### Archive Section Format

```markdown
## 📦 Archive

### YYYY-MM (grouped by month)

- [x] Old task A (2026-04-05) pm:confirmed
- [x] Old task B (2026-04-07) cursor:confirmed
```

### Output When Nothing Is Detected

```
✅ Plans.md: 180 lines (limit 200). 6 completed tasks, 0 older than 7 days. No cleanup needed.
```

### Sample Report After Execution

```
✅ Plans.md cleanup complete
- Lines: 250 → 178 (-72)
- Archived: 9 items (2026-03 group)
- Backup: Plans.md.bak.1712900000
```

---

## session-log — Monthly Split of session-log.md

Target is `.claude/memory/session-log.md`. A split is recommended when it exceeds 500 lines.

### Steps

```bash
LOG=".claude/memory/session-log.md"
ARCHIVE_DIR=".claude/memory/archive/sessions"
mkdir -p "$ARCHIVE_DIR"

# 1. Entries are delimited by `## YYYY-MM-DD` headers
# 2. Keep the most recent 30 days; split older entries by month
#    Output: .claude/memory/archive/sessions/YYYY-MM.md (append)
# 3. Remove moved entries from the original file
```

### Split File Format

Add the following header to each `archive/sessions/YYYY-MM.md`:

```markdown
# Session Log — YYYY-MM

Moved from `.claude/memory/session-log.md` on or after N days.
Move date: YYYY-MM-DD
```

### Sample Report After Execution

```
✅ session-log.md split complete
- Lines: 620 → 180
- Split to: archive/sessions/2026-03.md (+230 lines), 2026-02.md (+210 lines)
```

---

## logs — Delete Old Files in `.claude/logs/`

### Steps

```bash
LOGS_DIR=".claude/logs"
[ -d "$LOGS_DIR" ] || exit 0

# List targets in dry-run
find "$LOGS_DIR" -type f -mtime +${LOGS_RETAIN_DAYS:-30} -print

# Execute
find "$LOGS_DIR" -type f -mtime +${LOGS_RETAIN_DAYS:-30} -delete
```

### Sample Report

```
✅ logs/ cleanup complete
- Deleted: 12 files (older than 30 days)
- Remaining: 34 files
```

---

## state — Trim agent-trace / harness-usage

`.claude/state/agent-trace.jsonl` and `.claude/state/harness-usage.json` are
append-only / growing JSON files that can reach tens of MB if left unchecked.

### Trim agent-trace.jsonl

```bash
TRACE=".claude/state/agent-trace.jsonl"
[ -f "$TRACE" ] || exit 0

# Keep only the last 1000 lines
tail -1000 "$TRACE" > "$TRACE.tmp" && mv "$TRACE.tmp" "$TRACE"
```

### Compress harness-usage.json

```bash
USAGE=".claude/state/harness-usage.json"
[ -f "$USAGE" ] || exit 0

# Delete entries older than 60 days (write the jq condition appropriately based on structure)
# Read the actual structure with Read before processing
```

### Sample Report

```
✅ state trim complete
- agent-trace.jsonl: 8421 lines → 1000 lines
- harness-usage.json: Entries before 2026-02 deleted
```

---

## all — Run Everything

Run in order: plans → session-log → logs → state. Stop and report to user if an error occurs midway.

### Execution Flow

1. SSOT sync check (required only when plans is included)
2. Run each subcommand sequentially
3. Display Before/After summary at the end

### Sample Report

```
✅ Full maintenance complete

| Target | Before | After | Change |
|--------|--------|-------|--------|
| Plans.md | 250 lines | 178 lines | -72 (9 archived) |
| session-log.md | 620 lines | 180 lines | -440 (2 files split) |
| logs/ | 46 files | 34 files | -12 (over 30 days) |
| agent-trace.jsonl | 8421 lines | 1000 lines | -7421 |

Backup: Plans.md.bak.1712900000
```

---

## Handling Common Additional Instructions

| Instruction | Action |
|------------|--------|
| "Delete old archives too" | Also delete entries in `.claude/memory/archive/` exceeding N days |
| "Dry-run" | Replace all deletions/moves with `echo`; list only what would be removed |
| "Keep this file" | Exclude the relevant file from the target list and proceed |
| "Raise threshold to 300 lines" | Temporarily override with env var like `PLANS_MAX_LINES=300` |

---

## Prohibited Actions

- ❌ Automatic editing of `.claude/memory/decisions.md` / `patterns.md` (direct SSOT modification is prohibited)
- ❌ Compressing or archiving `CHANGELOG.md` (history must not be deleted)
- ❌ Operations under `.git/`
- ❌ Deleting lines without a backup (always back up files over 200 lines)
