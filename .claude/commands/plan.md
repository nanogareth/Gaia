---
description: "Morning planning — reads all domains + calendar, generates today's plan"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash"]
---

# /plan — Morning Planning

Generate a prioritized daily plan by synthesizing all domain states, calendar events, and carry-forward items.

## Steps

1. **Read all domain files** — Use `Glob` to find `domains/*.md`, then `Read` each one. Extract: Active Goals, Next Actions, Habits & Routines, and any items with today's date.

2. **Check for carry-forward items** — Read `temporal/today.md`. If it exists and has content from a previous day, extract any items marked incomplete or listed under "Carry-Forward".

3. **Check today's journal** — Read `journal/YYYY/MM/YYYY-MM-DD.md` (using today's date: $CURRENT_DATE). If it exists, note any pre-existing entries.

4. **Read manifest for project context** — Read `manifest.yaml` to understand active projects and their domains.

5. **Generate the daily plan** — Write `temporal/today.md` with this structure:

```markdown
---
date: YYYY-MM-DD
type: morning-plan
---

# Today's Plan — YYYY-MM-DD

## Schedule

<!-- Calendar events and time blocks for the day -->

## Priorities

<!-- Top 3-5 priorities, ranked by importance. Each should reference its source domain. -->

1. **[domain]** Priority item
2. **[domain]** Priority item
3. **[domain]** Priority item

## Carry-Forward

<!-- Items incomplete from yesterday, if any -->

## Domain Snapshots

<!-- One-line status per active domain -->

## Notes

<!-- Context, reminders, or things to keep in mind -->
```

6. **Create/update journal entry** — Write to `journal/YYYY/MM/YYYY-MM-DD.md` (create year/month directories if needed). If the file doesn't exist, create it with:

```markdown
---
date: YYYY-MM-DD
type: journal
---

# YYYY-MM-DD

## Morning Plan Summary

<!-- Brief summary of the plan -->
```

If it already exists, append a "## Morning Plan Summary" section.

7. **Commit changes** — Stage `temporal/today.md` and the journal entry, then commit:
   ```
   git add temporal/today.md journal/
   git commit -m "plan: morning plan for YYYY-MM-DD"
   ```

## Guidelines

- Priorities should be **actionable and specific**, not vague ("Review PR for MiniLang" not "Do some AI work")
- Surface items from domains whose `next_review` date is today or past due
- If a domain has items in "Next Actions" with dates, include any due today
- Keep the plan concise — it's a working document, not a report
- Use real dates, not template placeholders
