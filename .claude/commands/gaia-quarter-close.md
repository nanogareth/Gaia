---
description: "Close the current quarter and transition goals to the next"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash"]
---

# /gaia-quarter-close — Quarter Transition

Manually close the current quarter in goals.md and set up the next quarter. Run this at or near quarter boundaries.

## Steps

1. **Read goals.md** — Read `domains/goals.md`. Identify the latest quarter section (the last `### Qn YYYY` heading under `## Active Goals`).

2. **Determine the new quarter** — Based on today's date ($CURRENT_DATE), determine the new quarter label (e.g., "Q2 2026") and period (e.g., "Apr-Jun").

3. **Archive the old quarter** — Rename the latest quarter heading from `### Qn YYYY (period)` to `### Qn YYYY (Archived)`.

4. **Create the new quarter section** — Add a new `### Qn+1 YYYY (period)` heading after the archived one.

5. **Carry forward active goals** — For each domain group in the archived quarter:
   - Goals that are NOT struck through (not wrapped in `~~`) are carried forward to the new quarter under the same domain group heading.
   - Goals that ARE struck through are left in the archived section (completed).
   - Goals tagged with `[queued]` are promoted: remove the `[queued]` tag and carry forward as active.
   - Placeholder goals matching `_define in [domain]_` are dropped — do not carry these forward.

6. **Check domain files for queued goals** — Read each `domains/*.md` file. If the `## Active Goals` section contains any lines with `[queued]`, include them in the new quarter under the appropriate domain group (match by domain filename). Remove the `[queued]` tag.

7. **Flag domains with no goals** — After building the new quarter, list any domains that have no goals set. Add a comment under each empty domain group: `- _No goals set — use \`goal:\` in Quick Capture to add_`

8. **Commit** — Stage and commit:
   ```
   git add domains/goals.md
   git commit -m "goals: close Qn, open Qn+1 YYYY"
   ```

## Guidelines

- This is a manual command — ask the user to confirm before making changes if anything looks ambiguous
- Be careful with the archive: never delete goals, only move or tag them
- The new quarter should start clean with only carried-forward and promoted items
- Use real quarter labels: Q1 (Jan-Mar), Q2 (Apr-Jun), Q3 (Jul-Sep), Q4 (Oct-Dec)
