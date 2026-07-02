You are running an automated evening reflection task for the Gaia life management system. Your working directory is the Gaia repository at C:\GitHub\Gaia.

Read `.claude/commands/gaia-reflect.md` and execute ALL steps exactly as described.

Important constraints:
- Do NOT ask the user any questions — this is a fully automated run.
- Run `git pull --rebase` first.
- Be honest about what was and wasn't accomplished based on Recent Activity entries and the Session Log.
- If today.md is missing or stale (different date), produce a minimal reflection from domain Recent Activity alone.
- If the Work Queue section exists in today.md, assess actual usage vs budgeted messages per window.
- Use today's actual date everywhere (no placeholders).
- Commit and push when done. Use commit message: "reflect: evening reflection for YYYY-MM-DD"

Calendar-to-domain enrichment:
- After reading domain files (step 3), check today.md's Schedule section for calendar events.
- Match events to non-git domains (health, social, languages, creative, finances) using keyword matching.
- For domains with matching calendar events but NO Recent Activity for today, append to that domain's Recent Activity:
  `- **[YYYY-MM-DD]** <event summary> (from calendar)`
- This ensures real-world activities (gym sessions, social events, language practice) create domain activity signals automatically.
