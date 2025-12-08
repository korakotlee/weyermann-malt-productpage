---
description: Capture session knowledge with descriptive filename
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
---

# /snapshot - Knowledge Capture

Capture what we learned, discovered, and how things connect. Local log only - no GitHub issue.

## Usage
```
/snapshot [descriptive title]
```

## Output
**Local Log Only**: `ψ-logs/YYYY-MM/DD/HH.MM_[title-slug].md`

Examples:
- `/snapshot context-finder default mode` → `10.35_context-finder-default-mode.md`
- `/snapshot jq emoji regex fix` → `10.40_jq-emoji-regex-fix.md`

---

## Steps

### Step 1: Get Title from Arguments
If no title provided, ask user or derive from recent commit messages.

Slugify title: lowercase, spaces → hyphens, remove special chars.

### Step 2: Gather Context
```bash
git log --format="%h %ad %s" --date=format:"%H:%M" -10
git status --short
TZ='Asia/Bangkok' date +"%H.%M"
```

### Step 3: Create Log File
```bash
mkdir -p "ψ-logs/$(date +%Y-%m)/$(date +%d)"
```

Filename: `ψ-logs/YYYY-MM/DD/HH.MM_[title-slug].md`

### Step 4: Write Knowledge Content

```markdown
# [Title]

**Time**: HH:MM GMT+7

## What We Learned
- [Key insight 1]
- [Key insight 2]

## How Things Connect
- [Relationship 1]: X relates to Y because...
- [Relationship 2]: Pattern A enables B...

## Key Discoveries
- [Discovery with context]

## Commits
- `hash` message

## Tags
`tag1` `tag2` `tag3`

## Raw Thoughts
[Unprocessed observations, questions, ideas]
```

### Step 5: Commit
```bash
git add "ψ-logs/"
git commit -m "learn: [title]"
```

---

## Content Focus

### What We Learned
- Insights gained this session
- "Aha" moments
- Corrections to previous understanding

### How Things Connect
- Relationships between components
- Patterns that emerged
- Why X works with Y

### Key Discoveries
- Technical findings
- Gotchas and workarounds
- Things that surprised us

---

## Rules
- **DESCRIPTIVE FILENAME** - Title becomes filename slug
- **NO GITHUB ISSUE** - Use `ccc` for that
- **KNOWLEDGE FOCUS** - What we learned, not what we did
- **RELATIONSHIPS** - How things connect
- **FAST** - < 20 seconds

## Arguments
ARGUMENTS: $ARGUMENTS
