# Multi-Agent Workflow Pattern

## Overview

Use Codex agents for heavy analysis work, capture their output, integrate into main workflow. This saves tokens on the main Claude agent.

## The Pattern

```
Main Agent (Claude)
    │
    ├── Send task ──────────────► Codex (Agent 2)
    │                                   │
    │                                   ▼
    │                             [Heavy analysis]
    │                                   │
    │◄── Capture output ────────────────┘
    │
    ├── Integrate results
    │
    └── Continue workflow
```

## Commands

### Fast Method: File Signal (~100ms latency)
```bash
# 1. Setup signal file (use .tmp/ inside repo, gitignored)
SIGNAL=".tmp/codex-signal-$$"
rm -f "$SIGNAL"

# 2. Send task with signal instruction
source .envrc && maw hey 2 "Your task here. When done, run: touch $SIGNAL"

# 3. Wait for signal (fast polling)
while [ ! -f "$SIGNAL" ]; do sleep 0.1; done

# 4. Capture response
tmux capture-pane -t ai-000-workshop-product-page:1.2 -p -S -50
rm -f "$SIGNAL"
```

**Proven**: Codex WILL execute `touch .tmp/file` after answering (tested 2025-12-07).

**Safety**: Always use `.tmp/` inside repo (gitignored), never `/tmp/` outside.

### Slow Method: Fixed Sleep
```bash
# Send task to Codex
source .envrc && maw hey 2 "Your task here"

# Wait for completion
sleep 10  # Adjust based on task complexity

# Capture response
tmux capture-pane -t ai-000-workshop-product-page:1.2 -p -S -50
```

## Agent Roles

| Agent | Model | Best For |
|-------|-------|----------|
| Main | Claude | Orchestration, integration, user interaction |
| Agent 1 | Claude | Complex coding, architecture decisions |
| Agent 2 | Codex | Analysis, research, file processing |
| Agent 3 | Codex | Parallel tasks, verification |

## Worktree Rules

Each agent MUST stay in their worktree:

```
Main Agent  → /project/root (main branch)
Agent 1     → /project/agents/1 (agents/1 branch)
Agent 2     → /project/agents/2 (agents/2 branch)
Agent 3     → /project/agents/3 (agents/3 branch)
```

**Golden Rule:**
> Know who you are, sync from right source, never force (-f), stay in your worktree

## Self-Improving Loop

```
1. Main: Define task
2. Main: Send to Codex → maw hey 2 "analyze X"
3. Wait: sleep N
4. Main: Capture → tmux capture-pane
5. Main: Parse suggestions
6. Main: Apply improvements
7. Main: Test result
8. If not satisfied → Go to step 2 with refined task
```

## Example: Optimize a File

```bash
# Step 1: Ask Codex to analyze
source .envrc && maw hey 2 "Read file.md and suggest how to reduce it to <80 lines"

# Step 2: Wait
sleep 15

# Step 3: Capture
OUTPUT=$(tmux capture-pane -t ai-000-workshop-product-page:1.2 -p -S -50)

# Step 4: Apply suggestions (Main agent reads and implements)
```

## Benefits

| Approach | Main Agent Tokens | Speed |
|----------|-------------------|-------|
| Main does everything | High | Slow |
| Delegate to Codex | Low | Fast (parallel) |

## Tips

1. **Use file signals** - ~100ms latency vs 10s+ fixed sleep
2. **Be specific** - Clear task descriptions get better results
3. **Include signal instruction** - "When done, run: touch /tmp/signal"
4. **Capture more lines** - Use `-S -50` or `-S -100` for long output
5. **Iterate** - Send follow-up tasks for refinement

## Latency Comparison

| Method | Latency | Reliability |
|--------|---------|-------------|
| Fixed sleep | 10-20s | ✓ Always works |
| File signal | ~100ms | ✓ Proven (Codex executes touch) |
| tmux wait-for | ~0ms | ? Untested |

## Quick Reference

```bash
# List agents
maw agents list

# Send to specific agent
maw hey 1 "message"    # Claude
maw hey 2 "message"    # Codex
maw hey 3 "message"    # Codex

# Broadcast to all
maw hey all "git pull"

# Capture any pane
tmux capture-pane -t ai-000-workshop-product-page:1.N -p -S -30
```
