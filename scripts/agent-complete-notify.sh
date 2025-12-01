#!/bin/bash
# Agent Completion Notification Hook
# Called by Stop hook when a MAW agent (Claude session) finishes

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
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# Try to get last assistant message from transcript (what Claude said last)
LAST_MESSAGE=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    # Get last assistant message, take first 100 chars
    LAST_MESSAGE=$(tail -20 "$TRANSCRIPT_PATH" | grep -o '"text":"[^"]*"' | tail -1 | sed 's/"text":"//;s/"$//' | head -c 100)
fi

# Detect agent number from worktree path (e.g., /path/to/agents/1 or /path/to/agents/2)
AGENT_NUM=""
if [[ "$CWD" =~ agents/([0-9]+) ]]; then
    AGENT_NUM="${BASH_REMATCH[1]}"
fi

# If main agent (not in agents/ worktree), call it "main"
if [ -z "$AGENT_NUM" ]; then
    AGENT_NUM="main"
fi

# Get timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Log completion
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.agent-locks/completions.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$TIMESTAMP] Agent $AGENT_NUM completed - Session: $SESSION_ID" >> "$LOG_FILE"

# Optional: Send desktop notification (macOS)
if command -v osascript &> /dev/null; then
    osascript -e "display notification \"Agent $AGENT_NUM completed\" with title \"MAW Agent\" sound name \"Glass\""
fi

# Optional: Speak completion (macOS)
if command -v say &> /dev/null; then
    if [ -n "$LAST_MESSAGE" ]; then
        say "Agent $AGENT_NUM says: $LAST_MESSAGE" &
    else
        say "Agent $AGENT_NUM completed" &
    fi
fi

# Optional: Send to tmux status line
if command -v tmux &> /dev/null && [ -n "${TMUX:-}" ]; then
    tmux display-message "🤖 Agent $AGENT_NUM completed"
fi

# Output JSON for Claude Code
cat << EOF
{
  "decision": "approve",
  "reason": "Agent $AGENT_NUM completion logged"
}
EOF

exit 0
