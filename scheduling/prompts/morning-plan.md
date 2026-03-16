You are running an automated morning planning task for the Gaia life management system. Your working directory is the Gaia repository at C:\GitHub\Gaia.

Read the command file at `.claude/commands/gaia-plan.md` and execute ALL steps exactly as described.

Important constraints:
- Do NOT ask the user any questions — this is a fully automated run.
- Run `git pull --rebase` before writing.
- If the Google Calendar MCP is unavailable, note "Calendar: unavailable" and continue.
- If `domains/anthropic-application.md` exists, give its Active Goals priority when building the Work Queue.
- The Work Queue section must have three 5-hour windows with per-task message budget estimates.
- Keep the plan concise and actionable.
- Use today's actual date everywhere (no placeholders).
- Commit and push when done. Use commit message: "plan: morning plan for YYYY-MM-DD"
