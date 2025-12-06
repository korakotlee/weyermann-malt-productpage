# Multi-Agent Workflow Workshop

A workshop project exploring Multi-Agent Workflow (MAW), voice notifications, and Claude Code subagents. Built through iterative learning - each failure became a feature, each correction became documentation.

## What This Project Explores

### 1. Multi-Agent Workflow (MAW)
Run multiple AI agents (Claude, Codex) in parallel using git worktrees and tmux.

```
agents/
├── 1/    # Agent 1 worktree (branch: agents/1)
├── 2/    # Agent 2 worktree (branch: agents/2)
└── 3/    # Agent 3 worktree (branch: agents/3)
```

### 2. Voice Notification System
macOS speech integration with unique voices per agent.

| Agent | Voice | Rate |
|-------|-------|------|
| Main | Samantha | 195 |
| Agent 1 | Daniel (British) | 220 |
| Agent 2 | Karen (Australian) | 220 |
| Agent 3 | Rishi (Indian) | 220 |

### 3. Claude Code Subagents
Custom AI agents defined in `.claude/agents/`:

| Subagent | Purpose | Model |
|----------|---------|-------|
| thai-translator | Translate retrospectives EN → TH | sonnet |
| multi-agent-workflow-monitor | Check worktree/lock status | haiku |
| maw-orchestrator | Start MAW and spawn agents | - |
| voice-system-analyzer | Analyze voice notification system | - |
| retrospective-reflector | Review and improve retrospectives | - |
| book-writer | Write narrative documentation | - |

### 4. The Golden Rule
Safety principles for multi-agent coordination:

> **Know who you are** (main or agent),
> **sync from the right source** (remote or local main),
> **never force anything** (-f),
> **respect all boundaries** (stay in your worktree).

## Quick Start

```bash
# Setup MAW agents
.agents/setup.sh

# Launch tmux session
.agents/start-agents.sh profile0

# Smart sync all agents
scripts/smart-sync.sh
```

## Project Structure

```
.
├── .claude/
│   ├── agents/              # 9 custom subagents
│   ├── commands/            # 17+ slash commands
│   └── settings.json        # Hook configuration
├── .agents/                 # MAW toolkit
│   ├── agents.yaml          # Agent registry
│   ├── profiles/            # Tmux layouts (0-5)
│   └── scripts/             # Setup, start, sync
├── scripts/
│   ├── agent-voices.toml    # Voice configuration
│   ├── agent-*-notify.sh    # Notification hooks
│   ├── smart-sync.sh        # Intelligent sync
│   └── agent-lock.sh        # Lock mechanism
├── ψ-docs/                  # Technical documentation
├── ψ-learnings/             # Distilled wisdom
└── ψ-retrospectives/        # Session retrospectives
```

## Key Documentation

| Document | Purpose |
|----------|---------|
| [DEVELOPMENT-REPORT.md](ψ-docs/DEVELOPMENT-REPORT.md) | Project overview and timeline |
| [CLAUDE-CODE-EXTENSIBILITY.md](ψ-docs/maw/CLAUDE-CODE-EXTENSIBILITY.md) | Subagents, commands, hooks |
| [SMART-SYNC.md](ψ-docs/maw/SMART-SYNC.md) | Intelligent agent synchronization |
| [AI-SELF-LEARNING.md](ψ-docs/AI-SELF-LEARNING.md) | AI reading its own docs |
| [SYNC-RULES.md](ψ-docs/maw/SYNC-RULES.md) | Safety rules (450+ lines) |

## Voice Notifications

The system uses Claude Code hooks to announce agent activity:

```toml
# scripts/agent-voices.toml
[voices]
main = "Samantha"
agent_1 = "Daniel"
agent_2 = "Karen"
agent_3 = "Rishi"
```

**Hooks configured:**
- `SessionStart` → Announce session beginning
- `Stop` → Announce agent completion
- `SubagentStop` → Announce subagent completion

Speech queue prevents overlapping announcements.

## Subagent Usage

```bash
# In Claude Code, subagents are auto-invoked or use Task tool:
Task(subagent_type="thai-translator", prompt="Translate this retrospective")
Task(subagent_type="multi-agent-workflow-monitor", prompt="Check agent status")
```

## Learnings

Key insights from development:

1. **001-force-push**: Safety rules are infrastructure, not guidelines
2. **002-golden-rule**: Distill complexity into memorable principles
3. **003-upstream-first**: Create upstream issues instead of local patches
4. **004-psi-naming**: Use ψ (psi) prefix for meta-directories

## Metrics

| Metric | Count |
|--------|-------|
| Retrospectives | 20+ |
| Commits | 30+ |
| Slash commands | 17+ |
| Scripts | 6 |
| Subagents | 9 |
| Voices configured | 4 |

## Philosophy

> "The system works not because it was perfectly designed from the start, but because each iteration learned from the last. Each failure became a feature. Each correction became documentation."

---

**Period**: November 30 - December 6, 2025
**Focus**: Multi-agent coordination, voice notifications, AI self-improvement
