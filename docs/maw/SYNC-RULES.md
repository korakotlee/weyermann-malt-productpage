# Multi-Agent Sync Rules

**⚠️ CRITICAL: These rules prevent data loss and workflow corruption**

## Identity Check - ALWAYS FIRST

Before ANY git operation, verify your identity:

```bash
pwd                           # Where am I?
git branch --show-current     # Which branch am I on?
```

**You are either:**
- **Main Agent**: In project root (`/path/to/project`), on `main` branch
- **Agent 1/2/3**: In worktree (`/path/to/project/agents/N`), on `agents/N` branch

## Sync Rules by Identity

### Main Agent (Root, Main Branch)

**Pull from Remote ONLY**
```bash
# ✅ CORRECT
git pull --ff-only origin main

# ❌ NEVER
git pull origin agents/1
git pull origin agents/2
git pull origin agents/3
```

**Never Touch Agent Worktrees**
```bash
# ❌ FORBIDDEN
cd agents/1
cd agents/2
cd agents/3
rm -rf agents/*
git push --force origin agents/1
```

**Coordinate, Don't Control**
- Send tasks via `/maw.hey`
- Review PRs from agents
- Merge to main when ready
- Let agents sync themselves

### Agent 1/2/3 (Worktree, agents/N Branch)

**Merge from Local Main ONLY**
```bash
# ✅ CORRECT
git merge main

# ❌ NEVER
git pull origin main        # Wrong: skip local main
git merge origin/main       # Wrong: bypass local main
git rebase main             # Discouraged: can cause conflicts
```

**Push Your Own Branch**
```bash
# ✅ CORRECT
git push origin agents/1    # (or agents/2, agents/3)

# ❌ NEVER
git push origin main
git push --force origin agents/1
```

**Stay in Your Domain**
- Work only in your worktree directory
- Don't access ../agents/2 or ../agents/3
- Don't modify root project files directly

## 🔴 ABSOLUTE PROHIBITIONS

### Never Use Force Operations

```bash
# ❌ FORBIDDEN - WILL DESTROY HISTORY
git push --force
git push -f
git push --force-with-lease    # Still dangerous in multi-agent context
git checkout -f
git clean -f
git reset --hard origin/main   # From agent worktree
```

**Why**: Each agent's history is intentionally independent. Force operations destroy this independence and cause data loss.

**If branches diverge**: Use merge, ask for help, or create a new branch. NEVER force.

### Never Cross Agent Boundaries

```bash
# ❌ FORBIDDEN
cd agents/1 && git checkout agents/2
cd agents/2 && rm file.txt
git push origin agents/1:agents/2
```

**Why**: Each agent's worktree is their autonomous domain. Crossing boundaries breaks the isolation model.

### Never Sync from Wrong Source

```bash
# Main agent syncing from agent branch
# ❌ FORBIDDEN
git merge agents/1            # Main should never merge agent branches directly

# Agent syncing from remote main
# ❌ FORBIDDEN
git pull origin main          # Agent should merge local main, not pull remote
```

**Why**: The hierarchy is: `origin/main` → `local main` → `agents/N`. Skipping steps breaks the flow.

## Correct Sync Workflow

### Full Project Sync (Main Agent)

```bash
# 1. Verify identity
pwd                                    # Should show: /path/to/project
git branch --show-current              # Should show: main

# 2. Pull latest from remote
git pull --ff-only origin main

# 3. Notify all agents to sync
/maw.hey all "Main branch updated, please sync: git merge main"

# 4. Each agent (in their worktree) runs:
# git merge main
```

### Agent Receiving Updates

```bash
# 1. Verify identity
pwd                                    # Should show: /path/to/project/agents/1
git branch --show-current              # Should show: agents/1

# 2. Merge from local main
git merge main

# 3. Resolve conflicts if any
# (Never use --force to "resolve")

# 4. Continue work
```

### Agent Contributing Back

```bash
# 1. Commit your work
git add -A
git commit -m "feat: description"

# 2. Push to your branch
git push origin agents/1

# 3. Create PR
gh pr create --base main --head agents/1

# 4. Wait for main agent to review and merge
```

## Visual Sync Flow

```
┌─────────────┐
│ origin/main │  (GitHub remote)
└──────┬──────┘
       │ git pull --ff-only (Main Agent ONLY)
       ▼
┌─────────────┐
│ local main  │  (Shared .git database)
└──────┬──────┘
       │ git merge main (Agent 1/2/3 ONLY)
       ├─────────┬─────────┬─────────┐
       ▼         ▼         ▼         ▼
   ┌────────┐ ┌────────┐ ┌────────┐
   │agents/1│ │agents/2│ │agents/3│
   └────────┘ └────────┘ └────────┘
       │         │         │
       │ git push origin agents/N
       ▼         ▼         ▼
   ┌────────────────────────────┐
   │ origin/agents/1,2,3        │
   └────────────────────────────┘
             │
             │ gh pr create → merge
             ▼
       ┌─────────────┐
       │ origin/main │ (cycle continues)
       └─────────────┘
```

## Emergency Recovery

### If You Force-Pushed by Mistake

```bash
# 1. STOP immediately
# 2. Check reflog
git reflog agents/1

# 3. Find the commit BEFORE the force push
# 4. Reset to that commit (without --hard)
git reset abc1234

# 5. Create recovery branch
git checkout -b agents/1-recovery

# 6. Ask for help in project channel
```

### If Branches Are Hopelessly Diverged

```bash
# DON'T force push
# DON'T git reset --hard

# DO create a new branch
git checkout -b agents/1-new
git merge main
# Work from clean slate, cherry-pick what you need
```

### If You Modified Wrong Worktree

```bash
# 1. Stash changes
git stash

# 2. Go to correct worktree
cd ../agents/2  # (or wherever you should be)

# 3. Apply stash
git stash pop

# 4. Verify and commit in correct location
```

## Pre-Operation Checklist

Before ANY git operation:

- [ ] Run `pwd` - Am I in the right directory?
- [ ] Run `git branch --show-current` - Am I on the right branch?
- [ ] Am I the main agent or an agent worktree?
- [ ] Am I using the correct sync source? (origin/main vs local main)
- [ ] Am I about to use `--force`? (If yes, STOP and reconsider)
- [ ] Am I crossing agent boundaries? (If yes, STOP)

## Why This Matters

**Real Incident from 2025-11-30 Session:**

> Around 16:40, the main agent (me) misunderstood "merge to same commit" as needing
> to force-push all agent branches to match main. This violated the rule against force
> operations and destroyed the independent history of all three agent branches.
>
> **What was lost**: Each agent's work-in-progress commits, their independent evolution
> **What was learned**: Each agent's history is intentionally independent. The architecture
> depends on this independence. Force-syncing breaks the model.

## Summary: One Rule to Remember

**🎯 The Golden Rule of Multi-Agent Sync:**

> Know who you are (main or agent),
> sync from the right source (remote or local main),
> never force anything,
> respect all boundaries.

If you're ever unsure, ASK. Never guess with force operations.

---

**Last Updated**: 2025-12-01
**Incident Reference**: Session 2025-11-30 retrospective (force-push violation)
**Status**: MANDATORY for all agents
