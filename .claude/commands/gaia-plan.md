---
description: "Morning planning — reads all domains + calendar, generates today's plan"
allowed-tools:
  [
    "Read",
    "Write",
    "Edit",
    "Glob",
    "Grep",
    "Bash",
    "mcp__google-calendar__list_events",
  ]
---

# /gaia-plan — Morning Planning

Generate a prioritized daily plan by synthesizing all domain states, calendar events, and carry-forward items.

## Steps

1. **Read all domain files** — Use `Glob` to find `domains/*.md`, then `Read` each one. Extract: Active Goals, Next Actions, Habits & Routines, and any items with today's date.

2. **Check for carry-forward items** — Read `temporal/today.md`. If it exists and has content from a previous day, extract any items marked incomplete or listed under "Carry-Forward".

3. **Check today's calendar** — Use the Google Calendar MCP `list_events` tool to fetch today's events. Include them in the Schedule section of the daily plan. If the MCP is unavailable (not configured or auth expired), skip this step and note "Calendar: unavailable" in the Schedule section.

4. **Check today's journal** — Read `journal/YYYY/MM/YYYY-MM-DD.md` (using today's date: $CURRENT_DATE). If it exists, note any pre-existing entries.

5. **Read manifest for project context** — Read `manifest.yaml` to understand active projects and their domains.

6. **Build the usage-aware work queue** — Using the manifest, domain priorities (especially `anthropic-application.md` if it exists), carry-forward items, and calendar events, construct a work queue structured around three 5-hour rolling windows (~225 messages each from the Max 5x plan). Scheduling principles:
   - Front-load token-intensive tasks (Claude Code dev sessions with large codebases) into Windows 1–2
   - Cowork morning plan (07:00) and evening reflect (21:00) are fixed cheap tasks (~5 msgs each)
   - Calendar events constrain scheduling — block those time slots
   - Estimate per-task message budgets: light (5–10 msgs), medium (30–60 msgs), heavy (80–120 msgs)
   - Source project priorities from `anthropic-application.md` Active Goals (gap-closing work takes priority), manifest active projects, and carry-forward items
   - The work queue is a recommendation, not a rigid schedule — the user adjusts as the day unfolds

7. **Generate the daily plan** — Write `temporal/today.md` with this structure:

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

## Work Queue

### Window 1 (07:00–12:00)
- **07:00** Cowork: Morning plan (auto, ~5 msgs)
- **[time]** [Interface]: [Project] — [specific task] (~N msgs)
- Budget: ~X/225 messages. Reserve Y for ad-hoc.

### Window 2 (12:00–17:00)
- **[time]** [Interface]: [Project] — [specific task] (~N msgs)
- Budget: ~X/225 messages.

### Window 3 (17:00–22:00)
- **21:00** Cowork: Evening reflection (auto, ~5 msgs)
- Budget: ~X/225 messages. Light window by design.

### Weekly Budget
- Reset: [date or "unknown — check manually"]
- Estimated weekly consumption: [assessment based on planned tasks]
- Recommendation: [model guidance if approaching weekly cap]

## Carry-Forward

<!-- Items incomplete from yesterday, if any -->

## Domain Snapshots

<!-- One-line status per active domain -->

## Notes

<!-- Context, reminders, or things to keep in mind -->
```

8. **Create/update journal entry** — Write to `journal/YYYY/MM/YYYY-MM-DD.md` (create year/month directories if needed). If the file doesn't exist, create it with:

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

9. **Commit plan** — Stage `temporal/today.md` and the journal entry, then commit:
   ```
   git add temporal/today.md journal/
   git commit -m "plan: morning plan for YYYY-MM-DD"
   ```

10. **Write domain Next Actions** — For each priority in the Priorities section, group by `[domain]` tag. For each domain that has at least one priority:
   - Read `domains/<domain>.md`
   - Use `Edit` to replace the content between `## Next Actions` and the next `##` heading with clean priority text
   - Strip from the priority text: `**bold markers**`, `+N XP` annotations, carry-forward counts, overdue warnings, and plan-specific language after em-dashes (e.g., "— 8th carry, Q1 ends TODAY")
   - Keep only the actionable task description
   - Do a fresh `git pull --rebase` before starting the batch of domain edits
   - If an `Edit` fails for any domain (file not found, section not found), skip it and continue — Next Actions are transient and regenerated daily

11. **Commit domain updates** — Stage and commit domain changes separately:
   ```
   git add domains/
   git commit -m "plan: update domain next-actions for YYYY-MM-DD"
   ```
   Push both commits. If the push fails, the domain updates are lost — this is acceptable since they're transient.

## Guidelines

- Priorities should be **actionable and specific**, not vague ("Review PR for MiniLang" not "Do some AI work")
- Surface items from domains whose `next_review` date is today or past due
- If a domain has items in "Next Actions" with dates, include any due today
- Keep the plan concise — it's a working document, not a report
- Use real dates, not template placeholders
- Calendar events should appear in the Schedule section with times, providing structure for the day
