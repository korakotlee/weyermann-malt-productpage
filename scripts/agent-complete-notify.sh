#!/bin/bash
# Agent Completion Notification Hook
# Called by SubagentStop hook when a subagent finishes

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Debug: log raw input to see what we receive
DEBUG_LOG="${CLAUDE_PROJECT_DIR:-.}/.agent-locks/debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")"
echo "---" >> "$DEBUG_LOG"
echo "$INPUT" >> "$DEBUG_LOG"

# Parse relevant fields
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Try to detect agent number from working directory (worktree path)
AGENT_NUM=""
if [[ "$CWD" =~ agents/([0-9]+) ]]; then
    AGENT_NUM="${BASH_REMATCH[1]}"
fi

# If no agent number from path, use a sequential counter
if [ -z "$AGENT_NUM" ]; then
    COUNTER_FILE="${CLAUDE_PROJECT_DIR:-.}/.agent-locks/agent_counter"
    if [ -f "$COUNTER_FILE" ]; then
        AGENT_NUM=$(cat "$COUNTER_FILE")
        AGENT_NUM=$((AGENT_NUM + 1))
    else
        AGENT_NUM=1
    fi
    echo "$AGENT_NUM" > "$COUNTER_FILE"
fi

# Get timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Log completion
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.agent-locks/completions.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$TIMESTAMP] Agent completed - Session: $SESSION_ID" >> "$LOG_FILE"

# Optional: Send desktop notification (macOS)
if command -v osascript &> /dev/null; then
    osascript -e "display notification \"Agent task completed\" with title \"MAW Agent\" sound name \"Glass\""
fi

# Optional: Speak completion (macOS)
if command -v say &> /dev/null; then
    say "Agent $AGENT_NUM completed" &
fi

# Optional: Send to tmux status line
if command -v tmux &> /dev/null && [ -n "${TMUX:-}" ]; then
    tmux display-message "🤖 Agent completed task"
fi

# Output JSON for Claude Code (optional context)
cat << EOF
{
  "decision": "approve",
  "reason": "Agent completion logged",
  "hookSpecificOutput": {
    "hookEventName": "SubagentStop",
    "additionalContext": "Agent task completed at $TIMESTAMP"
  }
}
EOF

exit 0
