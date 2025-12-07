# MAW Wrapper - Safe Command Execution in Claude Code

## Problem

When running `maw` commands in Claude Code (Bash tool), you get:
```
Error: Exit code 127
(eval):1: command not found: maw
```

**Why?** Claude Code runs commands in isolated subshells that don't have access to the `.envrc` environment functions.

## Solution

Use the **maw-wrapper** script to ensure maw is available before execution.

## Quick Start

### Option 1: Direct Command (Recommended for Claude Code)
```bash
bash .agents/scripts/maw-wrapper.sh hey 2 "message here"
bash .agents/scripts/maw-wrapper.sh send root agent1 "task"
bash .agents/scripts/maw-wrapper.sh zoom 3
```

### Option 2: Environment Variable
```bash
MAW_COMMAND="hey 2 hello" bash .agents/scripts/maw-wrapper.sh
```

### Option 3: Source in Script
```bash
source .agents/scripts/maw-wrapper.sh

# Now use maw_safe function
maw_safe hey 2 "message"
maw_safe send root agent1 "task"
maw_safe stats
```

## How It Works

1. **Detects Working Directory**: Uses `MAW_REPO_ROOT` or current `$PWD`
2. **Sources maw.env.sh**: Loads the MAW environment setup
3. **Verifies maw Available**: Checks if maw function exists
4. **Executes Command**: Runs your command with maw

## In Claude Code Bash Tool

Instead of:
```bash
cd /Users/nat/000-workshop-product-page && maw hey 2 "analyze code"
```

Use:
```bash
bash /Users/nat/000-workshop-product-page/.agents/scripts/maw-wrapper.sh hey 2 "analyze code"
```

Or with absolute path:
```bash
/Users/nat/000-workshop-product-page/.agents/scripts/maw-wrapper.sh hey 2 "analyze code"
```

## Common maw Commands

### Send Message to Agent
```bash
bash .agents/scripts/maw-wrapper.sh hey 2 "implement feature X"
bash .agents/scripts/maw-wrapper.sh hey 3 "run tests"
```

### Start/Attach Session
```bash
bash .agents/scripts/maw-wrapper.sh start
bash .agents/scripts/maw-wrapper.sh attach
```

### Manage Agents
```bash
bash .agents/scripts/maw-wrapper.sh agents create 4
bash .agents/scripts/maw-wrapper.sh remove 4
```

### Navigation
```bash
bash .agents/scripts/maw-wrapper.sh warp 2      # Go to agent 2
bash .agents/scripts/maw-wrapper.sh warp root   # Go to root
```

### Pane Control
```bash
bash .agents/scripts/maw-wrapper.sh zoom 1      # Maximize agent 1
bash .agents/scripts/maw-wrapper.sh clear       # Clear all panes
```

### Synchronization
```bash
bash .agents/scripts/maw-wrapper.sh sync        # Git-based sync
bash .agents/scripts/maw-wrapper.sh sync --files # Quick copy files
```

## Troubleshooting

### "maw.env.sh not found"
```
❌ Error: /path/to/.agents/maw.env.sh not found
```

**Solution**: Make sure you're in the repo root directory:
```bash
cd /Users/nat/000-workshop-product-page
bash .agents/scripts/maw-wrapper.sh hey 2 "message"
```

### "maw command still not available"
```
❌ Error: maw command still not available
```

**Solution**: Check that maw.env.sh is valid:
```bash
cat .agents/maw.env.sh | head -20
```

If it's corrupted, restore from git:
```bash
git checkout .agents/maw.env.sh
```

### Command Not Working
If the wrapped command doesn't work:

1. Test directly first (in terminal with .envrc loaded):
   ```bash
   cd /Users/nat/000-workshop-product-page
   source .envrc
   maw hey 2 "test"
   ```

2. Then use wrapper:
   ```bash
   bash .agents/scripts/maw-wrapper.sh hey 2 "test"
   ```

## Implementation Details

The wrapper script:
1. Sets `MAW_REPO_ROOT` environment variable
2. Sources `.agents/maw.env.sh` to load maw function
3. Verifies `maw` is available via `command -v`
4. Passes all arguments through to `maw`

## For Developers

### Creating a Safe maw Alias
You can create an alias in your shell:
```bash
alias maw-safe='bash /Users/nat/000-workshop-product-page/.agents/scripts/maw-wrapper.sh'

# Then use:
maw-safe hey 2 "message"
```

### In Scripts
Always use the wrapper in automation scripts:
```bash
#!/bin/bash

REPO_ROOT="/Users/nat/000-workshop-product-page"

bash "$REPO_ROOT/.agents/scripts/maw-wrapper.sh" hey 2 "start implementation"
bash "$REPO_ROOT/.agents/scripts/maw-wrapper.sh" start
```

### Absolute vs Relative Paths
- **Use absolute paths** in Claude Code (more reliable)
- **Use relative paths** in shell scripts (more portable)

Absolute:
```bash
bash /Users/nat/000-workshop-product-page/.agents/scripts/maw-wrapper.sh hey 2 "msg"
```

Relative:
```bash
bash .agents/scripts/maw-wrapper.sh hey 2 "msg"
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | maw.env.sh not found or sourcing failed |
| 127 | maw command not available (original error) |

## Performance

- **First call**: ~100ms (sources environment)
- **Subsequent calls**: ~50ms (environment already loaded)

If you need multiple commands, source once:
```bash
source /Users/nat/000-workshop-product-page/.agents/scripts/maw-wrapper.sh
maw_safe hey 2 "first"
maw_safe hey 3 "second"
```

## Security Notes

- The wrapper doesn't modify any system files
- All commands execute with user privileges
- maw commands are unchanged, wrapper just enables execution
- No credential exposure in wrapper code

## Related

- `.agents/maw.env.sh` - Core MAW environment
- `AGENTS.md` - Agent communication guidelines
- `docs/INBOX-MONITORING.md` - Inbox monitoring guide
