---
description: "Show current state of one or all domains"
argument-hint: "[domain-name]"
allowed-tools: ["Read", "Glob", "Grep"]
---

# /status — Domain Status Overview

Display a formatted summary of domain state. Read-only — no file writes.

**Argument:** `$ARGUMENTS` — optional domain name (e.g., `health`, `finances`, `ai-projects`)

## Behaviour

### If a domain is specified (`$ARGUMENTS` is not empty):

1. Read `domains/$ARGUMENTS.md`
2. Display a formatted summary including:
   - **Status:** from frontmatter
   - **Last updated:** from frontmatter `updated` field
   - **Next review:** from frontmatter `next_review` field
   - **Active Goals:** list from the Active Goals section
   - **Next Actions:** list from the Next Actions section
   - **Recent Activity:** last 5 entries from Recent Activity section
   - **Notes:** any content in the Notes section

Format output as readable markdown with clear headers.

### If no domain is specified:

1. Use `Glob` to find all `domains/*.md` files
2. Read each domain file
3. Display a summary table:

```
| Domain          | Status | Last Updated | Next Review | Key Active Items        |
|-----------------|--------|--------------|-------------|-------------------------|
| health          | active | 2026-02-15   | 2026-02-22  | (first goal or action)  |
| finances        | active | 2026-02-15   | 2026-02-22  | (first goal or action)  |
| ...             | ...    | ...          | ...         | ...                     |
```

4. Below the table, flag any domains where:
   - `next_review` is today or past due
   - `status` is not `active`
   - There are no items in Next Actions (potentially stale)

## Guidelines

- This is **read-only** — do not modify any files
- Extract "Key Active Items" from the first non-empty entry in Active Goals or Next Actions
- If a domain file can't be found, report that clearly rather than failing silently
- Keep output scannable — users invoke this for a quick overview
