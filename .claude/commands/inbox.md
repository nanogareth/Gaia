---
description: "Route an unstructured note or idea to the appropriate domain file"
argument-hint: "<note text>"
allowed-tools:
  ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "AskUserQuestion"]
---

# /inbox — Route Notes to Domains

Analyse freeform text input and route it to the appropriate domain file's Notes section.

**Argument:** `$ARGUMENTS` — the note or idea to route (required)

## Steps

1. **Validate input** — If `$ARGUMENTS` is empty, ask the user what they want to capture.

2. **Read domain files** — Use `Glob` to find `domains/*.md`, then `Read` each one. Note each domain's:
   - `domain` name from frontmatter
   - `tags` from frontmatter
   - Content themes from Active Goals and Current State

3. **Classify the note** — Determine which domain(s) the input belongs to based on:
   - Keyword matching against domain tags
   - Semantic relevance to domain goals and current state
   - Common associations (e.g., "workout" → health, "invoice" → finances, "Japanese" → languages)

4. **Handle ambiguity** — If the note could belong to multiple domains, use `AskUserQuestion` to ask the user which domain to target. Present the top 2-3 candidates with brief reasoning.

5. **Append to domain file** — Use `Edit` to append the note to the target domain's "## Notes" section:

```markdown
- **[YYYY-MM-DD]** <note text>
```

Insert after any existing notes content but before the next section header. If the Notes section only has the placeholder comment, replace the comment.

6. **Update frontmatter** — Set `updated` to current ISO 8601 timestamp and `updated_by` to `manual`.

7. **Commit** — Stage and commit:
   ```
   git add domains/<domain>.md
   git commit -m "inbox: route note to <domain>"
   ```

## Guidelines

- Preserve the original wording of the note — don't rephrase or summarize
- Add a date prefix so notes have temporal context
- If a note genuinely spans multiple domains, ask whether to add it to multiple files or pick one
- Keep the routing logic transparent — briefly tell the user why you chose that domain
