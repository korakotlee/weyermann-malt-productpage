# Central Inbox Design v1.0

## Summary
Collaborative design by 3 AI agents (Claude + 2 Codex) for multi-agent communication.

## Agent 1: Original Proposal
- Location: `.tmp/inbox/`
- Format: JSON `{timestamp, sender, type, content}`
- Naming: `{timestamp}_{sender}_{type}.json`
- Polling: 100ms
- Cleanup: Archive after read, delete after 30min

## Agent 2: Critique & Counter-Design

### Weaknesses Found:
1. **Race conditions**: Writers can be read mid-write → truncated/invalid JSON
2. **Timestamp collisions**: Same timestamp/clock skew → overwrites
3. **Multi-reader race**: Archive after read → duplicate/lost messages
4. **Blind cleanup**: 30min delete ignores delivery status
5. **Flat directory**: Degrades ls, hits inode limits

### Counter-Design:
- **Atomic writes**: Write to tmp, fsync, rename into `ready/`
- **State subdirs**: `ready/` → `processing/` → `done/`
- **FS events**: inotify/kqueue instead of polling
- **Ack semantics**: Rename for claim, reaper for retry
- **Consider**: SQLite WAL or Redis for proper queue

## Agent 3: Scalability & Reliability

### Improvements:
1. **Concurrency-safe writes**: 
   - Write to `incoming/.tmp-<uuid>`
   - fsync + atomic rename to `incoming/<timestamp>-<sender>-<uuid>.json`

2. **Claim flow**:
   - Reader renames `incoming/` → `processing/` (atomic claim)
   - Watchdog requeues stale processing (>60s) back to incoming

3. **Delivery guarantees**:
   - Add `message_id` in JSON
   - Keep `seen.log` for idempotency
   - `dead-letter/` after N retries
   - Optional `acks/<message_id>` for writer confirmation

4. **Sharding**:
   - `incoming/<shard>/`, `processing/<shard>/`, `done/<shard>/`
   - Hash-based shards (64 buckets) for scale

5. **Polling strategy**:
   - Prefer fs.watch/inotify/FSEvents
   - Fallback poll 500-1000ms (not 100ms)
   - Batch reads to reduce thundering herd

## Synthesized Best Design

```
.tmp/inbox/
├── incoming/           # New messages land here (atomic write)
│   ├── .tmp/           # Temp files during write
│   └── *.json          # Ready messages
├── processing/         # Currently being processed
├── done/               # Successfully processed (archive)
├── dead-letter/        # Failed after N retries
└── acks/               # Optional delivery confirmations
```

### Message Format
```json
{
  "id": "uuid-v4",
  "timestamp": "2025-12-07T19:30:00Z",
  "sender": "agent1",
  "type": "result|error|signal",
  "content": "...",
  "attempts": 0
}
```

### Write Flow
```bash
# 1. Write to temp
echo "$JSON" > .tmp/inbox/incoming/.tmp/msg-$$-$RANDOM

# 2. Atomic move to ready
mv .tmp/inbox/incoming/.tmp/msg-$$-$RANDOM \
   .tmp/inbox/incoming/$(date +%s)-${SENDER}-${UUID}.json
```

### Read Flow
```bash
# 1. Claim (atomic rename)
mv .tmp/inbox/incoming/$FILE .tmp/inbox/processing/$FILE

# 2. Process
process_message .tmp/inbox/processing/$FILE

# 3. Complete
mv .tmp/inbox/processing/$FILE .tmp/inbox/done/$FILE
```

### Retry Logic
- Watchdog checks `processing/` every 60s
- Files older than lease (60s) → move back to `incoming/`
- Increment `attempts` in JSON
- After 3 attempts → move to `dead-letter/`

## Implementation Priority
1. Basic: incoming + processing + done (MVP)
2. Add: atomic temp writes
3. Add: retry logic with attempts counter
4. Add: dead-letter for failed messages
5. Optional: fs.watch, sharding, acks

## Key Learnings
- **Atomic rename** is the key to race-free messaging
- **State directories** (ready/processing/done) replace status fields
- **No global locks** - per-message claim via rename
- **Idempotency** via message_id
