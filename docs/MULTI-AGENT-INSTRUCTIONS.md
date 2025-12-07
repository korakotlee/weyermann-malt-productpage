# Multi-Agent Consultation Instructions

**Last Updated**: 2025-12-07
**Tested With**: 1 Claude + 2 Codex agents

---

## Quick Reference

```bash
# Send task to specific agent
maw hey 1 "your task here"
maw hey 2 "your task here"
maw hey 3 "your task here"

# Broadcast to all agents
maw hey all "your task here"

# Clear stuck agents
maw clear

# Check agent status
maw hey --map
```

---

## 1. Agent Configuration

### Current Setup

| Agent | Pane | CLI Command | Model | Reasoning |
|-------|------|-------------|-------|-----------|
| Agent 1 | LEFT (0) | `claude --dangerously-skip-permissions` | Claude Sonnet | `alwaysThinkingEnabled: true` |
| Agent 2 | CENTER (1) | `codex --dangerously-bypass-approvals-and-sandbox` | `gpt-5.1-codex-max` | `xhigh` |
| Agent 3 | RIGHT (2) | `codex --dangerously-bypass-approvals-and-sandbox` | `gpt-5.1-codex-max` | `xhigh` |

### Performance Benchmarks (2025-12-07)

Simple task (count lines, write file):
- Agent 1 (Claude): **11 seconds**
- Agent 2 (Codex): **12 seconds**
- Agent 3 (Codex): **21 seconds**

---

## 2. Task Message Format

### Standard Template

```
[TASK TYPE]: [Brief description]

[Detailed instructions]

Output to: contributions/[filename].md
When done: touch /path/to/.tmp/agent{N}-done
```

### Example: Research Task

```bash
maw hey 1 "RESEARCH TASK: Analyze PocketBase hook system.

Read: .tmp/pocketbase-src/tools/hook/hook.go
Focus on:
1. Hook chain pattern
2. Priority system
3. Event types

Write findings to: contributions/hook-research.md (100-200 words)
When done: touch /Users/nat/000-workshop-product-page/.tmp/agent1-done"
```

### Example: Code Analysis Task

```bash
maw hey 2 "CODE ANALYSIS: Count functions in core/base.go.

Read the file and list:
- Total functions
- Public vs private
- Key function names

Write to: contributions/function-analysis.md
When done: touch /Users/nat/000-workshop-product-page/.tmp/agent2-done"
```

### Example: Comparison Task

```bash
maw hey 3 "COMPARISON: Compare SQLite vs PostgreSQL for our use case.

Consider:
- Setup complexity
- Performance
- Scalability
- Our requirements (local-first, single binary)

Write recommendation to: contributions/db-comparison.md
When done: touch /Users/nat/000-workshop-product-page/.tmp/agent3-done"
```

---

## 3. Parallel Task Orchestration

### Pattern: Send All, Wait All

```bash
# 1. Clean old signals
rm -f .tmp/agent*-done

# 2. Record start time
START=$(date +%s)
echo "Started at $(date '+%H:%M:%S')"

# 3. Send tasks in parallel
source .envrc
maw hey 1 "Task for agent 1... touch .tmp/agent1-done when done"
maw hey 2 "Task for agent 2... touch .tmp/agent2-done when done"
maw hey 3 "Task for agent 3... touch .tmp/agent3-done when done"

# 4. Wait for all completions
for agent in 1 2 3; do
    while [ ! -f .tmp/agent${agent}-done ]; do
        sleep 1
    done
    END=$(date +%s)
    echo "Agent $agent completed in $((END - START))s"
done

# 5. Collect results
cat agents/1/contributions/*.md
cat agents/2/contributions/*.md
cat agents/3/contributions/*.md
```

### Pattern: First to Complete Wins

```bash
while true; do
    for agent in 1 2 3; do
        if [ -f .tmp/agent${agent}-done ]; then
            echo "Agent $agent finished first!"
            cat agents/${agent}/contributions/result.md
            break 2
        fi
    done
    sleep 0.5
done
```

### Pattern: Timeout with Fallback

```bash
TIMEOUT=60
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    DONE=0
    for agent in 1 2 3; do
        [ -f .tmp/agent${agent}-done ] && DONE=$((DONE + 1))
    done

    if [ $DONE -eq 3 ]; then
        echo "All agents completed!"
        break
    fi

    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "Timeout! Only $DONE/3 agents completed"
fi
```

---

## 4. Best Practices

### Do's ✅

1. **Always use absolute paths** for signal files
   ```bash
   touch /Users/nat/000-workshop-product-page/.tmp/agent1-done
   ```

2. **Clean signal files before each task**
   ```bash
   rm -f .tmp/agent*-done
   ```

3. **Specify output location clearly**
   ```
   Write to: contributions/analysis.md
   ```

4. **Give focused, specific tasks**
   - One task per message
   - Clear deliverable
   - Defined scope

5. **Use parallel execution for independent tasks**
   - Research different topics
   - Analyze different files
   - Generate different artifacts

### Don'ts ❌

1. **Don't send dependent tasks in parallel**
   - If task B needs output from task A, send sequentially

2. **Don't use relative paths for signals**
   - Bad: `touch .tmp/done`
   - Good: `touch /full/path/.tmp/done`

3. **Don't overwhelm with complex multi-part tasks**
   - Break into smaller, focused tasks

4. **Don't forget to clean up signal files**
   - Old signals cause false positives

5. **Don't mix task types without clear separation**
   - Keep research separate from implementation

---

## 5. Agent Strengths

### Claude (Agent 1)
- **Best for**: Analysis, writing, complex reasoning
- **Speed**: Fast (11s benchmark)
- **Style**: Follows AGENTS.md communication style
- **Quirk**: May not always create files (focus on analysis)

### Codex (Agents 2 & 3)
- **Best for**: Code tasks, file operations, structured output
- **Speed**: Fast (12-21s benchmark)
- **Model**: gpt-5.1-codex-max with xhigh reasoning
- **Quirk**: Verbose by default (needs AGENTS.md for concise output)

### Task Allocation Strategy

| Task Type | Best Agent | Why |
|-----------|------------|-----|
| Deep research | Agent 1 (Claude) | Better reasoning |
| Code analysis | Any | All capable |
| File generation | Agent 2/3 (Codex) | Reliable file ops |
| Comparison/review | Agent 1 (Claude) | Nuanced analysis |
| Parallel simple tasks | All 3 | Speed through parallelism |

---

## 6. Troubleshooting

### Agent Not Responding

```bash
# Check if session exists
tmux has-session -t ai-000-workshop-product-page

# List panes
tmux list-panes -t ai-000-workshop-product-page

# Clear stuck agent
maw clear

# Check pane content (scroll back)
# Use tmux mouse mode or Ctrl+B, [
```

### Signal File Not Created

1. Check if agent is still working (view pane)
2. Verify path is absolute
3. Check .tmp directory exists: `mkdir -p .tmp`
4. Agent may have errored - check pane output

### Wrong Output Location

Agents work in their own worktree:
- Agent 1: `agents/1/`
- Agent 2: `agents/2/`
- Agent 3: `agents/3/`

Files are created relative to their worktree root.

### Timing Issues

```bash
# Between keystroke commands
sleep 0.05

# After maw hey before checking signals
sleep 2  # Give agent time to start

# Between parallel sends
# No delay needed - tmux handles queuing
```

---

## 7. Complete Orchestration Example

```bash
#!/bin/bash
# Multi-agent research orchestration

REPO_ROOT="/Users/nat/000-workshop-product-page"
cd "$REPO_ROOT"
source .envrc

# Clean up
rm -f .tmp/agent*-done

# Record start
START=$(date +%s)
echo "🚀 Starting multi-agent research at $(date '+%H:%M:%S')"

# Send parallel tasks
maw hey 1 "Research PocketBase Go hooks. Focus on OnServe, OnRecordCreate.
Write to: contributions/hooks-research.md
When done: touch $REPO_ROOT/.tmp/agent1-done"

maw hey 2 "Analyze PocketBase router implementation in tools/router/.
Write to: contributions/router-analysis.md
When done: touch $REPO_ROOT/.tmp/agent2-done"

maw hey 3 "Compare PocketBase to alternatives (Supabase, Firebase).
Write to: contributions/comparison.md
When done: touch $REPO_ROOT/.tmp/agent3-done"

# Wait with progress
echo "⏳ Waiting for agents..."
while true; do
    DONE=""
    for agent in 1 2 3; do
        [ -f .tmp/agent${agent}-done ] && DONE="${DONE}${agent}"
    done

    NOW=$(date +%s)
    ELAPSED=$((NOW - START))
    echo "  [${ELAPSED}s] Completed: ${DONE:-none}"

    [ ${#DONE} -eq 3 ] && break
    sleep 3
done

# Report
END=$(date +%s)
TOTAL=$((END - START))
echo ""
echo "✅ All agents completed in ${TOTAL}s"
echo ""
echo "=== RESULTS ==="
for agent in 1 2 3; do
    echo "--- Agent $agent ---"
    cat agents/$agent/contributions/*.md 2>/dev/null | head -20
    echo ""
done
```

---

## 8. Integration with Main Workflow

### From Main Agent (Orchestrator)

The Main Agent runs in the root repo and coordinates:

1. **Plan the work** - Decide what to delegate
2. **Distribute tasks** - Use `maw hey` commands
3. **Monitor progress** - Watch signal files
4. **Collect results** - Read contributions
5. **Synthesize** - Combine agent outputs

### File Flow

```
Main Agent (root)
    │
    ├─► maw hey 1 "task"
    │       └─► agents/1/contributions/result.md
    │
    ├─► maw hey 2 "task"
    │       └─► agents/2/contributions/result.md
    │
    └─► maw hey 3 "task"
            └─► agents/3/contributions/result.md

Main Agent reads all contributions and synthesizes
```

---

## Related Files

- `AGENTS.md` - Agent identity and communication style
- `.agents/scripts/hey.sh` - Send messages to agents
- `.agents/scripts/clear-panes.sh` - Clear stuck agents
- `.agents/scripts/start-agents.sh` - Start agent session
- `.tmp/` - Signal files directory (gitignored)
