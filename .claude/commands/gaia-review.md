---
description: "Generate a weekly or monthly review"
argument-hint: "<weekly|monthly>"
allowed-tools:
  [
    "Read",
    "Write",
    "Edit",
    "Glob",
    "Grep",
    "Bash",
    "mcp__github__search_repositories",
    "mcp__github__list_issues",
    "mcp__github__get_pull_request",
  ]
---

# /gaia-review — Periodic Review Generation

Generate a structured review summarizing activity across all domains for the given period.

**Argument:** `$ARGUMENTS` — `weekly` or `monthly` (required)

## Steps

1. **Validate argument** — If `$ARGUMENTS` is not `weekly` or `monthly`, ask the user which type of review they want.

2. **Determine date range:**
   - `weekly`: last 7 days from today ($CURRENT_DATE)
   - `monthly`: last 30 days from today

3. **Read journal entries for the period** — Use `Glob` to find `journal/YYYY/MM/YYYY-MM-DD.md` files within the date range. Read each one.

4. **Read all domain files** — Use `Glob` for `domains/*.md`, then `Read` each. Focus on Recent Activity entries within the date range.

5. **Pull GitHub activity for registered projects** — Read `manifest.yaml` to find all registered projects. For each active project, use the GitHub MCP to fetch:
   - PRs merged during the review period
   - Issues closed during the review period

   Include this data in the Domain Summary for the relevant domain. If the GitHub MCP is unavailable, skip this step and note "GitHub data: unavailable" in the review.

6. **Read the existing review file** — Read `temporal/weekly-review.md` or `temporal/monthly-review.md` to see the previous review for context.

7. **Generate the review** — Write to the appropriate file:

### Weekly review (`temporal/weekly-review.md`):

```markdown
---
week: YYYY-Www
type: weekly-review
date_generated: YYYY-MM-DD
---

# Weekly Review — YYYY-Www

## Highlights

<!-- Key accomplishments and wins this week -->

## Domain Summary

<!-- Brief status update per domain — only include domains with activity -->

### domain-name

- Activity summary
- Goal progress
- GitHub: X PRs merged, Y issues closed (if applicable)

## Goal Progress

<!-- Progress against active goals across all domains -->

## Patterns & Observations

<!-- Recurring themes, energy patterns, what worked / what didn't -->

## Next Week Focus

<!-- Top priorities and focus areas for next week -->
```

### Monthly review (`temporal/monthly-review.md`):

Same structure but with broader scope and an additional "## Month-over-Month Trends" section.

8. **Commit** — Stage and commit:
   ```
   git add temporal/weekly-review.md  # or monthly-review.md
   git commit -m "review: TYPE review for PERIOD"
   ```

## Guidelines

- Only include domains that had meaningful activity during the period
- Reference specific journal entries or domain changes to ground observations
- Goal progress should be measurable where possible ("3 of 5 sessions completed")
- Patterns section is the most valuable part — look for cross-domain themes
- If no journal entries exist for the period, note that and work from domain file Recent Activity alone
- Use real dates and week numbers, not template placeholders
- GitHub activity provides concrete project metrics — use PR/issue data to enrich domain summaries
