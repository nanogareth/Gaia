---
description: "Manual session sync — update domain state after working in a project repo"
argument-hint: "[summary of what was done]"
allowed-tools:
  ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "AskUserQuestion"]
---

# /gaia-sync — Manual Session Sync

Update Gaia's domain state after a work session in a project repo. This is the manual precursor to the automatic post-session hook.

**Argument:** `$ARGUMENTS` — optional summary of what was done during the session

## Steps

1. **Determine the project** — Read `manifest.yaml` and try to match the current working directory to a registered project. Check if the CWD path or git remote matches any `github` entry in the manifest.

   If no match is found, use `AskUserQuestion` to ask the user which domain to update (list all available domains).

2. **Get session summary** — If `$ARGUMENTS` is provided, use that as the summary. Otherwise, use `AskUserQuestion` to ask the user what they accomplished in this session.

3. **Pull latest Gaia state** — Run:

   ```
   git -C /c/GitHub/Gaia pull --rebase
   ```

   This ensures we don't overwrite changes made from other devices (e.g., Obsidian mobile sync).

4. **Update the domain file** — Read `domains/<domain>.md` and apply these changes:

   a. **Append to Recent Activity** — Add an entry:

   ```markdown
   - **[YYYY-MM-DD]** <project-name>: <session summary>
   ```

   Insert after existing Recent Activity entries. If the section only has the placeholder comment, replace it.

   b. **Update frontmatter** — Set `updated` to current ISO 8601 timestamp and `updated_by` to `claude-code-hook`.

5. **Update today.md** — Read `temporal/today.md` and append a session entry:

   ```markdown
   - **[HH:MM]** Synced <project-name>: <brief summary>
   ```

   Add under a "## Session Log" section (create if it doesn't exist).

6. **Commit and push** — Stage, commit, and push:
   ```
   git -C /c/GitHub/Gaia add domains/<domain>.md temporal/today.md
   git -C /c/GitHub/Gaia commit -m "sync: <project-name> session update"
   git -C /c/GitHub/Gaia push
   ```

## Guidelines

- This command may be run from **outside** the Gaia repo (from a project repo), so always use `-C /c/GitHub/Gaia` for git operations on Gaia
- The `updated_by` field should be `claude-code-hook` (not `manual`) since this is an automated-style update
- Keep the Recent Activity entry concise — one line summarizing the session
- If git pull has conflicts, do NOT force-resolve — create a `.pending` file and inform the user
- The push at the end ensures Obsidian mobile picks up changes on next sync
