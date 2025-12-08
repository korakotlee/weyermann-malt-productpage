---
description: Create context issue AND session log in one command
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
---

# /snapshot - Unified Session Capture

Combines `ccc` (GitHub issue) + `/knowledge-save` (local log) into single command.

## Usage
```
/snapshot [brief title]
```

## Output
1. **GitHub Issue**: `snapshot: [title]` - for tracking
2. **Local Log**: `ψ-logs/YYYY-MM/DD/HH.MM_snapshot.md` - for fast search

---

## Steps

### Step 1: Gather Context
```bash
# Current state
git status --short
git branch --show-current

# Recent activity
git log --format="%h %ad %s" --date=format:"%H:%M" -10

# Time (GMT+7)
TZ='Asia/Bangkok' date +"%H:%M"
```

### Step 2: Auto-Extract Tags
From commit messages, extract:
- Type prefixes: `feat`, `fix`, `docs`, `refactor`, `test`
- Component names from paths in `git status`
- Feature keywords from recent work

### Step 3: Create Local Log
```bash
mkdir -p "ψ-logs/$(date +%Y-%m)/$(date +%d)"
```

Write to `ψ-logs/YYYY-MM/DD/HH.MM_snapshot.md`:

```markdown
# Snapshot: [TITLE]

**Time**: [HH:MM] GMT+7
**Branch**: [branch]

## Context Links
- **Issues**: #XX, #YY (related issues from session)
- **Commits**:
  - `hash` HH:MM - message
- **Tags**: `tag1` `tag2` `tag3`

## What Happened
- [Action 1]
- [Action 2]

## Key Discoveries
- [Finding 1]
- [Finding 2]

## Files Touched
```
[git status --short]
```

## Next Steps
- [ ] [Next 1]
- [ ] [Next 2]

## Raw Thoughts
[Unprocessed ideas, questions, observations]
```

### Step 4: Create GitHub Issue
Title: `snapshot: [TITLE]`

Body:
```markdown
**Time**: [HH:MM] GMT+7
**Branch**: [branch]
**Log**: `ψ-logs/YYYY-MM/DD/HH.MM_snapshot.md`

## Current State
[Brief description of where we are]

## Recent Commits
- `hash` message
- `hash` message

## Uncommitted Changes
```
[git status --short or "Clean"]
```

## Key Discoveries
- [Finding 1]
- [Finding 2]

## Next Steps
- [ ] [Next 1]
- [ ] [Next 2]

## Tags
`tag1` `tag2` `tag3`
```

### Step 5: Commit & Output
```bash
git add "ψ-logs/"
git commit -m "snapshot: [TITLE]"
```

Output:
```
Snapshot created:
- Issue: #XX (link)
- Log: ψ-logs/YYYY-MM/DD/HH.MM_snapshot.md
- Commit: abc1234
```

---

## Rules
- **FAST** - < 30 seconds total
- **LINK EVERYTHING** - Issues, commits, files are mandatory
- **DUAL OUTPUT** - Both GitHub issue AND local log
- **AUTO-TAG** - Extract from commits, don't ask user
- **GMT+7** - Primary timezone, always

## Arguments
ARGUMENTS: $ARGUMENTS
