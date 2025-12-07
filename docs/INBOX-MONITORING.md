# PocketBase Inbox Monitoring & Dashboard

Real-time visualization and API access to see how agents talk to each other.

## 📊 Web Dashboard

**Open the dashboard:**
```bash
maw inbox monitor
# or
open http://127.0.0.1:8090
```

**Features:**
- 🤖 Active agents list
- 📈 Real-time message statistics
- 👤 Per-agent stats (sent, received, inbox counts)
- 💬 Message feed with status
- 🔄 Auto-refresh every 5 seconds

## 🔌 REST API Endpoints

### Monitor Agents
```bash
curl http://127.0.0.1:8090/api/monitor/agents
```

**Response:**
```json
{
  "agents": {
    "agent1": true,
    "agent2": true,
    "agent3": true
  },
  "count": 3
}
```

### Get All Conversations
```bash
curl http://127.0.0.1:8090/api/monitor/conversations
```

**Response:**
```json
{
  "messages": [
    {
      "id": "1qd4j8nyl3nz3cd",
      "from": "agent1",
      "to": "agent2",
      "message": "Hello agent2",
      "status": "unread",
      "priority": 10,
      "created": "2025-12-07T20:45:30.123Z"
    },
    ...
  ],
  "total": 42
}
```

### Agent Statistics
```bash
curl http://127.0.0.1:8090/api/monitor/agent/agent1/stats
```

**Response:**
```json
{
  "agent": "agent1",
  "sent": 15,
  "received": 10,
  "inbox_stats": {
    "unread": 3,
    "processing": 1,
    "done": 6
  }
}
```

## 🛠️ Command-Line Interface

**Send a message:**
```bash
maw inbox send agent1 agent2 "Hello agent2" 10
```

**Get unread messages:**
```bash
maw inbox get agent1
```

**Claim a message (mark as processing):**
```bash
maw inbox claim <message-id>
```

**Complete a message (mark as done):**
```bash
maw inbox complete <message-id>
```

**View statistics:**
```bash
maw inbox stats              # Overall stats
maw inbox stats agent1       # Stats for agent1
```

**List all agents:**
```bash
maw inbox list
```

**Open dashboard:**
```bash
maw inbox monitor
```

## 📋 Message Status Flow

```
unread → processing → done
```

1. **unread**: Message just arrived, waiting to be picked up
2. **processing**: Agent has claimed the message, working on it
3. **done**: Message fully processed

## 🎯 Use Cases

### Monitor Agent Activity
```bash
# Check stats every 5 seconds
watch -n 5 'maw inbox stats'
```

### Send Multiple Messages
```bash
maw inbox send agent1 agent2 "First task" 10
maw inbox send agent1 agent3 "Second task" 5
maw inbox send agent2 agent3 "Collaboration message" 8
```

### Work with Inbox
```bash
# Get unread
maw inbox get agent1
# ID: abc123

# Claim and process
maw inbox claim abc123

# Complete
maw inbox complete abc123

# Verify stats
maw inbox stats agent1
```

## 🔍 Dashboard Metrics

| Metric | Description |
|--------|-------------|
| Active Agents | Count of unique agents in system |
| Total Messages | All messages (all statuses) |
| Unread | Messages waiting to be picked up |
| Processing | Messages currently being worked on |
| Done | Completed messages |
| Sent | Messages agent sent |
| Received | Messages agent received |

## 🌐 API Format

All API responses are JSON with consistent structure:

```json
{
  "status": 200,
  "data": { ... }
}
```

## 📡 Auto-Refresh

The dashboard auto-refreshes every 5 seconds. Click "🔄 Refresh Now" to force an immediate refresh.

## 🚀 Integration with Agents

Agents can monitor their own inbox:

```bash
# Source the client
source agents/1/contributions/pocketbase-inbox/client.sh

# Get unread messages
get_unread agent1

# Send message to another agent
send_message agent1 agent2 "Task complete" 5

# Claim and process
TASK_ID=$(get_unread agent1 | jq '.items[0].id')
claim_message "$TASK_ID"

# Finish processing
complete_message "$TASK_ID"
```

## 📊 Monitoring Examples

### Check if server is running
```bash
curl -s http://127.0.0.1:8090/api/monitor/agents | jq .count
```

### Count total pending work
```bash
curl -s http://127.0.0.1:8090/api/monitor/conversations | \
  jq '[.messages[] | select(.status == "unread" or .status == "processing")] | length'
```

### Find messages for specific agent
```bash
curl -s http://127.0.0.1:8090/api/monitor/conversations | \
  jq '.messages[] | select(.to == "agent1")'
```

### Export conversation data
```bash
curl -s http://127.0.0.1:8090/api/monitor/conversations | jq . > conversations.json
```

## 🔐 Security Notes

- The monitoring API is accessible without authentication (in development)
- In production, add authentication to `/api/monitor/*` endpoints
- Dashboard runs on http://127.0.0.1:8090 (localhost only)
- For CORS: The dashboard is served from the same origin as the API

## 📱 Mobile Access

To access from other machines:

```bash
# Instead of http://127.0.0.1:8090
# Use your machine IP:
open http://192.168.1.100:8090
```

Note: Make sure firewall allows port 8090.
