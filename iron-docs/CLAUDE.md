# CLAUDE.md — Iron

## What This Is

Iron is a mobile-first PWA fitness tracker with progressive overload intelligence. It's the gym-facing input layer for Gaia's health domain.

## Tech Stack

- **SvelteKit** (SPA mode, no SSR) + **TypeScript**
- **Tailwind CSS** (mobile-first)
- **Dexie.js** (IndexedDB wrapper, offline-first storage)
- **Vite PWA plugin** (service worker, installable)
- **Vitest** (unit + component tests) + **Playwright** (E2E)
- **Cloudflare Pages** (deploy)

## Commands

```bash
npm run dev        # Dev server
npm run build      # Production build
npm run preview    # Preview build
npm run test       # Unit + component tests (Vitest)
npm run test:e2e   # E2E tests (Playwright)
npm run lint       # ESLint
npm run check      # Svelte type check
```

## Architecture

```
src/lib/db/        # Dexie database, schema, seed data, migrations
src/lib/engine/    # Progressive overload algorithms (pure functions, heavily tested)
src/lib/sync/      # GitHub API sync to Gaia repo
src/lib/stores/    # Svelte stores (workout state, settings, programme)
src/lib/types/     # TypeScript type definitions
src/lib/utils/     # Helpers (timers, formatters, 1RM formulas)
src/routes/        # SvelteKit pages (/, /workout, /history, /programme, /settings, /metrics)
src/components/    # Svelte components (workout/, charts/, programme/, common/)
```

## Key Design Principles

1. **Offline-first** — All data in IndexedDB. Sync is async and failure-tolerant.
2. **Sub-3-second interactions** — Logging a set must be faster than writing it down.
3. **Engine is pure** — `src/lib/engine/` is pure TypeScript, no Svelte or DOM deps. Test coverage ≥95%.
4. **Gaia is source of truth** — Iron is a view/input layer. Programme definition lives in Gaia. Workout logs push to Gaia.
5. **Dark mode default** — Gyms are dim. White screens are blinding.

## Gaia Integration

- **Pull:** Programme from `Gaia/fitness/programme.yaml`
- **Push:** Workout logs to `Gaia/fitness/logs/YYYY-MM-DD.md`
- **Push:** Summary to `Gaia/domains/health.md` Recent Activity (append-only)
- **Sync:** Via GitHub API with offline queue

## Testing

- Engine functions: unit tests with ≥95% coverage
- Components: @testing-library/svelte, ≥80% coverage
- Sync: msw mocks for GitHub API
- E2E: Playwright with mobile viewport (390×844)
- See `docs/TESTING.md` for full strategy
