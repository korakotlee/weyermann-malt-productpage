# Consult Before Acting

**Created**: 2025-12-08
**Source**: Issues cleanup with reference checking - discovered when cleanup agent made bad decisions
**Tags**: `pattern` `safety` `cleanup` `context-finder` `decision-making`

---

## Context Links
- **Issues**: [#63](https://github.com/nazt/weyermann-malt-productpage/issues/63)
- **Commits**: `4215142`, `909498b`
- **Raw Logs**: ψ-logs/2025-12/08/11.14_context-finder-issues-cleanup-session.md
- **Related**: [reference-based-cleanup.md](./reference-based-cleanup.md)

---

## Key Insight

> **Before any destructive action, consult existing context to avoid losing valuable connections you can't see.**

---

## The Problem

| What We Tried | What Happened |
|---------------|---------------|
| Close "stale" issues by age | Would have closed #3 (36 refs!), #4 (11 refs) |
| Trust issue titles alone | Missed that issues were heavily referenced |
| Batch close without checking | Almost lost valuable context |

---

## The Solution

### Pattern: Reference Check Before Action

```bash
# Before closing issue #N, count references:
REFS=$(grep -rl "#N" ψ-retrospectives/ ψ-learnings/ ψ-logs/ 2>/dev/null | wc -l)
COMMITS=$(git log --grep="#N" --oneline | wc -l)
TOTAL=$((REFS + COMMITS))

# Decision matrix
# 0 refs    → Safe to proceed
# 1-2 refs  → Review first
# 3+ refs   → Don't do it
```

**When to use**: Any destructive or irreversible action
**Why it works**: Hidden connections exist that aren't visible from surface-level info

---

## Anti-Patterns

| Don't Do This | Do This Instead |
|---------------|-----------------|
| Delete by age alone | Check references first |
| Trust titles/labels | Search for actual usage |
| Batch operations blindly | Verify each candidate |
| Assume unused = unimportant | 0 refs = safe, 3+ = valuable |

---

## Applies Beyond Cleanup

| Action | Consult First |
|--------|---------------|
| Delete file | `git log`, grep for imports |
| Close issue | grep in docs, commits |
| Remove feature | usage analytics, tests |
| Archive code | check for callers |
| Deprecate API | search for consumers |
| Drop database column | check all queries |

---

## Summary

| Concept | Details |
|---------|---------|
| Core principle | Look before you leap |
| Implementation | Embed search in action workflow |
| Decision matrix | 0=safe, 1-2=review, 3+=stop |
| Scope | Any destructive/irreversible action |

---

## Apply When

- About to delete, close, archive, or remove anything
- Making batch operations on multiple items
- Acting on metadata (titles, dates, labels) alone
- The action cannot be easily undone
- You're not 100% sure of the impact
