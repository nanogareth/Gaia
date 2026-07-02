# Project Briefs: Core Triad

**Date:** 2026-03-14  
**Context:** These briefs define the immediate development direction for each project in the core triad. They are designed to be handed to Claude Code as context for implementation sessions.

---

## Brief 1: Gaia — Coordination Layer & Holistic Project Manager

### Current State

Operational Phases 0–2, Phases 3–4 in progress. 10 domain modules, 8 gaia-* Claude Code commands, custom Obsidian plugin (TypeScript/Svelte 5), SessionStart + PreToolUse hooks wired, SessionEnd hook exists but not wired. Cowork scheduled tasks not yet configured (Windows support was unknown at design time — now confirmed available since 2026-02-10).

### The Shift

Gaia was designed as a life management system with Claude as the intelligence layer. It needs to evolve into an active **coordination layer that schedules and orchestrates Claude Code usage across multiple projects and worktrees**, maximising subscription utilisation.

This means Gaia becomes a project manager that doesn't just track what you're working on — it decides what Claude Code should work on next, provisions the context for that work, and captures the results back into its state store.

### Immediate Development Priorities

#### 1. Wire Cowork Scheduled Tasks

Now that Cowork runs on Windows with full feature parity, set up:

- **Morning Plan** (daily, 07:00) — reads all domains + calendar, generates `temporal/today.md`, prioritises which projects need Claude Code time today
- **Evening Reflect** (daily, 21:00) — compares plan vs actual, flags carry-forwards, appends to journal
- **Weekly Review** (Sunday, 10:00) — compiles week's journal entries into `temporal/weekly-review.md`
- **Gap Tracker** (Monday, 08:00) — reads `domains/anthropic-application.md`, checks recent commits, generates progress report

Point Cowork at the Gaia folder. Use `/schedule` in a Cowork task to configure each one.

#### 2. Wire the SessionEnd Hook

The script exists at `~/.claude/hooks/gaia-session-sync.ps1`. It needs a `SessionEnd` entry in `~/.claude/settings.json` (global scope). This is the highest-impact single automation gap — every Claude Code session across every project will automatically feed back into Gaia's state.

#### 3. Usage-Aware Multi-Project Scheduling

The Max 5x plan has two interacting constraints that Gaia must be aware of:

**5-hour rolling window:** ~225 messages per window. The clock starts on first prompt and resets only when a new message is sent after the 5 hours lapse. All interfaces (Claude.ai, Claude Code, Cowork) draw from the same pool.

**Weekly quota:** A separate weekly cap shared across all models and platforms. Resets on a 7-day rolling basis.

Gaia's `/gaia-plan` should output a **usage-aware Claude Code work queue** structured around these reset cycles:

```markdown
## Today's Work Queue

### Window 1 (07:00–12:00) — triggered by morning plan Cowork task
- **07:00** Cowork: Morning plan generation (low token cost, ~5 msgs)
- **07:15** Claude Code: claudecodemeta — implement cross-interface protocol (~60 msgs)
- **09:00** Claude.ai: Essay drafting / ideation (~20 msgs)
- **10:00** Claude Code: Gaia Web Dashboard — build domain overview component (~80 msgs)
- Budget: ~165/225 messages. Reserve 60 for ad-hoc needs.

### Window 2 (12:00–17:00) — first prompt at 12:01 starts new window
- **12:01** Claude Code: Industrious React port — value chain grid (~100 msgs)
- **14:00** Claude Code: FlowForge — CLAUDE.md generator (~60 msgs)
- Budget: ~160/225 messages.

### Window 3 (17:00–22:00) — first prompt at 17:01
- **17:01** Claude Code: Lighter tasks, PR reviews, test fixes (~40 msgs)
- **19:00** Personal project time (creative, languages, etc.)
- **21:00** Cowork: Evening reflection (low token cost, ~5 msgs)
- Budget: ~45/225 messages. Light window by design.

### Weekly Budget Tracker
- Weekly reset: [date]
- Estimated weekly consumption: [X/Y messages used]
- Opus-heavy tasks remaining this week: [list]
- Recommendation: [shift model to Sonnet for X tasks if approaching weekly cap]
```

Key scheduling principles:

- **Time the first prompt of each window deliberately.** Don't waste a window start on a trivial question — batch the first prompt with a substantive task.
- **Front-load token-intensive work** (Claude Code dev sessions with large codebases) into the first two windows. Keep the evening window light.
- **Cowork scheduled tasks are cheap but still draw from the pool.** Morning plan and evening reflect should be concise. Don't schedule Cowork tasks that trigger heavy web search or multi-step file operations during a window you need for Claude Code.
- **Track weekly consumption.** The weekly cap is the harder constraint. If approaching it mid-week, shift to Sonnet for routine tasks, reserve Opus for high-value work.
- **Coordinate across subscriptions.** Work subscription handles InnoGlobal tasks. Personal subscription handles the triad + personal domains. Never cross the streams.

This doesn't need to be fully automated initially. Start with `/gaia-plan` outputting a structured work queue with window boundaries in `temporal/today.md` that you follow manually. Automation (Cowork triggering Claude Code sessions at window boundaries) is a Phase 4+ goal.

#### 4. Cross-Interface State Sharing

Gaia's domain state files are the natural bridge between Claude Code, Claude.ai, and Cowork. When you start a Claude.ai conversation about a project, you should be able to reference the current state from Gaia without manually copying it. Options:

- **Short term:** Claude.ai memory edits kept in sync with Gaia's top-level state (manual periodic sync — `/gaia-sync-memory` command that generates memory edit suggestions)
- **Medium term:** Cowork scheduled task that reads Gaia state and updates Claude.ai memory edits via the API (if Anthropic exposes memory management in Cowork's tool access)
- **Long term:** Gaia Web Dashboard as the unified interface that all three Claude surfaces can reference

#### 5. Sandbox and Permissions Architecture

To safely run Claude Code across multiple worktrees (potentially in parallel with Cowork), all projects need to move to sandboxed environments with restricted permissions. Define:

- A standard directory structure for sandboxed projects (`C:\Sandboxes\<project>\` with `.claude/settings.json` restricting file access to that sandbox)
- Permission templates per project type (research = read-heavy, minimal write; active dev = full read-write within sandbox; Gaia = cross-sandbox read, single-sandbox write)
- A manifest entry format in Gaia that records each project's sandbox path and permission level

This connects directly to claudecodemeta (which needs to operate across sandboxes) and FlowForge (which provisions new sandboxes).

### What Success Looks Like (2 weeks)

- Cowork scheduled tasks running daily (morning plan + evening reflect)
- SessionEnd hook wired and operational across all active projects
- `temporal/today.md` includes a structured Claude Code work queue
- `domains/anthropic-application.md` actively tracked
- At least 3 projects migrated to sandbox structure

---

## Brief 2: claudecodemeta — Cross-Interface Memory for Claude

### Current State

Active TypeScript repo. Provides persistent corrections memory, relational user profiles, cross-instance blackboard store, deferred reasoning threads, conversation compression, epistemic tagging, and calibration tracking. Operates as a Claude Code plugin.

### The Landscape

The session-to-session persistence problem within Claude Code is increasingly well-served:

- **Built-in Session Memory** (Anthropic, auto on Max plans) — structured summaries injected at session start
- **Built-in Auto Memory** (v2.1.59+) — Claude takes project-level notes in `~/.claude/projects/<project>/memory/`
- **claude-mem** (thedotmack, AGPL) — 3-tier progressive compression, AI summarisation, web viewer, SQLite. Most mature third-party solution. Supports 28 languages.
- **memsearch/ccplugin** (Zilliz, MIT) — lightweight, decoupled, one markdown file per day, CLI works independently of Claude Code
- **cortex** (hjertefolger) — local SQLite + embeddings, zero cloud
- **Feature request #27298** — layered memory with keyword-indexed topic files

**What none of them solve:** memory sharing across Claude Code ↔ Claude.ai ↔ Claude Cowork. Every existing solution is scoped within Claude Code sessions. Claude.ai (web/mobile) and Cowork (desktop agent) are completely disconnected.

### The Distinctive Position

claudecodemeta's unique value is not session-to-session persistence (that's becoming commoditised). It's **cross-interface memory**: making knowledge from Claude Code sessions available to Claude.ai conversations and Cowork tasks, and vice versa.

The specific capabilities that differentiate:

1. **Relational user profiles** — persistent understanding of the user that should be consistent whether they're in Claude Code, Claude.ai, or Cowork
2. **Cross-instance blackboard store** — a shared scratchpad that any Claude interface can read from and write to
3. **Epistemic tagging** — tracking what Claude knows, what it's uncertain about, and what it's been corrected on, across all interfaces
4. **Deferred reasoning threads** — questions or analyses that were started in one interface and should be continued in another

### Immediate Development Priorities

#### 1. Define the Cross-Interface Protocol

Design a simple, file-based protocol for sharing memory between Claude Code and other interfaces:

- **Write path (Claude Code → shared state):** On session end, claudecodemeta writes a structured summary to a known location (e.g., `~/.claudecodemeta/shared/` or a GitHub repo). Format: YAML frontmatter + markdown, similar to Gaia domain files.
- **Read path (Claude.ai ← shared state):** Claude.ai can't read files directly. Options: (a) Cowork scheduled task reads shared state and updates Claude.ai memory edits, (b) user uploads summary files to Claude.ai conversations, (c) Gaia Web Dashboard exposes the shared state in a browser.
- **Read path (Cowork ← shared state):** Cowork can read local files. Point Cowork tasks at the shared state directory. Cowork context files (markdown files in the working folder) are read automatically at task start — this is the most natural integration path.

#### 2. Integrate with Gaia

claudecodemeta and Gaia currently operate independently. They should share state:

- claudecodemeta's cross-instance blackboard should be readable by Gaia's `/gaia-status` and `/gaia-plan` commands
- Gaia's domain state should be available to claudecodemeta's context injection (so Claude Code sessions in any project can access life-level context)
- The connection point is the filesystem: claudecodemeta writes to a known path, Gaia reads it (and vice versa). No API needed initially.

#### 3. Sandbox-Aware Operation

As projects move to sandboxed environments (per Gaia brief), claudecodemeta needs to operate correctly across sandboxes:

- Global memory (user profile, corrections, epistemic state) lives outside any sandbox
- Project-specific memory lives within the sandbox
- claudecodemeta must distinguish between global and project-scoped state
- Permission model: claudecodemeta can read globally, write only to its own state directory and the current project's sandbox

#### 4. Prepare for Public Release

- Write README that frames the problem clearly: "existing solutions solve Claude Code → Claude Code persistence. This solves Claude Code ↔ Claude.ai ↔ Cowork memory sharing."
- Add MIT or Apache 2.0 licence (differentiate from claude-mem's AGPL)
- Security audit: ensure no secrets, API keys, or personal data in the repo
- Document the cross-interface protocol so others can build on it

### What Success Looks Like (2 weeks)

- Cross-interface protocol defined and documented
- Shared state directory operational, with Cowork able to read context from Claude Code sessions
- Integration point with Gaia established (at least read-only)
- Repo public with clear README and licence
- Essay #1 ("The Fragmented Claude Problem") published, referencing the repo

---

## Brief 3: FlowForge — Project Context Bootstrapping

### Current State

Active repo. React Native (Expo) mobile companion app + Vercel serverless API for GitHub OAuth + self-hosted Node.js server for remote Claude Code access. Original purpose: provision GitHub repos pre-configured with Claude Code extension enabled and CLAUDE.md templates.

### What's Changed

- Claude Code remote session continuation now partially addresses the "repo must be pre-provisioned" pain
- Claude Code's auto memory and Session Memory reduce the "blank slate" problem for returning to existing projects
- The real remaining pain is **context bootstrapping for new projects**: setting up CLAUDE.md with good defaults, configuring hooks (especially Gaia integration hooks), wiring MCP servers, registering in Gaia's manifest, setting up sandbox permissions, and ensuring claudecodemeta can operate in the new project's context

### The Reframed Scope

FlowForge becomes the tool that answers: **"I'm starting work on a new project. Set everything up so Claude Code, Gaia, and claudecodemeta all know about it from the first session."**

Concretely, FlowForge should:

1. **Create or clone a repo** with appropriate directory structure
2. **Generate CLAUDE.md** from a template, pre-populated with:
   - Project description and goals (from user input or Gaia domain state)
   - Standard hook configurations (SessionStart context injection, SessionEnd Gaia sync)
   - MCP server declarations relevant to the project type
   - References to claudecodemeta's shared state
3. **Set up the sandbox** — create the directory structure under `C:\Sandboxes\<project>\`, configure `.claude/settings.json` with appropriate permission restrictions
4. **Register in Gaia** — add the project to `manifest.yaml`, create or update the relevant domain file, and set initial state
5. **Configure claudecodemeta** — ensure the project-level memory directory exists and is wired to the global state
6. **Optionally create a git worktree** for parallel development (useful when Claude Code is working on one branch while you work on another)

### Implementation Questions

- **CLI tool vs mobile app vs Claude Code skill?** The original FlowForge was a mobile app. But bootstrapping a project is a desktop activity — you need filesystem access, git operations, and Claude Code configuration. A Claude Code skill or CLI tool may be more natural than a mobile app. The mobile companion could still exist for quick "I had an idea for a project, capture it" moments, but the heavy lifting happens on desktop.
- **Integration with `claude code --init`?** Claude Code has its own project initialisation. FlowForge should complement this, not replace it. Run `claude code --init` first, then layer FlowForge's Gaia/claudecodemeta integration on top.

### Immediate Development Priorities

#### 1. Decide the Primary Interface

Assess whether FlowForge's core value is best delivered as:
- A Claude Code slash command (`/flowforge-init`)
- A standalone CLI tool (`flowforge init <project-name>`)
- A Cowork task template ("Set up a new project called X in domain Y")
- The existing React Native mobile app (for capture) + one of the above (for execution)

Recommendation: start with a Claude Code slash command. It's the lowest-friction path and doesn't require a separate install. The mobile app becomes a secondary capture interface.

#### 2. Build the CLAUDE.md Generator

Template-based, with slots for:
- Project metadata (name, domain, description)
- Hook configuration (Gaia SessionEnd sync, claudecodemeta integration)
- MCP servers (GitHub, Google Calendar, project-specific)
- Coding standards and preferences (pulled from claudecodemeta's global state)
- Import references to shared context files

Templates should be versioned and stored in the FlowForge repo.

#### 3. Build the Sandbox Provisioner

- Create directory structure under sandboxes root
- Generate `.claude/settings.json` with permission restrictions
- Set up git worktree if requested
- Verify Claude Code can operate within the sandbox

#### 4. Build the Gaia Registrar

- Add entry to `manifest.yaml`
- Create or update domain file with initial project state
- Trigger `/gaia-sync` to propagate the new project across the ecosystem

### What Success Looks Like (2 weeks)

- `/flowforge-init` command operational in Claude Code
- Successfully bootstraps a new project with CLAUDE.md, hooks, sandbox, and Gaia registration in one command
- At least 3 existing projects retroactively registered and sandboxed via FlowForge
- Repo public with README explaining the context bootstrapping problem

---

## Cross-Cutting Concerns

### Subscription Maximisation Strategy

Max 5x ($100/mo) has two interlocking constraints: **~225 messages per 5-hour rolling window** and a **weekly quota** (shared across all models and all interfaces). Claude.ai, Claude Code, and Cowork all draw from the same pool.

**Daily rhythm aligned to reset windows:**

- **Window 1 (morning):** Cowork morning plan (cheap) → Claude Code deep work → Claude.ai ideation. Front-load the most token-intensive tasks.
- **Window 2 (afternoon):** Start with a deliberate first prompt at window boundary. Second Claude Code dev block.
- **Window 3 (evening):** Light usage. Personal projects, reflection. Cowork evening reflect (cheap).

**Weekly rhythm aligned to quota reset:**

- **Days 1–3 after reset:** Intensive Claude Code development. Opus for complex tasks.
- **Days 4–5:** Monitor weekly consumption. If approaching cap, shift to Sonnet for routine tasks.
- **Days 6–7:** Reserve for lighter work, ideation, essay writing. Let the buffer rebuild before next reset.

**Interface cost hierarchy (cheapest to most expensive):**

1. **Claude.ai chat** — short context, no tool use. Use for ideation, planning, quick questions.
2. **Cowork scheduled tasks** — moderate cost but each task is a full session. Keep scheduled tasks concise and focused.
3. **Claude Code** — heaviest cost. Large system prompts, file contexts, multi-step tool use. Use deliberately.

**Gaia's role:** The morning plan (`/gaia-plan`) outputs a structured work queue with window boundaries, per-task message budget estimates, and model recommendations. Evening reflect tracks actual usage vs budget. Weekly review surfaces consumption patterns for adjustment.

### Security Model

Moving to sandboxes is a security upgrade. Currently, Claude Code in any project has access to the entire filesystem. After migration:

- Each project operates within its sandbox only
- claudecodemeta has global read access (for cross-project memory) but writes only to its own state directory
- Gaia has read access to all sandboxes (for status aggregation) and write access to its own repo only
- Sensitive domains (health, finances) in Gaia remain in a private repo, never exposed to project-level Claude Code sessions

### The Public Narrative

These three briefs, taken together, tell a coherent story:

> "Claude's context is fragile and interface-scoped. I built three tools to fix this: one that orchestrates my entire life and development workflow (Gaia), one that gives Claude persistent memory across all its interfaces (claudecodemeta), and one that bootstraps new projects with full context from day one (FlowForge). They're separate tools that share state through the filesystem, and they may converge into a single ecosystem as the boundaries clarify."

This is the story to tell in the essays and the Anthropic application. It demonstrates deep product understanding, real engineering, and direct relevance to Education Labs' mission.
