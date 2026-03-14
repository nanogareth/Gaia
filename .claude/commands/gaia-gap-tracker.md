---
description: "Gap tracker — reads anthropic-application domain, checks core triad repos, generates progress report"
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

# /gaia-gap-tracker — Weekly Gap Progress Report

Assess progress against the five Anthropic Education Labs application gaps by checking recent commits across the core triad repos and updating the domain file.

## Steps

1. **Read the gap analysis domain** — Read `domains/anthropic-application.md`. Extract the five Active Goals (React/TS depth, frontend polish, consumer scale, public portfolio, published thinking) and any existing progress notes.

2. **Check core triad repos for recent commits** — For each of the three core triad repos, get the last 7 days of commits:
   - **Gaia:** `git log --oneline --since="7 days ago"` (current working directory)
   - **claudecodemeta:** `git -C C:/GitHub/claudecodemeta log --oneline --since="7 days ago"` — if the path doesn't exist, note "not cloned locally" and move on
   - **FlowForge:** `git -C C:/GitHub/FlowForge log --oneline --since="7 days ago"` — same graceful handling

3. **Check additional repos via manifest** — Read `manifest.yaml` to find all registered active repos. For each, use the GitHub MCP to check: last commit date, open PRs, and repo visibility (public/private). If the GitHub MCP is unavailable, skip this step and note "GitHub data: unavailable".

4. **Assess each gap** — For each of the five gaps, produce a status assessment:

   - **React/TypeScript depth:** Recent commits to Gaia Web Dashboard or latex-editor repos. Any new React components or pages created.
   - **Frontend polish:** Qualitative assessment from commit messages — any UI/UX work, animation, responsive design.
   - **Consumer scale:** Essay progress, references to consumer-facing work identified or drafted.
   - **Public portfolio:** List each target repo with current visibility status (public/private) in a table.
   - **Published thinking:** Essay drafts in progress, published URLs, any blog/Substack posts.

5. **Append summary to domain file** — Append a single-line entry to the `## Recent Activity` section of `domains/anthropic-application.md`:
   ```
   - **[YYYY-MM-DD]** Gap Tracker: [1-line summary of overall progress and which gap needs most attention]
   ```

6. **Write detailed report to journal** — Create or append to `journal/YYYY/MM/YYYY-MM-DD.md` (using today's date: $CURRENT_DATE) with:

   ```markdown
   ## Gap Tracker Report

   ### React/TypeScript Depth
   - Commits this week: X
   - Key changes: ...
   - Assessment: [on track / needs attention / blocked]

   ### Frontend Polish
   - Commits this week: X
   - Key changes: ...
   - Assessment: [on track / needs attention / blocked]

   ### Consumer Scale
   - Essay progress: ...
   - Assessment: [on track / needs attention / blocked]

   ### Public Portfolio
   | Repo | Current | Target | Prep Status |
   |------|---------|--------|-------------|
   | claudecodemeta | private | public | [status] |
   | Gaia | private | public | [status] |
   | obsidian-gaia-plugin | private | public | [status] |
   | latex-editor | private | public | [status] |
   | MiniLang | private | public | [status] |
   | FlowForge | private | public | [status] |

   ### Published Thinking
   - Essays drafted: ...
   - Essays published: ...
   - Assessment: [on track / needs attention / blocked]

   ### Overall Assessment
   [2-3 sentence summary. Flag which gap has the least progress and recommend focus areas for the coming week.]
   ```

7. **Commit changes** — Stage and commit:
   ```
   git add domains/anthropic-application.md journal/
   git commit -m "gap-tracker: weekly progress report YYYY-MM-DD"
   ```

## Guidelines

- Be specific and quantitative — commit counts, PR counts, concrete deliverables
- Be honest about lack of progress — the goal is clarity, not optimism
- Flag the gap with the **least progress** prominently in the Overall Assessment
- Recommend specific focus areas for the coming week based on the assessment
- Never prompt for user input — this command must work unattended via Cowork
- If a local repo path doesn't exist, note it clearly and continue with available data
- If the GitHub MCP is unavailable, work from local git data only
- Use real dates, not template placeholders
