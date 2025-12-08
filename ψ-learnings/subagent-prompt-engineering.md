# Subagent Prompt Engineering for Haiku

**Created**: 2025-12-08
**Source**: Archiver iteration (v1→v5, 5/10→10/10)
**Model**: claude-haiku (fast, needs precision)

---

## Key Insight

> **Haiku is fast but creative. It needs STRICT templates, not guidelines.**

---

## The Problem

| What We Said | What Haiku Did |
|--------------|----------------|
| "Output a structured report" | Created custom format |
| "Include all files" | Summarized with "..." |
| "Follow the template" | Added extra sections |
| "Be thorough" | Wrote essays |

---

## The Solution: 5 Rules for Haiku Prompts

### 1. COPY-PASTE Templates
```markdown
❌ BAD: "Output in a structured format"
✅ GOOD: "COPY THIS TEMPLATE. Fill in [brackets] only:"
```

### 2. Explicit "DO NOT" Instructions
```markdown
❌ BAD: "Be concise"
✅ GOOD: "DO NOT be creative. DO NOT add extra sections."
```

### 3. Fill-in-the-Blank Format
```markdown
❌ BAD: "List all files with their ages"
✅ GOOD:
| # | Path | Age | Act |
|---|------|-----|-----|
| 1 | [path] | [Xd] | 🗄️ |
```

### 4. Numbered Steps (ALL CAPS)
```markdown
❌ BAD: "First search, then analyze, then output"
✅ GOOD:
STEP 1: Run `ls pattern`
STEP 2: Count files
STEP 3: Create issue with `gh issue create`
STEP 4: COPY template and fill in
```

### 5. Validation Checklist
```markdown
Before finishing:
- [ ] Issue NUMBER returned (not just "created")
- [ ] COUNT: exact number
- [ ] ALL files listed (no "...")
- [ ] Link clearly visible
```

---

## Template Pattern

```markdown
## ⚠️ CRITICAL: COPY THE TEMPLATE EXACTLY

**DO NOT be creative. DO NOT add extra sections.**

### STEP N: COPY THIS TEMPLATE

\`\`\`
[Exact output format here]
📋 Issue: #[NUMBER]
🔗 [URL]

| # | Item | Value |
|---|------|-------|
| 1 | [fill] | [fill] |
\`\`\`

**RULES:**
- Replace [brackets] with real values
- List EVERY item (no "...")
- Use exact icons: 🗄️ = archive, ✅ = keep
```

---

## Iteration Results: Archiver

| Version | Score | Problem | Fix |
|---------|-------|---------|-----|
| v1 | 5/10 | No count, no paths | Added COUNT + PATHS |
| v2 | 8/10 | No table format | Added table template |
| v3 | 7/10 | Too creative | Added "DO NOT" rules |
| v4 | 6/10 | Still creative | Made template stricter |
| v5 | 9/10 | Template followed! | Added visible link border |
| v6 | 10/10 | Perfect | ━━━ border around link |

---

## Subagent Workflow Pattern

```
Subagent (haiku)          Main Agent (opus)
      │                         │
      ├─── Creates Issue ───────┤
      │                         │
      ├─── Returns:             │
      │    - Issue #NUMBER      │
      │    - Link URL           │
      │    - COUNT: N           ├─── Verifies count
      │    - PATHS list         │    (wc -l = N?)
      │                         │
      └─────────────────────────┴─── User decides
```

**Token Efficiency**: Main agent only runs `wc -l`, doesn't re-list files.

---

## Apply to Other Subagents

### context-finder
- Return: File paths + line numbers
- Main agent: Reads specific files

### book-writer
- Return: Exact markdown format
- Template: Chapter headings, word counts

### Any haiku subagent
- COPY template exactly
- DO NOT be creative
- Fill [brackets] only
- Validation checklist

---

## Summary

| Haiku Needs | Not This |
|-------------|----------|
| COPY template | "Output structured" |
| DO NOT be creative | "Be concise" |
| Fill [brackets] | "Include relevant info" |
| STEP 1, STEP 2 | "First..., then..." |
| Exact icons 🗄️ ✅ | "Mark appropriately" |

**Remember**: Haiku is a **template filler**, not a **creative writer**.

---

## Bug: Empty Issue Body

**Problem**: Haiku creates GitHub issue but with minimal body:
```bash
gh issue create --title "..." --body "short description"  # ❌
```

**Fix**: Show FULL template in STEP 3 for issue body:
```bash
gh issue create --title "..." --body "$(cat <<'EOF'
# Full Plan
| # | Path | Age |
|---|------|-----|
| 1 | ... | ... |
EOF
)"
```

**Lesson**: Haiku needs the FULL example, not just "include the plan".
