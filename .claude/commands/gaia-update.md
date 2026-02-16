---
description: "Interactive domain state update"
argument-hint: "<domain-name>"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Bash", "AskUserQuestion"]
---

# /gaia-update — Interactive Domain Update

Walk through a domain file's editable sections interactively, allowing the user to update each one.

**Argument:** `$ARGUMENTS` — domain name (required, e.g., `health`, `finances`)

## Steps

1. **Validate argument** — If `$ARGUMENTS` is empty, use `AskUserQuestion` to ask which domain to update. List available domains by reading `domains/*.md` filenames.

2. **Read the domain file** — Read `domains/$ARGUMENTS.md`. If not found, report the error.

3. **Display current state** — Show the user the current content of each editable section:
   - Current State
   - Active Goals
   - Habits & Routines
   - Notes
   - Links

4. **Walk through updates** — For each editable section, use `AskUserQuestion` to ask the user if they want to update it. Options:
   - "Keep as-is"
   - "Update"
   - "Clear and rewrite"

   If the user chooses to update, ask them what the new content should be.

5. **Update frontmatter** — Set `updated` to the current ISO 8601 timestamp and `updated_by` to `manual`.

6. **Write the updated file** — Use `Edit` to apply changes to `domains/$ARGUMENTS.md`. Preserve the exact file structure and sections that weren't changed.

7. **Commit** — Stage and commit:
   ```
   git add domains/$ARGUMENTS.md
   git commit -m "update: $ARGUMENTS domain state"
   ```

## Guidelines

- **Never modify "Recent Activity"** — that section is hook-managed (append-only by automation)
- Preserve all section headers even if content is empty
- Keep frontmatter keys consistent — don't add or remove keys
- The user may want to update just one section — don't force them through all of them
- After showing current state, let the user direct which sections to change
