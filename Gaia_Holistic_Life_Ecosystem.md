# Gaia: Holistic Life Management Ecosystem

## Architecture Specification v0.3

**Author:** Gareth Clarke
**Date:** 2026-03-14
**Status:** Operational — Phases 0–2 complete, Phase 3–4 in progress

---

## 1. Vision

A meta-management system that orchestrates existing tools (Claude.ai, Claude Code, Obsidian, GitHub, Google Calendar) into a unified, cross-device system for managing all domains of life: work, research, health, finances, learning, creativity, relationships, scheduling, goals, and business ideas.

The system does not build custom backends. It treats Claude (across all interfaces) as the intelligence layer and GitHub as the canonical state store, with Obsidian as the primary human interface for reading and light editing across devices.

---

## 2. Design Principles

1. **GitHub is the source of truth.** All state lives in version-controlled files. Every change is traceable.
2. **Obsidian is the window.** Full read-write sync via Git plugin. State files use YAML frontmatter + Markdown body — native to Obsidian's properties system.
3. **Claude is the intelligence.** Claude Code (desktop), Claude.ai (any device), and Claude's memory system collectively provide the reasoning, planning, and reflection layer.
4. **Orchestrate, don't build.** Prefer existing MCPs, plugins, skills, and hooks over custom infrastructure.
5. **Graceful degradation.** Every device gets the best experience it can support. Mobile gets read/edit/ideate. Desktop gets full agentic capability.
6. **Temporal awareness.** The system adapts its behaviour to time of day and context — morning planning, active work support, evening reflection.

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 5: TEMPORAL                         │
│         Morning Planning · Active Support · Evening Review   │
│         (Claude Code commands + Claude.ai prompts)           │
├─────────────────────────────────────────────────────────────┤
│                    LAYER 4: INTERFACE                        │
│  Desktop: Claude Code    Mobile: Obsidian    Any: Claude.ai  │
│  (full agentic)          (read/write/ideate)  (memory-aware) │
├─────────────────────────────────────────────────────────────┤
│                    LAYER 3: INTEGRATION                      │
│     MCPs · Hooks · Skills · Google Calendar · GitHub API     │
├─────────────────────────────────────────────────────────────┤
│                    LAYER 2: DOMAIN MODULES                   │
│  Health · Finance · Languages · Social · Creative · Calendar │
│  Goals · Work Projects · AI Projects · Business Ideas        │
├─────────────────────────────────────────────────────────────┤
│                    LAYER 1: STATE STORE                      │
│              GitHub: Gaia (central index)                 │
│              + distributed project repos                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Layer 1 — State Store

### 4.1 Central Index Repo: `Gaia`

This repo contains no application code. It is pure state, configuration, and cross-references.

```
Gaia/
├── CLAUDE.md                          # Claude Code project instructions
├── Gaia_Holistic_Life_Ecosystem.md    # This architecture spec
├── manifest.yaml                      # Registry of all connected repos
├── .mcp.json                          # MCP server configuration (project scope)
├── .claudeignore                      # Files excluded from Claude context
│
├── domains/                           # Domain state files (all 10 populated)
│   ├── health.md
│   ├── finances.md
│   ├── languages.md
│   ├── social.md
│   ├── creative.md
│   ├── calendar.md
│   ├── goals.md
│   ├── work-projects.md
│   ├── ai-projects.md
│   └── business-ideas.md
│
├── temporal/                          # Scheduling + reflection
│   ├── today.md                       # Today's plan (regenerated each morning)
│   ├── weekly-review.md               # Rolling weekly summary
│   ├── monthly-review.md              # Rolling monthly summary
│   └── templates/
│       ├── morning-plan.md
│       ├── evening-reflection.md
│       └── weekly-review.md
│
├── journal/                           # Daily logs (append-only)
│   └── 2026/
│       └── 02/
│           ├── 2026-02-15.md
│           └── ...
│
├── dashboards/                        # Aggregated views for Obsidian (Dataview)
│   ├── overview.md                    # Cross-domain summary
│   ├── active-projects.md             # All active work across domains
│   └── upcoming.md                    # Next 7 days across all domains
│
└── .claude/                           # Claude Code configuration
    ├── commands/                      # gaia-* slash commands (8 commands)
    │   ├── gaia-plan.md
    │   ├── gaia-reflect.md
    │   ├── gaia-status.md
    │   ├── gaia-update.md
    │   ├── gaia-review.md
    │   ├── gaia-inbox.md
    │   ├── gaia-link.md
    │   └── gaia-sync.md
    ├── hooks/
    │   └── session-start.ps1          # SessionStart context injection
    ├── settings.json                  # Project hooks config (SessionStart, PreToolUse)
    └── settings.local.json            # Local settings (gitignored)
```

### 4.2 Manifest (Connected Repos Registry)

```yaml
# manifest.yaml
repos:
  - name: MiniLang
    github: gareth/minilang
    domain: ai-projects
    status: active
    description: Compositional generalization research

  - name: SET
    github: gareth/spatial-equivariant-transformer
    domain: ai-projects
    status: active
    description: Spatial Equivariant Transformer for 3D reasoning

  - name: 3D-Viz-MCP
    github: gareth/3d-viz-mcp
    domain: ai-projects
    status: active
    description: 3D visualization MCP server for LLM agents

  - name: FlowForge
    github: gareth/flowforge
    domain: work-projects
    status: active
    description: GitHub project scaffolding tool

  - name: Edify
    github: gareth/edify
    domain: work-projects
    status: active
    description: AI learning content generator

  - name: obsidian-gaia-plugin
    github: gareth/obsidian-gaia-plugin
    domain: ai-projects
    status: active
    description: Obsidian plugin providing visual UI for Gaia ecosystem
```

### 4.3 Domain State File Schema

Every domain file follows the same structure:

```markdown
---
domain: health
updated: 2026-02-10T08:30:00Z
updated_by: claude-code-hook
status: active
review_cycle: weekly
next_review: 2026-02-14
tags: [personal, wellbeing]
---

# Health & Fitness

## Current State

<!-- Brief narrative of where things stand right now -->

## Active Goals

<!-- What you're working toward, with measurable targets where possible -->

## Habits & Routines

<!-- Recurring commitments and their current adherence -->

## Recent Activity

<!-- Auto-appended by hooks — last 5-10 relevant entries -->

## Next Actions

<!-- Concrete next steps, ideally with dates -->

## Notes

<!-- Freeform — ideas, observations, things to revisit -->

## Links

<!-- Cross-references to other domains, repos, or resources -->
```

---

## 5. Layer 2 — Domain Modules

### 5.1 Domain Definitions

Each domain has specific concerns but follows the universal schema above.

| Domain                 | Type          | State Location              | Linked Repos            |
| ---------------------- | ------------- | --------------------------- | ----------------------- |
| Health & Fitness       | Personal      | `domains/health.md`         | —                       |
| Finances & Investments | Personal      | `domains/finances.md`       | —                       |
| Language Learning      | Personal      | `domains/languages.md`      | —                       |
| Relationships & Social | Personal      | `domains/social.md`         | —                       |
| Creative Projects      | Personal      | `domains/creative.md`       | —                       |
| Calendar & Scheduling  | Cross-cutting | `domains/calendar.md`       | —                       |
| Goals & Reflection     | Cross-cutting | `domains/goals.md`          | —                       |
| Work Projects          | Professional  | `domains/work-projects.md`  | Multiple (via manifest) |
| AI/Research Projects   | Professional  | `domains/ai-projects.md`    | Multiple (via manifest) |
| Business Ideas         | Professional  | `domains/business-ideas.md` | —                       |

### 5.2 Cross-Domain References

Domain files can reference each other using standard markdown links. Obsidian will render these as navigable wikilinks if configured.

Example in `domains/health.md`:

```markdown
## Links

- Energy levels affecting [work productivity](work-projects.md#current-state)
- Exercise schedule synced with [calendar](calendar.md)
- Weight target linked to [Q1 goals](../goals.md#q1-2026)
```

### 5.3 Work & AI Projects — Distributed State

For domains with linked repos, the domain file in `Gaia` contains summary state only. Detailed project state lives in each repo's own `CLAUDE.md` or project docs. The domain file acts as an index:

```markdown
---
domain: ai-projects
updated: 2026-02-10
---

# AI & Research Projects

## Active

### MiniLang

- **Repo:** [gareth/minilang](https://github.com/gareth/minilang)
- **Phase:** Experimental sweeps — testing grokking at extended training epochs
- **Last session:** 2026-02-09 — analysed persistence diagram transitions across layers
- **Next:** Run 1000-epoch training, compare topological signatures
- **Blockers:** None

### Spatial Equivariant Transformer

- **Repo:** [gareth/set](https://github.com/gareth/set)
- **Phase:** Foundation — implementing SE(3) equivariant layers
- **Last session:** 2026-02-08 — completed codebase scaffolding with TDD baseline
- **Next:** Stage 1 backbone validation on ShapeNet
- **Blockers:** Need to download ShapeNet subset

## Backlog

<!-- Ideas not yet started -->

## Completed / Archived

<!-- With dates and links to final outputs -->
```

---

## 6. Layer 3 — Integration

### 6.1 Claude Code Hooks

#### SessionStart — Context Injection (project-level)

**Fires:** Every session start/resume/compact in the Gaia repo (configured in `.claude/settings.json`).

**Implementation:** `.claude/hooks/session-start.ps1` (PowerShell)

Injects into Claude's context:
- Today's plan summary (first 20 lines of `temporal/today.md`)
- Domain snapshot: `domain`, `status`, `updated`, `next_review` from each `domains/*.md` frontmatter
- Flags any domains with overdue `next_review`

#### PreToolUse — Write Protocol Enforcement (project-level)

**Fires:** Before any `Edit` or `Write` tool call in the Gaia repo (configured in `.claude/settings.json`).

**Implementation:** Prompt-type hook (inline in settings, no script file).

Checks if an edit to a `domains/*.md` file removes or overwrites existing entries in `## Recent Activity`. Blocks destructive edits, allows appends.

#### SessionEnd — Post-Session Sync (global) — NOT YET WIRED

**Status:** The script exists at `~/.claude/hooks/gaia-session-sync.ps1` but is **not configured** in `~/.claude/settings.json` hooks. Needs a `SessionEnd` entry in global settings to fire automatically.

**Implementation:** `~/.claude/hooks/gaia-session-sync.ps1` (PowerShell)

**Intended behaviour:**

1. Reads `cwd` from session input
2. Checks `manifest.yaml` to see if `cwd` matches a registered project
3. If no match → exits silently
4. If match:
   - Pulls latest Gaia state (`git pull --rebase`)
   - Appends to `domains/<domain>.md` Recent Activity: `- **[YYYY-MM-DD]** <project>: <last commit msg>`
   - Updates frontmatter `updated` timestamp and `updated_by: claude-code-hook`
   - Appends to `temporal/today.md` under `## Session Log`
   - Commits and pushes
5. On push failure → writes to `.pending/<timestamp>.md` for manual retry

**Conflict avoidance strategy:**

- Hook always pulls before writing
- Hook only modifies specific sections (Recent Activity, Next Actions, frontmatter timestamps)
- Uses append-only pattern for Recent Activity (no overwrites)
- If a merge conflict is detected, the hook stages the update as a `.pending` file and flags it for manual resolution

### 6.2 MCP Servers

| MCP                 | Purpose                                      | Status      | Scope   |
| ------------------- | -------------------------------------------- | ----------- | ------- |
| GitHub MCP          | Repo status, issues, PRs across all projects | Configured  | User    |
| Google Calendar MCP | Read/write calendar events for scheduling    | Configured  | Project |
| Serena              | Semantic code analysis and editing           | Configured  | Plugin  |

### 6.3 Claude Code Commands

#### `gaia-` Prefixed Commands

All 8 commands are implemented as markdown prompt files in `.claude/commands/` and invoked via `/gaia-<command>`.

| Command         | Args                | Description                                                                            |
| --------------- | ------------------- | -------------------------------------------------------------------------------------- |
| `/gaia-plan`    | —                   | Morning planning: reads all domains + calendar (via Google Calendar MCP), generates `temporal/today.md` |
| `/gaia-reflect` | —                   | Evening reflection: summarizes day vs plan, flags carry-forward items                  |
| `/gaia-status`  | `[domain]`          | Show current state of one domain or summary table (+ GitHub pulse for project domains) |
| `/gaia-update`  | `<domain>`          | Interactive walk-through of a domain's editable sections                               |
| `/gaia-review`  | `<weekly\|monthly>` | Generate periodic review from journal entries, domain activity, and GitHub data        |
| `/gaia-inbox`   | `<note text>`       | Route freeform text to the appropriate domain's Notes section                          |
| `/gaia-link`    | `<project>`         | Register a new repo in `manifest.yaml` and link it to a domain                         |
| `/gaia-sync`    | `[summary]`         | Manual session sync — update domain state after working in a project repo              |

**Behaviour notes:**
- `/gaia-plan` and `/gaia-reflect` commit changes automatically
- `/gaia-status` is read-only — safe to run anytime
- `/gaia-update` uses interactive prompts; never touches Recent Activity
- `/gaia-sync` works from **outside** the Gaia repo (from a project repo) and pushes after committing
- All write commands follow the write protocol: pull before write, append-only for Recent Activity
- All MCP-dependent features degrade gracefully if MCP auth is unavailable

### 6.4 Claude.ai Integration

Claude.ai participates in the system through two channels:

1. **Memory system:** Automatically loaded context about active projects, goals, and preferences. Already partially configured. Should be kept in sync with `Gaia` state (manual periodic review).

2. **Past chat search:** Enables continuity across Claude.ai conversations. The Gaia system doesn't replace this — it complements it by providing structured state that chat history alone can't maintain.

**Claude.ai's role in the system:**

- Mobile-friendly interface for reviewing state, ideating, and making decisions
- Can suggest updates that get manually pushed to GitHub (or automated via a future MCP)
- Morning planning and evening reflection conversations that reference the structured state
- The "thinking partner" layer — less about state management, more about reasoning over state

---

## 7. Layer 4 — Interface

### 7.1 Device Matrix

| Device          | Primary Tools                              | Capabilities                            | Typical Use                     |
| --------------- | ------------------------------------------ | --------------------------------------- | ------------------------------- |
| Windows Desktop | Claude Code + VS Code, Obsidian, GitHub    | Full agentic: code, hooks, MCPs, skills | Deep work, coding, system admin |
| Windows Laptop  | Claude Code + VS Code, Obsidian, GitHub    | Full agentic (same as desktop)          | Portable deep work              |
| iPad            | Obsidian (Git sync), Claude.ai, GitHub web | Read/write state, ideate, plan          | Review, light editing, ideation |
| Android         | Obsidian (Git sync), Claude.ai, GitHub app | Read/write state, ideate, capture       | Quick capture, mobile review    |

### 7.2 Obsidian Configuration

Gaia is accessible within the Obsidian vault (Alexandria) via a directory junction: `C:\Vaults\Alexandria\Gaia\` → `C:\GitHub\Gaia\`.

**Required Obsidian plugins:**

- **Obsidian Git** — automatic pull/push on configurable intervals
- **Dataview** — query YAML frontmatter across domain files for dashboard views
- **Templater** — template-driven file creation (morning plan, journal entries, new project entries)
- **Calendar** — visual navigation of journal entries
- **Gaia Plugin** — custom plugin providing domain dashboard, quick-edit, and mobile-optimised UI (see §7.3)

**Git sync settings (conflict mitigation):**

- Auto-pull interval: 5 minutes
- Auto-push interval: 10 minutes (offset from pull to reduce collision window)
- Pull before push: always
- Merge strategy: default (manual resolution on conflict)
- `.gitignore`: exclude `.obsidian/workspace.json` and other local-only config

**Conflict resolution protocol:**

- Claude Code hooks use append-only writes to "Recent Activity" sections
- Obsidian edits are typically to "Current State", "Goals", "Notes" sections
- Different edit targets minimise collision probability
- On conflict: `.pending` files from hooks are flagged for manual merge in Obsidian

### 7.3 Custom Obsidian Plugin (Gaia Plugin)

**Source:** `C:\GitHub\obsidian-gaia-plugin\` (registered in `manifest.yaml`)
**Install path:** `C:\Vaults\Alexandria\.obsidian\plugins\gaia\`
**Stack:** TypeScript + Svelte 5 + esbuild, `isDesktopOnly: false` (mobile-compatible)
**Build:** `npm run build` → copies `main.js`, `manifest.json`, `styles.css` to install path

**Features:**
- Domain dashboard view with status overview
- Quick-edit for editable domain sections (respects write protocol — Recent Activity is read-only)
- Mobile-optimised UI (16px font inputs to prevent iOS zoom)
- File reactivity via `onGaiaChange()` event bus, scoped to Gaia folder, debounced 500ms
- Theme-compatible using Obsidian CSS variables

**Architecture notes:**
- View state passing uses `setState()` on ItemView + `pendingDomain` on plugin instance for synchronous pre-setState
- `MarkdownRenderer.render()` needs a `Component` instance for lifecycle — create, load, then unload on cleanup
- Write protocol enforced at both UI layer (no edit button for Recent Activity) and service layer (strips non-editable sections)

### 7.4 Dashboard Views (Obsidian Dataview)

Example Dataview query for `dashboards/overview.md`:

````markdown
## All Domains — Last Updated

```dataview
TABLE updated AS "Last Updated", status AS "Status", next_review AS "Next Review"
FROM "domains"
SORT updated DESC
```

## Overdue Reviews

```dataview
TABLE domain AS "Domain", next_review AS "Due"
FROM "domains"
WHERE next_review < date(today)
SORT next_review ASC
```
````

---

## 8. Layer 5 — Temporal Awareness

### 8.1 Daily Rhythm

The system adapts to time of day. This is implemented through Claude Code commands and Claude.ai conversation patterns, not a custom scheduler.

#### Morning Planning (via `/gaia-plan` or Claude.ai conversation)

1. Pull latest state from all domains
2. Check Google Calendar for today's commitments
3. Review yesterday's incomplete items (`temporal/today.md` from previous day)
4. Review active goals and deadlines across domains
5. Generate prioritised plan for the day
6. Write to `temporal/today.md` and `journal/YYYY/MM/YYYY-MM-DD.md`

#### Active Work Support (via hooks and skills)

1. Post-session hooks keep state current throughout the day
2. Claude Code skill can be queried mid-session for cross-domain context
3. Claude.ai conversations can reference structured state for decisions

#### Evening Reflection (via `/gaia-reflect` or Claude.ai conversation)

1. Review today's plan against actual activity (from hook-generated logs)
2. Summarise accomplishments and note incomplete items
3. Flag items that need to carry forward
4. Optionally update domain "Current State" narratives
5. Draft preliminary priorities for tomorrow
6. Append reflection to journal entry

### 8.2 Periodic Reviews

| Cycle     | Trigger                             | Scope                                        | Output                              |
| --------- | ----------------------------------- | -------------------------------------------- | ----------------------------------- |
| Daily     | Morning `/gaia-plan`                | All domains, today's calendar                | `temporal/today.md` + journal entry |
| Weekly    | Sunday `/gaia-review weekly`        | All domains, week's journal entries          | `temporal/weekly-review.md`         |
| Monthly   | 1st of month `/gaia-review monthly` | All domains, month's weeklies, goal progress | `temporal/monthly-review.md`        |
| Quarterly | Manual                              | Goal reassessment, domain priority shifts    | Updated `domains/goals.md`          |

---

## 9. Data Flow

### 9.1 Write Paths (How State Gets Updated)

```
Claude Code session in any project
  → post-session hook fires
  → hook identifies domain via manifest
  → pulls Gaia, updates domain file + today.md
  → commits and pushes

Obsidian edit (any device)
  → user edits domain file directly
  → Git plugin auto-commits and pushes

Claude.ai conversation
  → user and Claude discuss updates
  → user manually edits in Obsidian or triggers via Claude Code
  → (future: Claude.ai → GitHub MCP direct write)

Google Calendar change
  → Calendar MCP detects change (polled or webhook)
  → Updates domains/calendar.md
  → (future: triggers re-plan if significant schedule change)
```

### 9.2 Read Paths (How State Gets Consumed)

```
Claude Code session starts
  → CLAUDE.md references Gaia repo
  → skill loads relevant domain state
  → full project context + life context available

Claude.ai conversation
  → memory system provides high-level context
  → past chat search provides conversation history
  → user can share specific state files if needed
  → (future: Claude.ai reads from GitHub directly)

Obsidian (any device)
  → Git plugin pulls latest state
  → Dataview renders dashboards
  → user browses/edits directly

Morning/Evening routines
  → Claude reads all domains + calendar + journal
  → generates temporal artifacts (plan, reflection)
```

---

## 10. Implementation Roadmap

### Phase 0: Foundation ✓

- [x] Create `Gaia` GitHub repo with directory structure
- [x] Write initial `CLAUDE.md` for the repo
- [x] Create domain state file templates
- [x] Populate `manifest.yaml` with existing repos
- [x] Write initial state for 2-3 domains (start with most active)
- [x] Configure Obsidian Git sync to `Gaia` repo

### Phase 1: Core Loop ✓

- [x] Implement `gaia-` prefixed Claude Code commands (`/gaia-plan`, `/gaia-reflect`, `/gaia-status`, `/gaia-update`, `/gaia-review`, `/gaia-inbox`, `/gaia-link`, `/gaia-sync`)
- [x] Implement post-session sync hook (basic version — manual trigger first)
- [x] Set up journal structure and morning/evening templates
- [x] Configure Obsidian Dataview dashboards
- [ ] Run the morning/evening cycle manually for 1 week to test

### Phase 2: Automation (partially complete)

- [x] Integrate Google Calendar MCP (project-scope via `.mcp.json`)
- [x] Integrate GitHub MCP for repo status queries (user-scope via CLI)
- [x] Implement conflict detection and `.pending` file protocol
- [x] Populate remaining domain state files (all 10 domains seeded)
- [ ] **Wire SessionEnd hook** — script exists at `~/.claude/hooks/gaia-session-sync.ps1` but is not configured in `~/.claude/settings.json`

### Phase 3: Intelligence (in progress)

- [x] Implement weekly and monthly review commands (`/gaia-review`)
- [x] Implement `/gaia-inbox` for unstructured capture → domain routing
- [ ] Build cross-domain analysis (e.g., "health impacts on productivity" correlations)
- [ ] Tune Claude.ai memory edits to reflect Gaia state
- [ ] Build Obsidian templates (Templater) for common operations

### Phase 4: Refinement (in progress)

- [x] Clean up stale Phase 0 scaffolding (removed `hooks/`, `skills/`, `config/`)
- [x] Seed all domain files with structural content
- [x] Build custom Obsidian plugin (`obsidian-gaia-plugin`) with domain dashboard and quick-edit UI
- [ ] Optimise based on daily use friction
- [ ] Add new domains or split existing ones as needed
- [ ] Explore direct Claude.ai → GitHub write path
- [ ] Investigate fitness/finance API integrations

---

## 11. Answers

1. **Obsidian vault structure:** `Gaia` is a subfolder of an existing vault, Alexandria, in C:\Vaults.

2. **Hook implementation detail:** Claude Code hooks are PowerShell scripts (`.ps1`). Project-level hooks are in `.claude/hooks/` and configured in `.claude/settings.json`. Global hooks are in `~/.claude/hooks/` and configured in `~/.claude/settings.json`. The SessionStart and PreToolUse hooks are wired and operational. The SessionEnd sync hook script exists but needs wiring.

3. **Calendar MCP:** Using `@cocal/google-calendar-mcp` via stdio transport, configured in `.mcp.json`. Requires `GOOGLE_OAUTH_CREDENTIALS` env var.

4. **The correct path is Claude Code → GitHub write path**

5. **Mobile Git reliability:** Via Obsidian Sync.

6. **Privacy and sensitivity:** Some domains (health, finances, relationships) contain sensitive data. The GitHub repo should be private.

7. **Gareth's daily device flow:** The Gaia alarm goes off and presents me with my morning rountine: quote of the day, water and tablets reminder, 5 minute meditation, 10 minute stretching, 15 minute cardio, 20 minute coffee and breakfast with morning personal review of day's line-up and chat with agentic AI for planning and prep. This populates to-do list items, creates drafts of emails and meeting requests, carries out research, populates drafts of documents and schedules time to review each of the outputs. Then I start work and my copilot keeps me on schedule and prepared for each to-do item. It triggers tools to transcribe, diarize and summarise meetings, and schedules follow-up events and to-do items from the summarisations. Out of the blue I have an idea and need to quickly jot it down or sketch it out. Ideas like this are like golddust not just because they are valuable but also because they are shiny (i.e. distracting) and take a lot of work to extract. So I need a super quick way to ideate and label them to associate an idea with the right topics or projects and then to defer further ideation until I have time to dedicate to it -> maybe Create Flow state periods throughout the day/week. Back to work. Getting through the morning's to-dos. A meeting is coming up tomorrow morning - a research project update. My Gaia app has my notes on the project that includes a summary of tasks I have been working on since the last meeting on this project. An LLM has summarised the notes and extracted points to include on the agenda discuss and, given the project context, has drafted some next steps that I can work on in advance of the meeting and/or edit during the meeting tomorrow before sharing with the rest of the group. Product development - pomodoro technique - no work distractions. Integration with MS outlook and teams needed. If some internal contact sends a message via teams or outlook, my Gaia should autorespond, saying what I am currently working on and let them know when I will next have time to review their message. Gaia should also trigger 20 minute timers 5 minute intervals for the duration of the product development phase. Gaia will also need to coordinate ideas boards, mind maps, and track web-based research. Project management - Gaia must have templates and integrations for project ideation, planning, scheduling, resource management, communication, engagement, monitoring and oversight. That way I can use it to manage across all work and personal projects. After work, in the gym, Gaia reminds me what exercise groups we are doing (legs and shoulders; biceps, chest and core or triceps, back and core), it queues up a targeted dynamic warmup, what exercise I need to do next (sets, reps, and weights) and times the reps' concentric and eccentric phases, times rest between sets, tracks actual vs target total volume, and schedules progressive overload, then it guides me through a HIIT cardio routine and stretching program. On the way home I hit the supermarket for groceries, and Gaia guides me on what to buy based on what is in my fridge and store cupboards, then how to cut up fresh produce to prepare the next meals. While preparing dinner, I dictate messages to friends and family for Gaia to send off and Gaia captures details to add to that person's mindmap. After dinner each weekday evening, Gaia reserves 2 hours for personal hobbies and projects, cycling through my range of interests, including drawing, painting, sculpture, reading, learning languages, programming, electronics, modelling. This is the day-to-day functionality of Gaia.

---

## 12. Design Decisions Log

| Decision              | Choice                               | Rationale                                                          | Date       |
| --------------------- | ------------------------------------ | ------------------------------------------------------------------ | ---------- |
| Canonical state store | GitHub (distributed + central index) | Version control, cross-device access, Claude Code native           | 2026-02-10 |
| State file format     | YAML frontmatter + Markdown body     | Native to Obsidian properties, human-readable, machine-parseable   | 2026-02-10 |
| Hook trigger          | Automatic post-session               | Reduces friction, ensures state stays current                      | 2026-02-10 |
| Obsidian coupling     | Full read-write Git sync             | Maximum utility on mobile, native editing experience               | 2026-02-10 |
| Intelligence layer    | Claude (all interfaces)              | No custom ML backend — orchestrate existing capabilities           | 2026-02-10 |
| Cowork                | Excluded (macOS only)                | User is on Windows/iPad/Android — revisit if Windows support ships | 2026-02-10 |
| Vault access          | Directory junction (not submodule)   | `Alexandria\Gaia\` → `C:\GitHub\Gaia\` — simpler than git submodule | 2026-02-15 |
| Obsidian plugin stack | Svelte 5 + TypeScript + esbuild      | Modern reactive framework, mobile-compatible, fast builds          | 2026-02-16 |
| Command prefix        | `gaia-` prefix on all commands       | Avoids collision with built-in Claude Code skills                  | 2026-02-15 |
| Hook language         | PowerShell (`.ps1`)                  | Native on Windows 11, works with Claude Code hook protocol         | 2026-02-16 |
| Write protocol        | Append-only for Recent Activity      | Prevents hook/human edit conflicts; enforced at hook + UI layer    | 2026-02-16 |
