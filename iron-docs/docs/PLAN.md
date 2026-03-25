# Iron — Atomic Implementation Plan

Each phase is a shippable increment. Each task within a phase is atomic — one PR, one concern.

---

## Phase 0: Project Scaffold
> Goal: Empty app runs on phone, installable as PWA

| # | Task | Detail | Files |
|---|------|--------|-------|
| 0.1 | Init SvelteKit project | `npm create svelte@latest`, TypeScript, no SSR (SPA mode) | `svelte.config.js`, `tsconfig.json` |
| 0.2 | Add Tailwind CSS | Install + configure with mobile-first defaults | `tailwind.config.js`, `app.css` |
| 0.3 | Configure PWA | `vite-plugin-pwa`, web manifest (name, icons, theme colour, display: standalone) | `vite.config.ts`, `static/manifest.json` |
| 0.4 | App shell layout | Bottom nav (Home, Workout, History, Settings), top bar, viewport meta | `src/routes/+layout.svelte` |
| 0.5 | Add Dexie.js | Install, define initial DB schema (v1), export db instance | `src/lib/db/index.ts` |
| 0.6 | Deploy pipeline | Cloudflare Pages or Vercel, auto-deploy from `main` | `wrangler.toml` or Vercel config |
| 0.7 | Generate PWA icons | 192x192 and 512x512 icons, favicon | `static/icons/` |

**Exit criteria:** App installs on Android homescreen, shows bottom nav, works offline (empty shell).

---

## Phase 1: Data Model & Exercise Library
> Goal: Core types defined, seeded with real exercises

| # | Task | Detail | Files |
|---|------|--------|-------|
| 1.1 | Define TypeScript types | `Exercise`, `Set`, `WorkoutSession`, `Programme`, `ExerciseTemplate`, `MuscleGroup`, `BodyMetric` | `src/lib/types/index.ts` |
| 1.2 | Dexie schema for exercises | `exerciseTemplates` table: id, name, muscleGroups[], category, defaultRepRange, defaultRest, increment, formCues | `src/lib/db/schema.ts` |
| 1.3 | Dexie schema for workouts | `workoutSessions` table + `workoutSets` table (normalised) | `src/lib/db/schema.ts` |
| 1.4 | Dexie schema for programme | `programmes` table + `programmeDay` structure | `src/lib/db/schema.ts` |
| 1.5 | Seed exercise library | 40-50 common exercises with muscle groups, categories, default rep ranges, form cues | `src/lib/db/seed.ts` |
| 1.6 | Seed default programme | The 3-day rotation from Gaia health domain (Legs+Shoulders, Biceps+Chest+Core, Triceps+Back+Core) | `src/lib/db/seed.ts` |
| 1.7 | DB migration strategy | Dexie version-based migrations, test upgrade path | `src/lib/db/migrations.ts` |

**Exit criteria:** DB initialises with seeded data on first load. Types compile. Can inspect data in DevTools IndexedDB.

---

## Phase 2: Programme Management
> Goal: View and edit training programme

| # | Task | Detail | Files |
|---|------|--------|-------|
| 2.1 | Programme view page | Show current programme: days, exercises per day, rep ranges, rest times | `src/routes/programme/+page.svelte` |
| 2.2 | Day reorder | Drag-to-reorder days within programme | Component with touch drag |
| 2.3 | Exercise reorder | Drag-to-reorder exercises within a day | Component with touch drag |
| 2.4 | Add exercise to day | Search/filter exercise library, tap to add | `src/components/programme/ExerciseSearch.svelte` |
| 2.5 | Remove exercise from day | Swipe-to-delete or long-press menu | Gesture handler |
| 2.6 | Edit exercise params | Tap exercise → edit rep range, rest time, increment, notes | `src/components/programme/ExerciseEditor.svelte` |
| 2.7 | Create custom exercise | Form: name, muscle groups (multi-select), category, defaults | `src/components/programme/CreateExercise.svelte` |
| 2.8 | Programme day rotation tracker | Store which day was last completed, auto-advance | `src/lib/stores/programme.ts` |

**Exit criteria:** Can view, reorder, add/remove exercises, and edit params. Rotation tracks correctly.

---

## Phase 3: Workout Tracking (Core Loop) ← MVP
> Goal: Can run a full workout session, logging every set

| # | Task | Detail | Files |
|---|------|--------|-------|
| 3.1 | Workout start flow | "Start Day N" button → create WorkoutSession, load exercises | `src/routes/workout/+page.svelte` |
| 3.2 | Pre-workout readiness check | Quick 1-5 scale: sleep, energy, soreness → stored on session | `src/components/workout/ReadinessCheck.svelte` |
| 3.3 | Exercise card component | Shows: exercise name, target sets × rep range, weight last session, form cue (expandable) | `src/components/workout/ExerciseCard.svelte` |
| 3.4 | Set logging row | Inputs: weight (pre-filled from last session), reps, RPE (optional). Tap checkmark to log | `src/components/workout/SetRow.svelte` |
| 3.5 | Add/remove sets | "+" button to add extra set, swipe to remove | Within ExerciseCard |
| 3.6 | Rest timer | Auto-starts on set completion. Countdown overlay, vibration on finish, tap to dismiss early | `src/components/workout/RestTimer.svelte` |
| 3.7 | Exercise navigation | Swipe left/right between exercises OR scrollable list. Progress indicator (3/7) | Gesture/scroll handler |
| 3.8 | Session timer | Running clock at top of workout screen | `src/components/workout/SessionTimer.svelte` |
| 3.9 | Quick-add exercise | Mid-workout: search and add an exercise not in today's plan | Reuse ExerciseSearch |
| 3.10 | Workout notes | Free-text input per exercise and per session | Text input fields |
| 3.11 | Finish workout flow | Confirm → calculate summary → save to DB → show summary card | `src/components/workout/WorkoutSummary.svelte` |
| 3.12 | Workout resume | If app closes mid-workout, detect in-progress session on next open, offer to resume | `src/lib/stores/workout.ts` |
| 3.13 | Cancel/discard workout | Option to discard an in-progress session | Confirmation dialog |

**Exit criteria:** Can start a workout, log all sets with weights/reps, see rest timer, finish and see summary. Session persists across app restarts.

---

## Phase 4: Progressive Overload Engine
> Goal: App suggests weight/rep changes based on history

| # | Task | Detail | Files |
|---|------|--------|-------|
| 4.1 | 1RM calculator | Epley + Brzycki formulas, best-set extraction | `src/lib/engine/oneRepMax.ts` |
| 4.2 | Double progression logic | Evaluate sets against rep range, determine: increase weight / add reps / hold | `src/lib/engine/progression.ts` |
| 4.3 | Suggestion display | Show suggestion on ExerciseCard: "↑ 82.5kg × 8" or "→ Repeat 80kg, aim for 10 reps" | Badge/chip on ExerciseCard |
| 4.4 | Pre-fill weights from suggestion | When starting workout, weight inputs pre-filled with suggested values | `src/lib/stores/workout.ts` |
| 4.5 | PR detection | After logging a set, check if estimated 1RM exceeds previous best. Show celebration toast | `src/lib/engine/prDetection.ts` |
| 4.6 | Stall detection | Flag exercises with no progress for 3+ sessions | `src/lib/engine/stallDetection.ts` |
| 4.7 | Stall-breaking suggestions | Offer: deload, change rep range, swap variation | UI in exercise detail |
| 4.8 | Volume tracking | Weekly sets per muscle group, MEV/MRV indicators | `src/lib/engine/volumeTracking.ts` |
| 4.9 | Warm-up set generator | Given working weight, output ramped warm-up sets | `src/lib/engine/warmup.ts` |
| 4.10 | Deload suggestion | Track consecutive weeks, detect fatigue, suggest deload week | `src/lib/engine/deload.ts` |

**Exit criteria:** Exercises show progression suggestions. PRs detected and celebrated. Volume tracked per muscle group. Deload triggered after 4 weeks.

---

## Phase 5: History & Visualisation
> Goal: Review past workouts, see progression over time

| # | Task | Detail | Files |
|---|------|--------|-------|
| 5.1 | Workout history list | Scrollable list of past sessions: date, day label, duration, total volume | `src/routes/history/+page.svelte` |
| 5.2 | Workout detail view | Tap session → see all exercises, sets, notes, summary stats | `src/routes/history/[id]/+page.svelte` |
| 5.3 | Calendar heat map | Month view, coloured by training days (similar to GitHub contribution graph) | `src/components/charts/HeatMap.svelte` |
| 5.4 | Exercise progression chart | Line chart: estimated 1RM over time per exercise | `src/components/charts/ProgressionChart.svelte` |
| 5.5 | Volume trend chart | Stacked bar: weekly volume per muscle group | `src/components/charts/VolumeChart.svelte` |
| 5.6 | PR timeline | List of all-time PRs with dates | `src/components/charts/PRTimeline.svelte` |
| 5.7 | Streak counter | Current training streak (consecutive weeks with ≥N sessions) | `src/lib/engine/streaks.ts` |
| 5.8 | Session comparison | Compare today's session vs last time same day was run | `src/components/workout/SessionComparison.svelte` |
| 5.9 | Charting library | Integrate lightweight chart lib (Chart.js or Layercake for Svelte-native) | `src/lib/charts/` |

**Exit criteria:** Can browse all past workouts. Charts show meaningful progression data. Streaks and PRs visible on home screen.

---

## Phase 6: Body Metrics
> Goal: Track bodyweight, measurements, and body composition

| # | Task | Detail | Files |
|---|------|--------|-------|
| 6.1 | Dexie schema for metrics | `bodyMetrics` table: date, weight, measurements{}, notes | `src/lib/db/schema.ts` |
| 6.2 | Metrics log page | Form: weight (kg), optional measurements (chest, waist, arms, legs), notes | `src/routes/metrics/+page.svelte` |
| 6.3 | Weight trend chart | Line chart with 7-day rolling average | `src/components/charts/WeightChart.svelte` |
| 6.4 | Measurement trends | Per-measurement line charts | Within metrics page |
| 6.5 | Quick-log from home | "Log weight" shortcut on home screen for fast daily entry | Home screen widget |

**Exit criteria:** Can log daily weight and measurements. Trend chart shows rolling average.

---

## Phase 7: Gaia Sync
> Goal: Bidirectional data flow between Iron and Gaia

| # | Task | Detail | Files |
|---|------|--------|-------|
| 7.1 | GitHub API auth | OAuth device flow or PAT-based auth, stored in IndexedDB (encrypted) | `src/lib/sync/auth.ts` |
| 7.2 | Programme pull | Fetch `Gaia/fitness/programme.yaml`, parse, update local DB | `src/lib/sync/pullProgramme.ts` |
| 7.3 | Workout log push | After workout: generate markdown log, commit to `Gaia/fitness/logs/YYYY-MM-DD.md` | `src/lib/sync/pushWorkout.ts` |
| 7.4 | Health domain update | Append workout summary to `domains/health.md` Recent Activity | `src/lib/sync/updateDomain.ts` |
| 7.5 | Sync queue | Queue sync operations when offline, process when back online | `src/lib/sync/queue.ts` |
| 7.6 | Conflict resolution | If remote has newer data, merge (append-only for logs, latest-wins for programme) | `src/lib/sync/merge.ts` |
| 7.7 | Sync status indicator | Icon in nav showing sync state: synced / pending / error | `src/components/common/SyncStatus.svelte` |
| 7.8 | Settings page: sync config | Gaia repo URL, auth token, sync frequency, manual sync button | `src/routes/settings/+page.svelte` |
| 7.9 | Register in Gaia manifest | Add iron entry to `manifest.yaml` | `Gaia/manifest.yaml` |

**Exit criteria:** Workouts sync to Gaia repo. Programme changes in Gaia pull into Iron. Offline queue works.

---

## Phase 8: Polish & UX
> Goal: Feels like a native app, delightful to use mid-workout

| # | Task | Detail | Files |
|---|------|--------|-------|
| 8.1 | Haptic feedback | Vibration on set completion, timer end, PR | Vibration API |
| 8.2 | Swipe gestures | Swipe between exercises, swipe-to-delete sets | Touch gesture library |
| 8.3 | Dark mode | Default dark theme (gym-friendly), optional light | Tailwind dark mode |
| 8.4 | Number input UX | Large tap targets, +/- buttons for weight (2.5kg steps), quick-scroll for reps | Custom number input component |
| 8.5 | Loading states | Skeleton screens, optimistic UI for set logging | Svelte transitions |
| 8.6 | Error handling | Toast notifications for errors, retry logic for sync | `src/components/common/Toast.svelte` |
| 8.7 | Onboarding flow | First launch: set up programme (or import from Gaia), set preferences | `src/routes/onboarding/` |
| 8.8 | Keep screen awake | Wake Lock API during active workout | `src/lib/utils/wakeLock.ts` |
| 8.9 | App icon & splash | Branded icon, splash screen for PWA install | `static/icons/` |

**Exit criteria:** App feels snappy and native. Usable one-handed between sets. Screen stays on during workouts.

---

## Phase Summary

| Phase | Name | Tasks | Priority | Dependency |
|-------|------|-------|----------|------------|
| 0 | Scaffold | 7 | P0 | — |
| 1 | Data Model | 7 | P0 | Phase 0 |
| 2 | Programme | 8 | P1 | Phase 1 |
| 3 | **Workout Tracking** | 13 | **P0 — MVP** | Phase 1 |
| 4 | **Overload Engine** | 10 | **P0** | Phase 3 |
| 5 | History & Viz | 9 | P1 | Phase 3 |
| 6 | Body Metrics | 5 | P2 | Phase 1 |
| 7 | Gaia Sync | 9 | P1 | Phase 3 |
| 8 | Polish | 9 | P2 | Phase 3 |

**Total: 77 tasks across 9 phases.**

### Critical Path to Gym-Ready MVP

Phase 0 → Phase 1 → Phase 3 → Phase 4

This gets you: installable PWA, pre-loaded programme, set logging with rest timer, progressive overload suggestions. ~30 tasks.
