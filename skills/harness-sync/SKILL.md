---
name: harness-sync
description: "HAR: Sync Plans.md with implementation. Drift detect, marker update, retrospective. Trigger: sync-status, where am I, check progress. --snapshot for snapshots. Do NOT load for: planning, implementation, review, release."
description-en: "HAR: Sync Plans.md with implementation. Drift detect, marker update, retrospective. Trigger: sync-status, where am I, check progress. --snapshot for snapshots. Do NOT load for: planning, implementation, review, release."
description-ja: "HAR:Plans.md と実装の進捗同期。差分検出・マーカー更新・レトロスペクティブ。sync-status、進捗確認、今どこ、どこまで終わったで起動。--snapshot でスナップショット保存。プランニング・実装・レビュー・リリースには使わない。"
kind: workflow
purpose: "Reconcile Plans.md, git, and implementation state"
trigger: "sync-status, where am I, check progress"
shape: workflow
role: synchronizer
pair: harness-plan
owner: harness-core
since: "2026-05-05"
allowed-tools: ["Read", "Edit", "Bash", "Grep", "Glob"]
argument-hint: "[--snapshot|--no-retro]"
user-invocable: true
effort: medium
---

# Harness Sync

Reconciles Plans.md against implementation status and detects/updates drift.
Standalone version of legacy `sync-status` and the `harness-plan sync` subcommand.

## Quick Reference

| User input | Action |
|------------|--------|
| `harness-sync` | Progress sync + retrospective (default ON) |
| `harness-sync --no-retro` | Progress sync only (skip retrospective) |
| `harness-sync --snapshot` | Save snapshot (point-in-time progress record) |
| `harness-sync --plan roadmap` | Sync the `roadmap` named plan |
| "Where am I?" / "Check progress" | Same as above |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--snapshot` | Save current progress as a snapshot | false |
| `--no-retro` | Skip retrospective | false (runs by default) |
| `--plan NAME` | Use a named plan from `plans/manifest.json` | active/default |

## Step 0: Plans.md validation

Verify Plans.md exists and is properly formatted. If issues are found, guide and stop immediately.
In repos with multiple Plans.md files, confirm the target plan with `scripts/plan-registry.sh list` or `--plan NAME` before reading.

| State | Guidance |
|-------|---------|
| Plans.md does not exist | `Plans.md not found. Create it with harness-plan create.` → **Stop** |
| Header missing DoD / Depends columns (v1 format) | `Plans.md is in old format (3 columns). Regenerate to v2 (5 columns) with harness-plan create. Existing tasks will be carried over automatically.` → **Stop** |
| v2 format (5 columns) | Proceed to Step 1 |

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

## Step 1.5: Agent trace analysis

Retrieve recent edit history from Agent Trace and reconcile with Plans.md tasks:

```bash
# List of recently edited files
RECENT_FILES=$(tail -20 .claude/state/agent-trace.jsonl 2>/dev/null | \
  jq -r '.files[].path' | sort -u)

# Project information
PROJECT=$(tail -1 .claude/state/agent-trace.jsonl 2>/dev/null | \
  jq -r '.metadata.project')
```

**Reconciliation points**:

| Check item | Detection method |
|------------|-----------------|
| File edits not in Plans.md | Agent Trace vs task descriptions |
| Files different from task description | Expected files vs actual edits |
| Tasks with no edits for a long time | Agent Trace timeline vs WIP duration |

## Step 2: Drift detection

| Check item | Detection method |
|------------|-----------------|
| `cc:WIP` despite being done | Commit history vs marker |
| `cc:TODO` despite being started | Changed files vs marker |
| `cc:done` but not committed | git status vs marker |

## Step 3: Plans.md update proposal

When drift is detected, propose and execute:

```
Plans.md update needed

| Task | Current | Change to | Reason |
|------|---------|-----------|--------|
| XX   | cc:WIP | cc:done | Already committed |
| YY   | cc:TODO | cc:WIP | File already edited |

Update? (yes / no)
```

## Step 4: Progress summary output

```markdown
## Progress Summary

**Project**: {{project_name}}

| Status | Count |
|--------|-------|
| Not started (cc:TODO) | {{count}} |
| In progress (cc:WIP) | {{count}} |
| Done (cc:done) | {{count}} |
| PM confirmed (pm:approved) | {{count}} |

**Progress rate**: {{percent}}%

### Recently edited files (Agent Trace)
- {{file1}}
- {{file2}}
```

## Step 4.5: Save snapshot (when `--snapshot` is specified)

When `--snapshot` is specified, save the current progress state as a timestamped snapshot.

### Save location

Save in JSON format to the `.claude/state/snapshots/` directory:

```bash
SNAPSHOT_DIR="${PROJECT_ROOT}/.claude/state/snapshots"
mkdir -p "${SNAPSHOT_DIR}"
SNAPSHOT_FILE="${SNAPSHOT_DIR}/progress-$(date -u +%Y%m%dT%H%M%SZ).json"
```

### Snapshot contents

```json
{
  "timestamp": "2026-03-08T10:30:00Z",
  "phase": "Phase 26",
  "progress": {
    "total": 16,
    "todo": 5,
    "wip": 3,
    "done": 6,
    "confirmed": 2
  },
  "progress_rate": 50,
  "recent_commits": ["abc1234 feat: ...", "def5678 fix: ..."],
  "recent_files": ["skills/harness-work/SKILL.md", "..."],
  "notes": ""
}
```

### Diff comparison

When a previous snapshot exists, show the diff:

```markdown
## Snapshot diff

| Metric | Previous ({{prev_time}}) | Current | Change |
|--------|-------------------------|---------|--------|
| Progress rate | {{prev}}% | {{current}}% | +{{diff}}%pt |
| Done tasks | {{prev_done}} | {{current_done}} | +{{diff_done}} |
| WIP tasks | {{prev_wip}} | {{current_wip}} | {{diff_wip}} |
```

> **Design intent**: Snapshots are for manual use when users want to "record the current state."
> This is a different feature from the automatic progress feed during breezing (26.2.3).

## Step 5: Next action suggestions

```
Next steps

**Priority 1**: {{task}}
- Reason: {{requested / waiting for unblock}}

**Recommended**: harness-work, harness-review
```

## Anomaly detection

| Situation | Warning |
|-----------|---------|
| Multiple `cc:WIP` | Multiple tasks in progress simultaneously |
| `pm:requested` unprocessed | Handle PM requests first |
| Large drift | Task management not keeping up |
| WIP not updated for 3+ days | Check if blocked |

## Step 6: Retrospective (default ON)

If there is at least 1 `cc:done` task, automatically run a retrospective.
Can be explicitly skipped with `--no-retro`.

### Step R1: Collect completed tasks

```bash
# Extract cc:done / pm:approved tasks from Plans.md
grep -E 'cc:done|pm:approved' Plans.md

# Recent completion commit history
git log --oneline --since="7 days ago"

# Change scale
git diff --stat HEAD~10
```

### Step R2: Retrospective 4 items

| Item | Analysis method |
|------|----------------|
| **Estimation accuracy** | Infer expected file count from Plans.md task descriptions → compare with actual changed files from `git diff --stat` |
| **Block causes** | Aggregate reason patterns for tasks with `blocked` marker (technical / external dependency / unclear spec) |
| **Quality marker accuracy** | For tasks tagged `[feature:security]` etc., check if related issues actually occurred |
| **Scope variation** | Task count in Plans.md at first commit vs current count (added/removed count) |

### Step R3: Retrospective summary output

```markdown
## Retrospective Summary

**Period**: {{start_date}} – {{end_date}}

| Metric | Value |
|--------|-------|
| Completed tasks | {{count}} |
| Blocks occurred | {{blocked_count}} |
| Scope variation | +{{added}} / -{{removed}} |
| Estimation accuracy | Expected {{est}} files → Actual {{actual}} files |

### Learnings
- {{1-2 lines of learning}}

### Actions for next time
- {{1-2 lines of improvement actions}}
```

### Step R4: Record to harness-mem

Record retrospective results in harness-mem for reference during the next `create`.
Record location: Relevant agent memory under `.claude/agent-memory/`.

## Related skills

- `harness-plan` — Plan creation and task management
- `harness-work` — Task implementation
- `harness-review` — Code review
