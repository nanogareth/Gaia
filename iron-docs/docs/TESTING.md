# Iron — Testing Strategy

## Testing Stack

| Tool | Purpose |
|------|---------|
| **Vitest** | Unit tests, component tests (fast, Vite-native) |
| **@testing-library/svelte** | Component rendering and interaction |
| **Playwright** | E2E tests, PWA testing, mobile viewport |
| **msw** (Mock Service Worker) | API mocking for GitHub sync tests |

## Test Categories

### 1. Unit Tests (`src/**/*.test.ts`)

Pure logic, no DOM. Fast, run on every commit.

#### Progressive Overload Engine

| Test | Input | Expected Output |
|------|-------|-----------------|
| `oneRepMax.epley` | 80kg × 10 reps | 106.7 kg |
| `oneRepMax.epley` | 100kg × 1 rep | 103.3 kg |
| `oneRepMax.brzycki` | 80kg × 10 reps | 108.1 kg |
| `oneRepMax.bestSet` | array of sets | set with highest estimated 1RM |
| `progression.evaluate` — all sets at top of range | [{80kg, 12}, {80kg, 12}, {80kg, 12}], range [8,12] | `{ action: 'increase_weight', newWeight: 82.5 }` |
| `progression.evaluate` — mid range | [{80kg, 10}, {80kg, 9}, {80kg, 9}], range [8,12] | `{ action: 'add_reps' }` |
| `progression.evaluate` — below range | [{80kg, 7}, {80kg, 6}, {80kg, 6}], range [8,12] | `{ action: 'hold' }` |
| `progression.evaluate` — single set at top | [{80kg, 12}, {80kg, 10}], range [8,12] | `{ action: 'add_reps' }` (not all sets at top) |
| `progression.increment` — barbell compound | exercise category 'barbell_compound' | 2.5 kg |
| `progression.increment` — dumbbell | exercise category 'dumbbell' | 2.0 kg |
| `stallDetection.isStalled` | 3 sessions same weight, same/fewer reps | `true` |
| `stallDetection.isStalled` | 3 sessions, reps increasing | `false` |
| `stallDetection.suggestions` | stalled exercise | ordered list: deload, change range, swap variation |
| `volumeTracking.weeklyVolume` | week of sessions | sets per muscle group map |
| `volumeTracking.belowMEV` | 6 sets chest in week | `true` (below 8) |
| `volumeTracking.aboveMRV` | 24 sets chest in week | `true` (above 22) |
| `deload.fatigueScore` | 4 weeks, avg RPE 8 | score > threshold |
| `deload.shouldDeload` | 4 consecutive weeks | `true` |
| `deload.shouldDeload` | 2 weeks | `false` |
| `deload.prescription` | working sets | sets with 50% weight, 60% volume |
| `warmup.generate` | working weight 100kg, barbell | [20×10, 40×8, 60×5, 80×3] |
| `warmup.generate` | working weight 20kg, dumbbell | [4×10, 8×8, 12×5, 16×3] |
| `streaks.calculate` | sessions with dates | current streak count |
| `prDetection.check` | new 1RM > historical max | `{ isPR: true, exercise, old1RM, new1RM }` |

#### Utility Functions

| Test | Description |
|------|-------------|
| `formatDuration` | Seconds → "45:23" format |
| `formatWeight` | Number → "82.5 kg" with correct decimal handling |
| `formatVolume` | Total kg → "12,400 kg" with thousands separator |
| `calculateTotalVolume` | Sum of (weight × reps) across all sets |
| `dayRotation.next` | Given last completed day index, return next day |
| `dayRotation.next` | After last day, wraps to first day |
| `restTimer.format` | Remaining seconds → "1:30" display |

### 2. Component Tests (`src/**/*.test.svelte.ts`)

Render components, simulate interactions, verify DOM output.

#### Workout Components

| Test | Component | Scenario | Assertion |
|------|-----------|----------|-----------|
| Renders with last session data | `SetRow` | Previous: 80kg × 8 | Weight input shows "80", reps shows "8" |
| Logs a set on checkmark tap | `SetRow` | Tap ✓ | `onComplete` fires with weight + reps |
| Pre-fills suggested weight | `SetRow` | Suggestion: increase to 82.5 | Weight input shows "82.5" |
| Weight +/- buttons | `SetRow` | Tap + | Weight increments by exercise increment |
| Shows rest timer on set complete | `RestTimer` | Set logged | Timer counts down from exercise rest time |
| Vibrates on timer end | `RestTimer` | Countdown reaches 0 | `navigator.vibrate` called |
| Dismiss timer early | `RestTimer` | Tap dismiss | Timer closes, no vibrate |
| Shows exercise with target | `ExerciseCard` | Exercise: Bench 3×8-12 | Shows "Bench Press", "3 × 8-12", weight |
| Expandable form cues | `ExerciseCard` | Tap "form" button | Cue text appears |
| Shows progression badge | `ExerciseCard` | Suggestion: increase weight | Green "↑" badge visible |
| Shows stall warning | `ExerciseCard` | 3 sessions stalled | Orange "stalled" indicator |
| Session timer ticks | `SessionTimer` | 60 seconds pass | Displays "1:00" |
| Readiness slider | `ReadinessCheck` | Slide to 4 | Value updates, emoji changes |
| Summary stats correct | `WorkoutSummary` | Session with known sets | Total volume, duration, PR count correct |

#### Programme Components

| Test | Component | Scenario | Assertion |
|------|-----------|----------|-----------|
| Lists all days | `ProgrammeView` | 3-day programme | 3 day cards rendered |
| Lists exercises per day | `ProgrammeView` | Day 1 has 5 exercises | 5 exercise rows |
| Search filters exercises | `ExerciseSearch` | Type "bench" | Only bench variants shown |
| Add exercise to day | `ExerciseSearch` | Tap exercise | Added to day's exercise list |
| Edit rep range | `ExerciseEditor` | Change to 6-10 | Saved to DB |

#### Chart Components

| Test | Component | Scenario | Assertion |
|------|-----------|----------|-----------|
| Renders with data | `ProgressionChart` | 10 data points | SVG/canvas rendered, no errors |
| Empty state | `ProgressionChart` | 0 data points | "No data yet" message |
| Heat map colours | `HeatMap` | Mix of trained/rest days | Correct colour coding |
| PR timeline entries | `PRTimeline` | 5 PRs | 5 entries with dates and values |

### 3. Integration Tests (`src/**/*.integration.test.ts`)

Test interactions between modules — DB + engine + stores.

| Test | Description |
|------|-------------|
| Full workout flow | Start session → log sets → finish → verify DB state |
| Progressive overload after workout | Complete workout → engine calculates suggestion → next session pre-fills correctly |
| PR detection end-to-end | Log a set exceeding historical best → PR detected and stored |
| Volume tracking across sessions | Log 3 sessions in a week → weekly volume calculated correctly per muscle group |
| Deload after 4 weeks | Simulate 4 weeks of sessions → deload suggested |
| Programme rotation | Complete Day 1 → app suggests Day 2 → complete Day 2 → suggests Day 3 → wraps to Day 1 |
| Workout resume | Start workout → kill app → reopen → in-progress session detected and resumable |
| Exercise history query | Log 10 sessions → query history for specific exercise → returns chronological data |
| DB migration | Create v1 DB with data → run v2 migration → data intact + new fields present |

### 4. Sync Tests (`src/lib/sync/**/*.test.ts`)

Use MSW to mock GitHub API responses.

| Test | Description |
|------|-------------|
| Push workout log | After workout → generates correct markdown → commits to correct path |
| Push domain update | After workout → appends to health.md Recent Activity (not overwrite) |
| Pull programme | Fetch programme.yaml → parse → update local DB |
| Offline queue | Sync fails → queued → network restored → queue processes |
| Queue ordering | Multiple queued syncs → processed in FIFO order |
| Conflict: newer remote programme | Local programme older → remote wins, local updated |
| Auth token refresh | Token expired → refresh flow → retry succeeds |
| Auth token missing | No token → sync skipped, UI shows "not configured" |
| Markdown generation | Known session data → markdown output matches snapshot |

### 5. E2E Tests (`tests/**/*.spec.ts`)

Playwright, mobile viewport (390×844, iPhone 14 equivalent).

| Test | Description |
|------|-------------|
| Install PWA | Open app → browser install prompt available |
| Offline support | Load app → go offline → app still functional |
| Full workout E2E | Start workout → log 3 exercises × 3 sets each → finish → see summary → see in history |
| Programme edit E2E | Go to programme → add exercise → reorder → save → start workout → new exercise present |
| Navigation | Bottom nav → all 4 routes accessible, active state correct |
| Responsive layout | Viewport 360px wide → no horizontal scroll, all controls tappable |
| Rest timer E2E | Log a set → timer appears → wait for countdown → timer dismisses |
| History charts | Navigate to history → exercise chart renders with data |
| Workout resume E2E | Start workout → navigate away → return → resume prompt shown |
| Dark mode | Default renders dark theme, text readable, contrast OK |
| Keep screen awake | During workout, Wake Lock API active |
| Pre-filled weights | Complete session 1 → start session 2 → weights from session 1 pre-filled |
| PR celebration | Log set exceeding best → toast/animation shown |

### 6. PWA-Specific Tests

| Test | Description |
|------|-------------|
| Service worker registers | On first load, SW registered and caching assets |
| Offline fallback | Offline → navigate → app shell loads from cache |
| Background sync | Log workout offline → come online → sync fires |
| App manifest | Correct name, icons, theme colour, display mode |
| Add to homescreen | Manifest triggers install prompt on Android Chrome |

## Test Organisation

```
src/
  lib/
    engine/
      oneRepMax.ts
      oneRepMax.test.ts          ← unit
      progression.ts
      progression.test.ts        ← unit
      ...
    sync/
      pushWorkout.ts
      pushWorkout.test.ts        ← unit (msw mock)
      ...
  components/
    workout/
      SetRow.svelte
      SetRow.test.svelte.ts      ← component
      ...
  routes/
    workout/
      +page.svelte
      workout.integration.test.ts ← integration
tests/
  e2e/
    workout-flow.spec.ts          ← E2E (Playwright)
    programme-edit.spec.ts
    navigation.spec.ts
    pwa.spec.ts
    offline.spec.ts
```

## Coverage Targets

| Category | Target | Rationale |
|----------|--------|-----------|
| Engine (overload, 1RM, volume) | **95%** | Core logic, must be correct — wrong suggestions erode trust |
| DB/Schema | **90%** | Data integrity critical for long-term tracking |
| Components | **80%** | Key interactions covered, visual details less critical |
| Sync | **85%** | Offline queue and conflict handling must be reliable |
| E2E | Key flows | Not coverage-driven — covers critical user journeys |

## CI Pipeline

```yaml
# On every PR:
- npm run lint        # ESLint + Prettier check
- npm run check       # Svelte check (type errors)
- npm run test        # Vitest (unit + component + integration)
- npm run build       # Verify production build succeeds

# On merge to main:
- All of the above
- npx playwright test  # E2E tests against production build
- Deploy to Cloudflare Pages
```

## Test Data Strategy

- **Fixtures:** `tests/fixtures/` contains factory functions for common test data (sessions, exercises, programmes)
- **Deterministic dates:** Tests use fixed dates via `vi.useFakeTimers()` — no flaky date-dependent tests
- **Isolated DB:** Each test gets a fresh Dexie instance (in-memory or unique name) — no cross-test pollution
- **Snapshot tests:** Markdown generation output tested via Vitest snapshots — changes flagged in review
