# sync subcommand — Progress Sync Flow

Cross-reference implementation status with Plans.md, detect differences, and update.

## Step 0: Plans.md validation

Check Plans.md existence and format. If there is a problem, immediately provide guidance and stop.

| State | Guidance |
|------|------|
| Plans.md does not exist | `Plans.md not found. Create it with /harness-plan create.` → **stop** |
| Header lacks DoD / Depends columns (v1 format) | `Plans.md is in old format (3 columns). Please regenerate in v2 (5 columns) with /harness-plan create. Existing tasks will be automatically carried over.` → **stop** |
| v2 format (5 columns) | Proceed to Step 1 as-is |

## Step 1: Collect current state (parallel)

```bash
# Plans.md state
cat Plans.md

# Git change state
git status
git diff --stat HEAD~3

# Recent commit history
git log --oneline -10

# Agent trace (recently edited files)
tail -20 .claude/state/agent-trace.jsonl 2>/dev/null | jq -r '.files[].path' | sort -u
```

## Step 1.5: Agent Trace analysis

Get recent edit history from Agent Trace and cross-reference with Plans.md tasks:

```bash
# List of recently edited files
RECENT_FILES=$(tail -20 .claude/state/agent-trace.jsonl 2>/dev/null | \
  jq -r '.files[].path' | sort -u)

# Project information
PROJECT=$(tail -1 .claude/state/agent-trace.jsonl 2>/dev/null | \
  jq -r '.metadata.project')
```

**Cross-reference points**:

| Check item | Detection method |
|------------|----------|
| File edits not in Plans.md | Agent Trace vs task description |
| Files different from task description | Expected files vs actual edits |
| Tasks with no long-term edits | Agent Trace timeline vs WIP duration |

## Step 2: Diff detection

| Check item | Detection method |
|------------|----------|
| `cc:WIP` even though already complete | Commit history vs marker |
| `cc:TODO` even though already started | Changed files vs marker |
| Uncommitted even though `cc:done` | git status vs marker |

### Artifact Hash backward compatibility

Recognize both `cc:done [a1b2c3d]` format (with commit hash) and `cc:done` (without hash).

**Matching rules**:
- `cc:done` → treat as hash-less completion
- `cc:done [xxxxxxx]` → treat as hash-attached completion. Retain 7-character abbreviated hash
- When hash is attached, can verify commit existence by cross-referencing with `git log --oneline`

> **Backward compatibility**: hash-less format also remains valid. Does not break existing Plans.md.

## Step 3: Plans.md update proposal

When differences are detected, propose and execute:

```
Plans.md update needed

| Task | Current | After change | Reason |
|------|------|--------|------|
| XX   | cc:WIP | cc:done | Already committed |
| YY   | cc:TODO | cc:WIP | File already edited |

Update? (yes / no)
```

## Step 4: Progress summary output

```markdown
## Progress Summary

**Project**: {{project_name}}

| Status | Count |
|----------|------|
| Not started (cc:TODO) | {{count}} |
| In progress (cc:WIP) | {{count}} |
| Complete (cc:done) | {{count}} |
| PM confirmed (pm:confirmed) | {{count}} |

**Progress rate**: {{percent}}%

### Recently edited files (Agent Trace)
- {{file1}}
- {{file2}}
```

## Step 5: Next action proposal

```
Next steps

**Priority 1**: {{task}}
- Reason: {{requested / waiting to unblock}}

**Recommended**: harness-work, harness-review
```

## Anomaly detection

| Situation | Warning |
|------|------|
| Multiple `cc:WIP` | Multiple tasks in progress simultaneously |
| `pm:requested` unprocessed | Process PM request first |
| Large discrepancy | Task management is falling behind |
| WIP not updated for 3+ days | Check if blocked |

## Step 6: Retrospective (default ON)

When `sync` is executed, automatically run a retrospective if there is at least 1 `cc:done` task.
Can be explicitly skipped with `--no-retro`.

### Step R1: Collect completed tasks

```bash
# Extract cc:done / pm:confirmed tasks from Plans.md
grep -E 'cc:done|pm:confirmed' Plans.md

# Recent completion commit history
git log --oneline --since="7 days ago"

# Change scale
git diff --stat HEAD~10
```

### Step R2: Retrospective 4 items

| Item | Analysis method |
|------|---------|
| **Estimate accuracy** | Infer expected file count from Plans.md task description → compare with actual changed file count from `git diff --stat` |
| **Block causes** | Aggregate reason patterns for tasks with `blocked` marker (technical / external dependency / unclear specs) |
| **Quality marker accuracy** | Did tasks marked `[feature:security]`, etc., actually result in related issues? |
| **Scope fluctuation** | Task count at first commit of Plans.md vs current task count (number added/deleted) |

### Step R3: Retrospective summary output

```markdown
## Retrospective Summary

**Period**: {{start_date}} to {{end_date}}

| Metric | Value |
|------|-----|
| Completed tasks | {{count}} |
| Blocks occurred | {{blocked_count}} |
| Scope fluctuation | +{{added}} / -{{removed}} |
| Estimate accuracy | Expected {{est}} files → actual {{actual}} files |

### Learnings
- {{1-2 lines of learnings}}

### What to apply next
- {{1-2 lines of improvement actions}}
```

### Step R4: Record to harness-mem

Record retrospective results to harness-mem for reference during the next `create`.
Storage location: corresponding agent memory under `.claude/agent-memory/`.
