Please create the following 4 scheduled tasks. For each one, use /schedule to set it up.

### Task 1: Gaia Morning Plan
- Name: Gaia Morning Plan
- Description: Generate today's plan with usage-aware work queue
- Frequency: Daily at 07:00
- Model: Sonnet
- Working folder: C:\GitHub\Gaia
- Prompt:
  You are running an automated morning planning task for the Gaia life management system.
  Your working folder is the Gaia repository. Read the command file at `.claude/commands/gaia-plan.md` and execute all steps exactly as described.
  Important: Do NOT ask the user any questions. Always run `git pull --rebase` before writing. If the Google Calendar MCP is unavailable, note "Calendar: unavailable" and continue. If `domains/anthropic-application.md` exists, give its Active Goals priority when building the Work Queue. The Work Queue section should have three 5-hour windows with per-task message budget estimates. Keep the plan concise and actionable. Commit and push when done. Use today's actual date.

### Task 2: Gaia Evening Reflection
- Name: Gaia Evening Reflection
- Description: Compare today's plan vs actual, flag carry-forwards, update journal
- Frequency: Daily at 21:00
- Model: Sonnet
- Working folder: C:\GitHub\Gaia
- Prompt:
  You are running an automated evening reflection task for the Gaia life management system.
  Read `.claude/commands/gaia-reflect.md` and execute all steps. Do NOT ask questions. Run `git pull --rebase` first. Be honest about what was and wasn't accomplished based on Recent Activity entries and the Session Log. If today.md is missing or stale, produce a minimal reflection from domain Recent Activity alone. If the Work Queue section exists in today.md, assess actual usage vs budgeted messages per window. Commit and push when done.

### Task 3: Gaia Weekly Review
- Name: Gaia Weekly Review
- Description: Compile the week's activity into a weekly review
- Frequency: Weekly, Sunday at 10:00
- Model: Opus
- Working folder: C:\GitHub\Gaia
- Prompt:
  You are running an automated weekly review. Read `.claude/commands/gaia-review.md` and execute for a "weekly" review. Do NOT prompt for arguments. The review period is the last 7 days. If GitHub MCP unavailable, skip and note. Focus the Patterns & Observations section on cross-domain themes. Run `git pull --rebase` first. Commit and push when done.

### Task 4: Gaia Gap Tracker
- Name: Gaia Gap Tracker
- Description: Track progress against Anthropic application gaps
- Frequency: Weekly, Monday at 08:00
- Model: Sonnet
- Working folder: C:\GitHub\Gaia
- Prompt:
  You are running an automated gap tracking task. Read `.claude/commands/gaia-gap-tracker.md` and execute all steps. Check repos at C:\GitHub\Gaia, C:\GitHub\claudecodemeta, C:\GitHub\FlowForge. If a path doesn't exist, note it and continue. Be specific and quantitative. Flag which gap needs the most attention. Do NOT ask questions. Run `git pull --rebase` first. Commit and push when done.

Please create all 4 tasks now, one at a time.
