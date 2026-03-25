# Iron

Mobile-first PWA fitness tracker with progressive overload intelligence and [Gaia](https://github.com/nanogareth/gaia) integration.

## What It Does

Iron is your gym companion — a phone-based workout tracker that pre-loads your programme, logs sets with minimal taps, calculates progressive overload, and syncs everything back to Gaia's health domain automatically.

## Key Features

- **Quick-start workouts** — knows your rotation, pre-loads today's exercises
- **One-tap set logging** — log weight × reps with minimal interaction
- **Rest timer** — auto-starts after each set, vibration alert
- **Progressive overload engine** — tracks 1RM estimates, suggests weight/rep increases
- **Offline-first** — works without WiFi (gyms have terrible signal), syncs when online
- **Gaia integration** — bidirectional sync with health domain state
- **Workout history** — progression charts, volume trends, PR tracking

## Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| Framework | SvelteKit | Already used in Gaia ecosystem (Obsidian plugin), excellent mobile perf |
| Styling | Tailwind CSS | Rapid mobile-first UI development |
| Local Storage | Dexie.js (IndexedDB) | Offline-first, structured data, reactive queries |
| PWA | Vite PWA plugin | Service worker, web app manifest, installable |
| Sync | GitHub API | Commits workout logs to Gaia repo |
| Deploy | Cloudflare Pages | Free tier, global CDN, fast |
| Testing | Vitest + Playwright | Unit + E2E |

## Architecture

```
Phone (PWA)
  ├── UI Layer (SvelteKit + Tailwind)
  ├── State Layer (Svelte stores + Dexie.js/IndexedDB)
  ├── Overload Engine (progression calculations)
  └── Sync Layer (GitHub API → Gaia repo)
        ├── Push: workout logs → Gaia/fitness/logs/
        ├── Push: summary → domains/health.md Recent Activity
        └── Pull: programme config ← Gaia/fitness/programme.yaml
```

## Getting Started

```bash
npm install
npm run dev        # Dev server on localhost:5173
npm run build      # Production build
npm run preview    # Preview production build
npm run test       # Run unit tests
npm run test:e2e   # Run E2E tests
```

## Project Structure

```
src/
  lib/
    db/             # Dexie.js database schema and migrations
    engine/         # Progressive overload calculations
    sync/           # Gaia sync logic (GitHub API)
    stores/         # Svelte stores (workout state, settings)
    types/          # TypeScript type definitions
    utils/          # Helpers (timers, formatters, 1RM formulas)
  routes/
    /               # Home — start workout or view recent sessions
    /workout/       # Active workout session
    /history/       # Workout history + charts
    /programme/     # Programme editor
    /settings/      # App settings, sync config
    /metrics/       # Body metrics log
  components/
    workout/        # ExerciseCard, SetRow, RestTimer, WorkoutSummary
    charts/         # ProgressionChart, VolumeChart, HeatMap
    common/         # Button, Card, Input, Modal, Toast
docs/
  PLAN.md           # Atomic implementation plan
  TESTING.md        # Test strategy
  PROGRESSIVE_OVERLOAD.md  # Overload algorithm documentation
```

## Gaia Integration

Iron is a registered project in Gaia's `manifest.yaml`. The sync loop:

1. **Programme pull**: Iron reads `Gaia/fitness/programme.yaml` for the current training programme
2. **Workout push**: After each session, Iron commits a structured markdown log to `Gaia/fitness/logs/YYYY-MM-DD.md`
3. **Domain update**: Appends a summary line to `domains/health.md` Recent Activity
4. **Hook compatibility**: Gaia's SessionEnd hook recognises Iron sessions

## License

Private project.
