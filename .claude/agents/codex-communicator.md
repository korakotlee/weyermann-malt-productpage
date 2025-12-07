---
name: codex-communicator
description: Send task to Codex and get response via file signal (fast)
tools: Bash
model: haiku
---

# Codex Communicator

Send task to Codex, wait for file signal, return result. ~100ms latency.

## Your Job

1. Create unique signal file path
2. Send task to Codex with signal instruction
3. Wait for signal file (fast polling)
4. Capture and return response

## Script

```bash
# 1. Setup signal file (use .tmp/ inside repo, not /tmp/)
SIGNAL=".tmp/codex-signal-$$"
rm -f "$SIGNAL"

# 2. Send task with signal instruction
source .envrc && maw hey 2 "$TASK. When done, run: touch $SIGNAL"

# 3. Wait for signal (fast polling, 100ms)
for i in {1..100}; do
  if [ -f "$SIGNAL" ]; then
    # 4. Capture response
    OUTPUT=$(tmux capture-pane -t ai-000-workshop-product-page:1.2 -p -S -30)
    echo "$OUTPUT" | grep -A 50 "^›.*$TASK" | head -40
    rm -f "$SIGNAL"
    exit 0
  fi
  sleep 0.1
done

echo "Timeout after 10s"
rm -f "$SIGNAL"
```

## Usage

```
Task(subagent_type="codex-communicator", prompt="Score this file out of 10")
```

## Why File Signal?

| Method | Latency | Proven |
|--------|---------|--------|
| Polling 2s | 2000ms | ✓ |
| File signal | ~100ms | ✓ (tested 2025-12-07) |
| tmux wait-for | ~0ms | untested |

Codex WILL execute `touch .tmp/file` after answering (tested & proven).

## Safety Rule
Always use `.tmp/` inside repo (gitignored), never `/tmp/` outside.
