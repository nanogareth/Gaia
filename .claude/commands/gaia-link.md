---
description: "Register a new project repo in manifest.yaml"
argument-hint: "<project-name or github-path>"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Bash", "AskUserQuestion"]
---

# /gaia-link — Register a Project Repo

Add a new project repository to `manifest.yaml` and cross-reference it in the appropriate domain file.

**Argument:** `$ARGUMENTS` — project name or GitHub path (e.g., `my-project` or `gareth/my-project`)

## Steps

1. **Read manifest** — Read `manifest.yaml` to check for existing entries and understand the format.

2. **Gather project details** — Use `AskUserQuestion` to collect any missing information. Required fields:
   - **name**: Human-readable project name (pre-fill from `$ARGUMENTS` if possible)
   - **github**: GitHub owner/repo path
   - **domain**: Which domain this project belongs to (show list of available domains from `domains/*.md`)
   - **status**: `active`, `paused`, or `archived` (default: `active`)
   - **description**: One-line description of the project

   If `$ARGUMENTS` already contains enough info (e.g., a full github path), only ask for what's missing.

3. **Check for duplicates** — If a repo with the same `github` path already exists in the manifest, inform the user and ask whether to update or skip.

4. **Append to manifest** — Use `Edit` to add the new entry to `manifest.yaml` under the `repos:` list, following the existing format:

```yaml
- name: ProjectName
  github: owner/repo
  domain: domain-name
  status: active
  description: Brief description
```

5. **Update domain file** — Read `domains/<domain>.md` and append a link to the project in the "## Links" section:

```markdown
- [ProjectName](https://github.com/owner/repo) — Brief description
```

6. **Commit** — Stage and commit:
   ```
   git add manifest.yaml domains/<domain>.md
   git commit -m "link: register <name> in manifest"
   ```

## Guidelines

- Keep manifest entries consistent with the existing format (indentation, field order)
- The github path should be `owner/repo` format without the full URL
- If the user provides just a name, ask for the GitHub path
- Domain links section should use full GitHub URLs for clickability in Obsidian
