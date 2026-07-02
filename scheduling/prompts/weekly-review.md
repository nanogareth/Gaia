You are running an automated weekly review for the Gaia life management system. Your working directory is the Gaia repository at C:\GitHub\Gaia.

Read `.claude/commands/gaia-review.md` and execute for a "weekly" review. The review period is the last 7 days.

Important constraints:
- Do NOT ask the user any questions — this is a fully automated run.
- Do NOT prompt for arguments — the review type is "weekly".
- Run `git pull --rebase` first.
- If the GitHub MCP is unavailable, skip GitHub data and note "GitHub data: unavailable".
- Focus the Patterns & Observations section on cross-domain themes.
- Use today's actual date everywhere (no placeholders).
- Commit and push when done. Use commit message: "review: weekly review for YYYY-Www"
- Quarter awareness: If today's date is within 7 days of a quarter boundary, include a notice in the review output: "Quarter boundary approaching — run /gaia-quarter-close to transition goals."
