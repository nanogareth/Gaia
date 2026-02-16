---
description: "Evening reflection — summarizes the day, flags incomplete items, drafts tomorrow's priorities"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash"]
---

# /gaia-reflect — Evening Reflection

Summarize the day's accomplishments against the morning plan, flag incomplete items, and draft preliminary priorities for tomorrow.

## Steps

1. **Read today's plan** — Read `temporal/today.md` to understand what was planned.

2. **Read today's journal** — Read `journal/YYYY/MM/YYYY-MM-DD.md` (using today's date: $CURRENT_DATE) for any entries added during the day.

3. **Read all domain files** — Use `Glob` to find `domains/*.md`, then `Read` each one. Check "Recent Activity" for today's entries to understand what actually happened.

4. **Generate reflection** — Assess accomplishments vs plan. For each planned priority, determine: completed, partially done, or not started.

5. **Append reflection to journal** — Add the following section to today's journal entry (`journal/YYYY/MM/YYYY-MM-DD.md`):

```markdown
## Evening Reflection

### Accomplishments

<!-- What got done today, referencing planned priorities where applicable -->

### Incomplete

<!-- What didn't get done and brief reason why -->

### Carry Forward

<!-- Specific items to carry into tomorrow's plan -->

### Reflection

<!-- Brief narrative: how the day went, energy, observations -->
```

6. **Update today.md** — Append a reflection summary to `temporal/today.md`:

```markdown
---

## Reflection (Evening)

**Completed:** X of Y planned priorities
**Carry-forward:** list of items
**Tomorrow's preliminary focus:** top 2-3 items
```

7. **Commit changes** — Stage the updated files and commit:
   ```
   git add temporal/today.md journal/
   git commit -m "reflect: evening reflection for YYYY-MM-DD"
   ```

## Guidelines

- Be honest about what didn't get done — the goal is clarity, not optimism
- Carry-forward items should be specific enough to slot directly into tomorrow's plan
- If a priority was dropped intentionally (not just forgotten), note why — that's useful context
- Keep the reflection concise — 1-2 sentences per item is plenty
- Use real dates, not template placeholders
