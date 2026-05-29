---
name: merge-plans
description: "A skill for merging and updating Plans.md (while preserving user tasks). Use when you need to consolidate multiple Plans.md files."
allowed-tools: ["Read", "Write", "Edit"]
---

# Merge Plans Skill

A skill for applying template structure while preserving user task data
when updating an existing Plans.md.

---

## Purpose

- Preserve user tasks (the 🔴🟡🟢📦 sections)
- Update template structure and marker definitions
- Update the last-updated information

---

## Plans.md Structure

```markdown
# Plans.md - Task Management

> **Project**: {{PROJECT_NAME}}
> **Last Updated**: {{DATE}}
> **Updated by**: Claude Code

---

## 🔴 In Progress          ← User data (preserved)

## 🟡 Not Started          ← User data (preserved)

## 🟢 Completed            ← User data (preserved)

## 📦 Archive              ← User data (preserved)

## Marker Legend           ← Updated from template

## Last Update Info        ← Update date
```

---

## Merge Algorithm

### Step 1: Split into Sections

```
Split the existing Plans.md into the following sections:

1. Header section (# Plans.md ... ---)
2. 🔴 In Progress (up to next section)
3. 🟡 Not Started (up to next section)
4. 🟢 Completed (up to next section)
5. 📦 Archive (up to next section)
6. Marker Legend (up to next section)
7. Last Update Info (to end of file)
```

### Step 2: Extract Task Sections

```bash
extract_section() {
  local file="$1"
  local start_marker="$2"
  local end_markers="$3"  # Pipe-delimited end markers

  awk -v start="$start_marker" -v ends="$end_markers" '
    BEGIN { in_section = 0; split(ends, end_arr, "|") }
    $0 ~ start { in_section = 1; next }
    in_section {
      for (i in end_arr) {
        if ($0 ~ end_arr[i]) { in_section = 0; exit }
      }
      if (in_section) print
    }
  ' "$file"
}

# Extract each section
TASKS_WIP=$(extract_section "$PLANS_FILE" "## 🔴" "## 🟡|## 🟢|## 📦|## Marker|---")
TASKS_TODO=$(extract_section "$PLANS_FILE" "## 🟡" "## 🔴|## 🟢|## 📦|## Marker|---")
TASKS_DONE=$(extract_section "$PLANS_FILE" "## 🟢" "## 🔴|## 🟡|## 📦|## Marker|---")
TASKS_ARCHIVE=$(extract_section "$PLANS_FILE" "## 📦" "## 🔴|## 🟡|## 🟢|## Marker|---")
```

### Step 3: Validate Tasks

```bash
# Confirm they are not empty
count_tasks() {
  echo "$1" | grep -c "^\s*- \[" || echo "0"
}

WIP_COUNT=$(count_tasks "$TASKS_WIP")
TODO_COUNT=$(count_tasks "$TASKS_TODO")
DONE_COUNT=$(count_tasks "$TASKS_DONE")
ARCHIVE_COUNT=$(count_tasks "$TASKS_ARCHIVE")

echo "Tasks to be preserved:"
echo "  In Progress: $WIP_COUNT"
echo "  Not Started: $TODO_COUNT"
echo "  Completed: $DONE_COUNT"
echo "  Archive: $ARCHIVE_COUNT"
```

### Step 4: Generate New Plans.md

```markdown
# Plans.md - Task Management

> **Project**: {{PROJECT_NAME}}
> **Last Updated**: {{DATE}}
> **Updated by**: Claude Code

---

## 🔴 In Progress

<!-- List cc:WIP tasks here -->

{{TASKS_WIP}}

---

## 🟡 Not Started

<!-- List cc:TODO, pm:requested (compatible: cursor:requested) tasks here -->

{{TASKS_TODO}}

---

## 🟢 Completed

<!-- List cc:done, pm:confirmed (compatible: cursor:confirmed) tasks here -->

{{TASKS_DONE}}

---

## 📦 Archive

<!-- Move old completed tasks here -->

{{TASKS_ARCHIVE}}

---

## Marker Legend

| Marker | Meaning |
|--------|---------|
| `pm:requested` | Task requested by PM (compatible: cursor:requested) |
| `cc:TODO` | Claude Code not started |
| `cc:WIP` | Claude Code in progress |
| `cc:done` | Claude Code complete (awaiting confirmation) |
| `pm:confirmed` | PM confirmation complete (compatible: cursor:confirmed) |
| `cursor:requested` | (compatible) Same as pm:requested |
| `cursor:confirmed` | (compatible) Same as pm:confirmed |
| `blocked` | Blocked (include reason) |

---

## Last Update Info

- **Updated**: {{DATE}}
- **Last session handler**: Claude Code
- **Branch**: main
- **Update type**: Plugin update
```

---

## Handling Empty Sections

If a section has no tasks, insert default text:

```markdown
## 🔴 In Progress

<!-- List cc:WIP tasks here -->

(None currently)
```

---

## Error Handling

### If Plans.md Cannot Be Parsed

```bash
if ! validate_plans_structure "$PLANS_FILE"; then
  echo "⚠️ Could not parse Plans.md structure"
  echo "Keeping backup and using new template"

  # Backup
  cp "$PLANS_FILE" "${PLANS_FILE}.bak.$(date +%Y%m%d%H%M%S)"

  # Use template
  use_template_instead=true
fi
```

### If Required Sections Are Missing

Missing sections are filled with template defaults.

---

## Outputs

| Item | Description |
|------|-------------|
| `merge_successful` | Merge success flag |
| `tasks_wip_count` | Number of in-progress tasks |
| `tasks_todo_count` | Number of not-started tasks |
| `tasks_done_count` | Number of completed tasks |
| `tasks_archive_count` | Number of archived tasks |
| `backup_created` | Whether a backup was created |

---

## Usage Example

```bash
# Invoke the skill
merge_plans \
  --existing "./Plans.md" \
  --template "$PLUGIN_PATH/templates/Plans.md.template" \
  --output "./Plans.md" \
  --project-name "my-project" \
  --date "$(date +%Y-%m-%d)"
```

---

## Related Skills

- `update-2agent-files` - Full update flow
- `generate-workflow-files` - Generate new files
