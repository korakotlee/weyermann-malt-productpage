# Actionable Next Steps - Unimplemented Issues

**Last Updated**: 2025-12-08 09:15 UTC  
**Based on**: UNIMPLEMENTED-ISSUES-AUDIT.md  
**Priority**: HIGH - 12 valuable ideas currently shelved

---

## This Week - Quick Wins (3-4 hours total)

### 1. Reopen #54: book-writer subagent (2-3 hours)

**Status**: Closed as "Cleanup: 0 references"  
**Reality**: High user need confirmed across 5+ retrospectives

**Quick Start**:
```bash
gh issue reopen 54

# Then create plan issue:
gh issue create --title "plan: Implement book-writer subagent" --body "$(cat <<'BODY'
## Overview
Automatically summarize retrospectives (2000+ words → 2-minute summary)

## User Need
- Leaders need quick session reviews
- Current retrospectives too verbose
- Multiple mentions in session notes: 'retrospective was too long'

## Proposed Solution
Create `/summarize` command that:
1. Reads last retrospective markdown
2. Extracts key sections (summary, learnings, next steps)
3. Generates 2-minute bullet-point review
4. Outputs formatted summary

## Implementation Approach
- Parse CLAUDE.md retrospective template
- Extract: Session Summary, Learnings, Next Steps, Honest Feedback
- Use model_name (Haiku) for fast summarization
- Output to stdout and optional file save

## Acceptance Criteria
- [ ] `/summarize` command works
- [ ] Reduces 2400-word session → 120-word summary
- [ ] Preserves critical insights
- [ ] Runs in <5 seconds
- [ ] Works with all retrospective formats

Estimated effort: 2-3 hours (parsing + LLM + testing)
BODY
)"
```

---

### 2. Fix #43: Archiver False Positives (1-2 hours)

**Status**: Closed as "Cleanup: 0 references"  
**Root Cause**: Archiver-subagent only checks title mentions, not git commits

**Quick Fix**:
```bash
gh issue reopen 43

# Edit the archiver-subagent prompt in CLAUDE.md:
# Location: Available Subagents > archiver section
# Add: "Check git log for issue references in commit messages"
# Add: "Flag issues with recent commits as NOT orphaned"

# Example problematic issues:
# - #50: Has commits de1a838, b23bae4, 233f72f (all recent)
# - #39: Has commits eee5436, 06f6ff4, 527916c (all recent)
# - #34: Has commits bb3c071, 92b280a (both recent)

# None of these should have been marked "0 references"
```

**What to Add to Archiver Prompt**:
```
### Reference Detection
Check for issue references in:
1. Issue title mentions
2. Related GitHub issues
3. Recent git commits (git log --grep="#N")
4. PR descriptions and comments

If ANY reference found in past 30 days → NOT orphaned
Flag ambiguous cases (old commits but no recent mention) → human review
```

---

### 3. Verify #50, #39, #34 Weren't Orphaned (15 min)

**Status**: Closed as "Cleanup: 0 references" but ACTUALLY IMPLEMENTED

```bash
# These should NOT have been closed
gh issue reopen 50  # context-finder
gh issue reopen 39  # 6-agent tmux layout
gh issue reopen 34  # Agent Status Tracking

# Comment on each: "Reopened - actually implemented with commits"
gh issue comment 50 --body "Reopened: Issue was incorrectly marked orphaned.
Commits: de1a838, b23bae4, 233f72f show full implementation.
Status: Actually implemented, archiver false positive."
```

---

## This Month - Medium Effort (7-10 hours total)

### 4. Implement #28: Central Inbox System (3-4 hours)

**Status**: Closed as "Clearing MAW backlog"  
**Blocker**: Agents need reliable communication (currently file signals = slow)

**Decision to Make First**:
- Option A: File-based signals (faster, already tested in #27)
- Option B: PocketBase (more robust, partially done in #30)

**Quick Prototype (File-based)**:
```bash
# Create proof-of-concept
mkdir -p .tmp/inbox/{in,out,processed}

# Agent write: echo "message" > .tmp/inbox/in/agent-1-123456.json
# Agent read: tail -f .tmp/inbox/out/agent-2/*.json

# Timestamp-based ordering ensures FIFO
```

**Effort**: 3-4 hours to decide, prototype, document

---

### 5. Implement #18: Self-improving Retrospective System (4-5 hours)

**Status**: Closed as "Clearing MAW backlog"  
**Value**: Quality enhancement for critical learning artifact

**What to Build**:
1. Add `/reflect` command
2. Reads last retrospective
3. Identifies weak sections
4. Suggests improvements
5. Creates feedback document

**Quick Implementation**:
```bash
# Add new command in .claude/commands/reflect.md
# Call context-finder to analyze retrospectives
# Use model to suggest improvements
# Output: "retrospective-feedback-YYYY-MM-DD.md"
```

---

### 6. Implement #43 Archiver Fix (1-2 hours) - REPEAT

This is time-critical because archiver is in active use.

---

## Next Quarter - Aspirational (7-9 hours)

### 7. Implement #23: Self-improving Orchestrator

**Status**: Closed as "Clearing backlog"  
**Vision**: Orchestrator learns from failures and improves iteratively

---

### 8. Implement #20: Thai Translator Quality Loop

**Status**: Closed as "Clearing backlog"  
**Vision**: Score translations, identify weak areas, improve prompt

---

## Process Changes (Do This Week)

### Create GitHub Labels
```bash
gh label create "shelved" \
  --description "High-value idea not currently being built" \
  --color "FFA500"

gh label create "needs-audit" \
  --description "Issue needs human review - may be misclassified" \
  --color "FF0000"
```

### Update Issue Close Standards
When closing issues, ALWAYS use one of:
- "Implemented in commit ABC123 (feature XYZ)"
- "Superseded by #XYZ (better approach)"
- "Deprecated: reason (project pivot, no longer needed, etc)"
- "Shelved: will revisit Q1 (specific trigger condition)"

**Never use**:
- "Clearing backlog" (too vague)
- "MAW-related" (doesn't explain status)
- "0 references" (often false - check git log first)

---

## Quick Decision Matrix

| Issue | Effort | Value | Blocker? | Recommendation |
|-------|--------|-------|----------|-----------------|
| #54 book-writer | 2-3h | HIGH | No | BUILD THIS WEEK |
| #43 archiver fix | 1-2h | HIGH | No | BUILD THIS WEEK |
| #28 inbox | 3-4h | HIGH | YES | BUILD THIS MONTH |
| #50 reopen | 0h | N/A | No | REOPEN TODAY |
| #39 reopen | 0h | N/A | No | REOPEN TODAY |
| #34 reopen | 0h | N/A | No | REOPEN TODAY |
| #18 retrospective | 4-5h | MEDIUM | No | BUILD NEXT MONTH |
| #23 orchestrator | 3-4h | MEDIUM | No | BUILD Q1 2025 |
| #20 translator | 2-3h | MEDIUM | No | BUILD Q1 2025 |

---

## Command Sequence (Copy-Paste Ready)

### To Reopen Misclassified Issues
```bash
# Reopen 3 that were incorrectly marked orphaned
gh issue reopen 50 39 34

# Comment on each
gh issue comment 50 --body "Reopened: Context-finder was fully implemented but marked orphaned. Commits: de1a838, b23bae4, 233f72f. Archiver false positive."

gh issue comment 39 --body "Reopened: 6-agent tmux layout fully documented and implemented. Commits: eee5436, 06f6ff4, 527916c. Archiver false positive."

gh issue comment 34 --body "Reopened: Agent Status Tracking system fully implemented. Commits: bb3c071, 92b280a. Archiver false positive."
```

### To Create Implementation Plan for #54
```bash
gh issue reopen 54

gh issue create --title "plan: Implement book-writer subagent" \
  --body "See ACTIONABLE-NEXT-STEPS.md line 20"
```

---

## Success Criteria

By end of this week:
- [ ] #50, #39, #34 reopened with correct status
- [ ] #54 book-writer implementation started
- [ ] #43 archiver prompt improved
- [ ] Process standards updated (close reason clarity)

By end of month:
- [ ] #54 book-writer complete and in use
- [ ] #43 archiver false positives eliminated
- [ ] #28 inbox system decision made and prototype built
- [ ] Issue audit shows improved categorization accuracy

