# Vision: A Systematic Programme for Anthropic Education Labs

**Author:** Gareth Clarke  
**Date:** 2026-03-14  
**Status:** Draft — for review and iteration

---

## 1. The Thesis

The Design Engineer, AI Capability Development role at Anthropic's Education Labs sits at the intersection of three things: building polished consumer-facing products (React/TypeScript), understanding how people develop skill with AI tools, and caring deeply about the craft of human-AI interaction.

The gap analysis identified five shortfalls: React/TypeScript depth, frontend polish, consumer scale, public portfolio, and published thinking on capability development. But these gaps exist against a background of extraordinary strength: a PhD in materials science, 140 GitHub repositories spanning AI agents, manufacturing simulation, workforce intelligence, spectroscopy, and life management systems, deep experience with Claude's own tooling (skills, hooks, MCPs, plugins), and a working meta-management system (Gaia) that orchestrates Claude across every domain of life.

The problem is not capability. It is visibility and stack alignment. The work exists but nobody can see it, and the frontend layer is in Vue/Svelte/Power Apps rather than React/TypeScript.

This document maps a programme to close all five gaps simultaneously, using a single coherent methodology: build in public, using Claude's own tools, while documenting the process of becoming more capable with AI — which is itself the core question Education Labs exists to study.

---

## 2. The Project Landscape

### 2.1 Flagship Projects (Build in Public)

These projects become public repositories with READMEs, write-ups, and visible commit history.

#### The Core Triad

These three projects are architecturally separate but address the same underlying problem from different angles: **Claude's context is fragile, session-scoped, and requires manual labour to maintain.** They start as independent repos and converge later once the natural boundaries reveal themselves through use.

| Project | What It Is | The Problem It Solves | Primary Gap Addressed | Stack |
|---------|-----------|----------------------|----------------------|-------|
| **Gaia** (+ Web Dashboard) | Holistic life management ecosystem — GitHub as state store, Obsidian as window, Claude as intelligence layer. 10 domain modules, 8 Claude Code commands, custom Obsidian plugin, temporal awareness system. The **web dashboard** is a new React/TypeScript interface providing browser-based read/write access to domain state, temporal views, and cross-domain analytics. | Claude doesn't know what I'm working on across my life. Context must be re-established every session. | Gap 1 (React/TS via dashboard), Gap 2 (frontend polish), Gap 4 (public portfolio), Gap 5 (published thinking on capability development) | Markdown/YAML, TypeScript (Obsidian plugin), PowerShell hooks. Dashboard: React, TypeScript, Next.js, Tailwind |
| **claudecodemeta** | Claude Code plugin providing persistent corrections memory, relational user profiles, cross-instance blackboard store, deferred reasoning threads, conversation compression, epistemic tagging, and calibration tracking. | Claude Code doesn't remember corrections, preferences, or relational context across sessions. | Gap 4 (public portfolio). Directly relevant to Anthropic's own ecosystem. | TypeScript |
| **FlowForge** (reframed) | Originally: React Native mobile app for provisioning GitHub repos pre-configured for Claude Code. The repo provisioning pain has been partially addressed by CC remote session continuation. Reframed focus: **project scaffolding and context bootstrapping** — setting up CLAUDE.md, hooks, MCP configs, skills, and directory structure with good defaults for any new project. The "new project onboarding" problem remains unsolved. | Getting a new project properly wired for Claude Code (CLAUDE.md, hooks, MCPs, manifest registration) is too much friction. | Gap 1 (React/TS if mobile companion retained), Gap 4 (public portfolio) | React Native, Expo, Node.js. Scope to be refined. |

**Convergence hypothesis:** These three may eventually merge into a single ecosystem where Gaia is the state layer, claudecodemeta is the persistence engine, and FlowForge is the bootstrapper. But this is a hypothesis to be tested through use, not an upfront architectural commitment.

#### Other Flagship Projects

| Project | What It Is | Primary Gap Addressed | Stack |
|---------|-----------|----------------------|-------|
| **Industrious** | Industry 1.0→5.0 business simulation game. React port of existing SvelteKit frontend, Python/FastAPI backend retained. | Gap 1: React/TypeScript. Gap 2: Frontend polish/motion/interaction. Gap 4: Public portfolio. | React, TypeScript, Python, FastAPI |

### 2.2 Supporting Projects (Selective Public Visibility)

These provide evidence of depth and breadth but don't need full build-in-public treatment.

| Project | What It Is | Visibility Action |
|---------|-----------|------------------|
| **latex-editor** | Browser-based LaTeX editor — React, TypeScript, Turborepo, Monaco, Yjs collab, multi-provider AI chat | Make public. Already demonstrates production React/TypeScript. Clean up README. |
| **MiniLang / SMsRS / LLMexperiments** | Transformer research — compositional generalisation, novel architectures | Make public. Shows research depth relevant to understanding AI. |
| **metis** | Deep-tech investment research platform | Keep private (financial sensitivity). Reference in essays. |

### 2.3 Projects to Reference (Not Make Public)

DMSA, SmartLabs platform, smartlabs-web, Edify, skills-4sight, Eudaemon, and other InnoGlobal IP. Discussed in essays and applications as evidence of domain expertise, but repos remain private. Edify (AI-powered educational content generation) and skills-4sight (full-stack labour market intelligence with Vue 3/FastAPI/Neo4j) are particularly relevant to Education Labs and should feature prominently in the application narrative, even though the code can't be shown. If a clean-room React rebuild of the Edify concept is pursued on personal time, it becomes a separate project with no IP constraint.

---

## 3. The Methodology: Claude-Orchestrated Capability Development

This is the meta-contribution — the thing that makes this programme more than a portfolio sprint. The methodology itself is the artefact most relevant to Education Labs.

### 3.1 Core Idea

Use Gaia (the life management system) as both:

1. **The orchestration layer** that schedules, tracks, and reflects on gap-closing work
2. **The primary case study** of how a person systematically develops new capabilities using AI

Every morning, Gaia generates a plan. Every evening, Gaia generates a reflection. Every week, Gaia generates a review. The gap analysis is a domain file in Gaia. Progress against it is tracked, reflected on, and published.

### 3.2 The Scheduling Layer

**Primary: Windows Task Scheduler + Claude Code CLI (`claude -p`)**

Cowork scheduled tasks were the initial approach but have two limitations: no programmatic task creation (UI-only), and require machine awake with Claude Desktop open. The scheduling layer now uses Windows Task Scheduler, which supports wake timers, catch-up runs, and programmatic management. See `scheduling/` directory for implementation.

| Task | Cadence | Model | What It Does |
|------|---------|-------|-------------|
| Morning Plan | Daily, 07:00 | Sonnet | Reads all domain state, checks calendar, generates `temporal/today.md` with usage-aware work queue |
| Evening Reflect | Daily, 21:00 | Sonnet | Compares plan vs actual, flags carry-forwards, appends to journal |
| Weekly Review | Sunday, 10:00 | Opus | Compiles week's journal entries into `temporal/weekly-review.md` |
| Gap Tracker | Monday, 08:00 | Sonnet | Reads gap analysis domain file, checks recent commits across flagship repos, generates progress report |

Cowork scheduled tasks remain registered as a supplementary fallback. The `Anthropic Watch` task (weekly web search) is planned but not yet implemented in the Task Scheduler layer.

**Claude Code `/loop` (development workflow):**

| Task | Interval | What It Does |
|------|----------|-------------|
| PR Monitor | 2h | During active dev: checks open PRs, runs linting, flags issues |
| Test Runner | On commit | Runs test suite after significant changes |

**GitHub Actions (CI/CD — runs regardless of device state):**

| Action | Trigger | What It Does |
|--------|---------|-------------|
| Build Check | Push to main | Ensures all flagship projects build cleanly |
| Deploy Preview | PR opened | Deploys preview of web projects (Vercel/Netlify) |

### 3.3 The Two-Subscription Separation

| Subscription | Scope | Scheduling Tools | Primary Interface |
|-------------|-------|------------------|-------------------|
| **Personal** (Max, $100/mo) | Gaia, Industrious, claudecodemeta, Gaia Web Dashboard, essays, portfolio work, personal domains | Cowork scheduled tasks, Claude Code `/loop` | Claude Desktop (Windows), Claude.ai, Claude Code CLI |
| **Work** (InnoGlobal) | Skills4EII, ONE4ALL, DMSA, Edify (work version), SmartLabs, Eudaemon | Work-scoped Cowork tasks | Separate Claude Desktop profile / Claude.ai |

The boundary is clean: InnoGlobal IP stays on the work subscription. Personal projects, the Anthropic application prep, and building-in-public all happen on personal.

---

## 4. The Writing Programme

Gap 5 requires published thinking. The build-in-public process generates the material naturally.

### 4.1 Planned Pieces

| # | Title (Working) | Core Argument | Derived From |
|---|----------------|--------------|-------------|
| 1 | **"The Fragmented Claude Problem"** | AI capability development is hampered by disconnected contexts across Claude's interfaces. Here's how I built bridges with claudecodemeta and Gaia. | claudecodemeta + Gaia's cross-interface architecture |
| 2 | **"Gaia: Using AI to Systematically Develop Capabilities With AI"** | The meta-methodology — how a structured life-management system built on Claude became the vehicle for closing specific professional gaps. A documented experiment in AI-orchestrated self-improvement. | The programme itself, written while living it |
| 3 | **"People Are the Key Enabling Technology"** | Connecting DMSA/Skills4sight findings to Education Labs' mission — why capability development at the human-AI interface matters more than model improvements. | Skills4EII + webinar prep + gap analysis |
| 4 | **"Capability-Driven Design"** | How designing for skill development (Edify, SmartLabs, DMSA) differs from designing for task completion, and what that means for AI product design. | InnoGlobal portfolio (discussed, not shown — all three are InnoGlobal IP) |
| 5 | **"The Context Bootstrapping Problem"** | Why getting a new project properly set up for agentic AI (CLAUDE.md, hooks, MCPs, memory) is an unsolved UX problem, and what FlowForge's evolution reveals about it. | FlowForge reframing |

### 4.2 Publication Venue

Personal site or Substack. Cross-post summaries to LinkedIn. Each piece links to the relevant public repo.

---

## 5. Sequencing: The Programme in Weeks

### Week 0 (Now): Foundation

- [x] **Update Gaia design decision:** ~~Cowork~~ → Windows Task Scheduler + Claude Code CLI (`claude -p`). Architecture updated in CLAUDE.md and this doc.
- [x] **Set up scheduled tasks:** 4 tasks registered via `scheduling/setup-scheduler.ps1`. Cowork tasks kept as supplementary.
- [x] **Wire the SessionEnd hook** — Global hook in `~/.claude/settings.json`, auto-syncs project sessions to Gaia state.
- [x] **Security audit:** Scanned Gaia, claudecodemeta, FlowForge. Findings: (1) FlowForge GitHub OAuth secret in local `.env` — untracked but needs rotation, (2) work email in claudecodemeta git history — rewrite before public, (3) session export and old journal files removed from tracking, (4) `nanog` username path in CLAUDE.md fixed. HuggingFace token in whisperScripts still needs rotation (separate repo).
- [x] **Add gap analysis as a Gaia domain file** — `domains/anthropic-application.md` created with 5-gap tracking.
- [ ] **Update Claude.ai memory edits** — requires Claude.ai web session (cannot do from Claude Code).
- [x] **Reassess FlowForge scope.** Assessment: mobile app deprioritised. Reframed core is `/flowforge-init` slash command (already exists) + template composition engine. Terminal server (`flowforge-server`) is independently useful. See FlowForge architecture docs for details.

### Week 1: Make the Triad Visible

- [ ] **Make `claudecodemeta` public.** Write README explaining the fragmented-Claude problem and how the plugin solves it. This is the attention-getter for the Anthropic audience.
- [ ] **Make `Gaia` repo public** (after reviewing all domain files for sensitive content — redact health/finance specifics, keep structure and architecture spec).
- [ ] **Make `obsidian-gaia-plugin` public.** README with screenshots.
- [ ] **Make `latex-editor` public.** Write a proper README. Immediate evidence of production React/TypeScript.
- [ ] **Make `MiniLang` and `LLMexperiments` public.** Shows research depth.
- [ ] **Write piece #1** ("The Fragmented Claude Problem") — publish. This grounds claudecodemeta and Gaia in a clear problem statement.

### Week 2: Build the Web Dashboard

- [ ] **Begin Gaia Web Dashboard** in React/TypeScript/Next.js. Start with read-only domain overview + temporal view. This is the from-scratch React project that addresses Gap 1.
- [ ] **Add interaction polish** to the dashboard — motion, transitions, responsive design. Apply frontend-design skill principles. This addresses Gap 2.
- [ ] **Refactor FlowForge** toward the reframed scope. If the React Native mobile companion still makes sense, continue it. If not, the scaffolding logic may work better as a Claude Code skill or CLI tool.
- [ ] **Write piece #2** ("Gaia: Using AI to Systematically Develop Capabilities With AI") — the methodology essay. Publish while the dashboard build is in progress so the writing reflects the live experience.

### Week 3: Polish, Converge, Apply

- [ ] **Add write capability to Gaia Web Dashboard.** Domain editing, daily plan view, Cowork task status.
- [ ] **Assess convergence points** between the triad. Are there shared types? Shared state access patterns? Document observations but don't force a merge.
- [ ] **Write piece #3** ("People Are the Key Enabling Technology") — connecting DMSA/Skills4sight to Education Labs' mission.
- [ ] **Prepare application materials.** CV update, cover letter grounded in the published work and public repos.
- [ ] **Apply.**

### Ongoing (parallel throughout):

- [ ] Cowork scheduled tasks running daily (plan + reflect) and weekly (review + gap tracker + Anthropic watch)
- [ ] Document failures and surprises as honestly as successes
- [ ] Respond to any community engagement on public repos
- [ ] Industrious React port progresses in parallel when time allows — it's valuable but no longer the lead project

---

## 6. What This Programme Demonstrates to Education Labs

Taken together, this body of work shows:

1. **React/TypeScript capability** — Gaia Web Dashboard (built from scratch in Next.js), latex-editor (existing production app), FlowForge (React Native)

2. **Frontend craft and interaction design** — Gaia Web Dashboard's temporal views and domain analytics, the Obsidian plugin's mobile-optimised UI, Industrious (when the port progresses)

3. **Deep understanding of Claude's product ecosystem** — claudecodemeta (plugin extending Claude Code's memory), Gaia (orchestrating Claude across all interfaces), FlowForge (solving context bootstrapping), Cowork scheduled tasks, hooks, MCPs, skills. This is someone who lives inside the product and builds tools to make it better.

4. **Published thinking on capability development** — The essay series, grounded in real systems and honest about what fails

5. **The meta-demonstration** — Using Claude to systematically close the gaps required to work on Claude's capability development team. The triad (Gaia + claudecodemeta + FlowForge) collectively addresses the single biggest friction in AI-assisted work: context fragility. This is Education Labs' core problem space.

6. **Domain credibility** — PhD, adjunct professorship, EU research projects, manufacturing/pharma expertise. Not a career frontend developer — someone who understands capability development from first principles because they've built systems for it across multiple industries.

---

## 7. Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|-----------|
| Scope creep — trying to do everything | High | The sequencing is designed to produce a viable application by Week 3. Everything after that is bonus. |
| InnoGlobal IP leakage | Medium | Clear subscription separation. No InnoGlobal code in personal repos. Reference in essays only. |
| React port quality — shallow understanding exposed | Medium | Learn by building, not by reading. Use Claude Code as pair programmer but understand every line. Write about what you learn. |
| Scheduling layer failure (Task Scheduler + CLI) | Low | Task Scheduler is mature Windows infrastructure. Claude Code CLI `-p` mode is stable. Cowork remains as supplementary fallback. Manual `/gaia-plan` and `/gaia-reflect` always work. |
| Role filled before application ready | Real | Week 1 deliverables (public repos + first essay) are sufficient for an initial application. The rest strengthens it. |
| Burnout — parallel programme on top of day job | High | Gaia's evening reflection is designed to catch this. Be honest in the reflections. Adjust scope down, not quality. |

---

## 8. Immediate Next Actions

1. Confirm Cowork is installed and working on Windows desktop
2. Set up the first three Cowork scheduled tasks (morning plan, evening reflect, weekly review)
3. Wire the SessionEnd hook in `~/.claude/settings.json`
4. Create `domains/anthropic-application.md` in Gaia
5. Run security audit on repos targeted for Week 1 public release
6. Begin `latex-editor` README rewrite
7. Begin `claudecodemeta` README and publish

---

## Appendix A: Technology Stack Alignment

| Anthropic Uses | Gareth Has | Gap | Closing Via |
|---------------|-----------|-----|------------|
| React | Vue 3 (production, InnoGlobal), React (latex-editor) | Depth, not existence | Gaia Web Dashboard, Industrious port |
| TypeScript | Extensive (6+ VS Code extensions, Obsidian plugin, latex-editor) | None — already strong | — |
| Next.js | smartlabs-platform (scaffold only) | Real project needed | Gaia Web Dashboard |
| CSS / Tailwind | Throughout | Polish, not knowledge | Frontend-design skill + deliberate practice |
| Python | ~55 repos | None | — |
| Claude API / SDK | claudecodemeta, Gaia hooks | Already deep | — |

## Appendix B: Repo Visibility Plan

| Repository | Current | Target | Prep Needed |
|-----------|---------|--------|-------------|
| claudecodemeta | Private | Public | README, licence, remove any secrets |
| latex-editor | Private | Public | README rewrite, dependency audit |
| Gaia | Private | Public | Redact sensitive domain content, sanitise journal entries |
| obsidian-gaia-plugin | Private | Public | README, screenshots |
| gaia-web (new) | — | Public | Create repo, Next.js scaffold, build in public from first commit |
| FlowForge | Private | Public | README reflecting reframed scope (context bootstrapping), verify no secrets, assess which components are still relevant |
| industry-rev (Industrious) | Private | Public | README, React port branch |
| MiniLang / LLMexperiments | Private | Public | README, clean up notebooks |
| FlowForge | Private | Public | README reflecting reframed scope (context bootstrapping), verify no secrets, assess which components are still relevant |
| SMsRS | Private | Public | README explaining the research |
