# 006: gogogo Delegation Workflow

**Date**: 2025-12-08
**Source**: Session cleaning up MAW short codes (Issue #78, PR #79)

## Key Lessons

### 1. Main Agent Never Executes Directly

Main agent orchestrates, subagents execute:

| Action | Who Does It |
|--------|-------------|
| Research | context-finder (haiku) |
| Planning | Plan agent (haiku) |
| Issue creation | new-feature (sonnet) |
| Execution | executor (haiku) or coder (opus) |
| Verification | verifier subagent (haiku) |
| Merge | executor (haiku) after user approval |

**Main agent's job**: Coordinate, summarize, present links, ask user.

### 2. nnn Workflow Chain

```
nnn = context-finder (haiku) → Plan (haiku) → new-feature (sonnet)
```

Each agent passes findings to the next. Attribution preserved.

### 3. gogogo Delegation Rules

```
gogogo = executor or coder → verifier → [ask user] → executor merge
```

| Task Type | Agent | Model |
|-----------|-------|-------|
| Simple (delete, move, git) | executor | haiku |
| Complex (code writing) | coder | opus |

**Default to coder (opus)** for quality. Use executor (haiku) only for simple bash tasks.

### 4. Always Provide Links

Never just say "Issue #78 created". Always fetch and display:

```bash
gh issue view N --json url --jq '.url'
```

Then present: `**Issue #N**: https://github.com/...`

Same for PRs. User expectation: clickable links, not just numbers.

### 5. Verification Before Merge

After executor creates PR:
1. Spawn verifier subagent to check PR vs plan
2. Verifier outputs: PASS or FAIL with details
3. If PASS → ask user at terminal: "OK to merge?"
4. If user approves → delegate merge to executor

**Main agent never merges directly.**

### 6. Complete gogogo Flow

```
1. Read plan issue
2. Delegate to executor/coder → creates PR
3. Delegate to verifier → checks PR vs plan
4. If PASS:
   - Present PR link to user
   - Ask: "Merge PR #N?"
5. If user says yes:
   - Delegate merge to executor
   - Report completion with link
```

### 7. Auto-Close Issues

PR body must include closing keyword to auto-close the plan issue:

```markdown
Closes #78
```

Or in commit message. Without this, issue stays open after merge.

## Anti-Patterns

- ❌ PR without `Closes #N` keyword (issue stays open)
- ❌ Main agent running bash commands directly
- ❌ Main agent reading files to verify (delegate!)
- ❌ Main agent doing `gh pr merge`
- ❌ Reporting issue/PR number without link
- ❌ Auto-merging without user approval

## Quick Reference

```
nnn:    research → plan → issue (all subagents)
gogogo: execute → verify → [ask] → merge (all subagents)
```

Main agent = orchestrator + presenter. Never executor.
