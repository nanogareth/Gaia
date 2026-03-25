# Progressive Overload Engine

The core intelligence of Iron. This document defines the algorithms and rules that power workout suggestions.

## 1RM Estimation

We use the **Epley formula** (most widely validated):

```
1RM = weight × (1 + reps / 30)
```

Alternative (Brzycki, used for cross-validation when reps < 10):

```
1RM = weight × (36 / (37 - reps))
```

Iron stores the **estimated 1RM** for every exercise after each session, using the best set (highest estimated 1RM) from that session.

## Double Progression Model

Iron uses **double progression** as the default strategy — the most reliable method for intermediate lifters:

### How It Works

1. Define a **rep range** per exercise (e.g., 8-12 reps)
2. Start at the **bottom** of the range with a given weight
3. Each session, try to add reps (staying within the range)
4. When you hit the **top** of the range for all prescribed sets → **increase weight**
5. Drop back to the bottom of the range at the new weight
6. Repeat

### Weight Increment Rules

| Exercise Category | Increment |
|-------------------|-----------|
| Barbell compound (squat, bench, deadlift, OHP, row) | +2.5 kg |
| Dumbbell exercises | +2 kg (per hand) |
| Cable/machine exercises | +2.5 kg (or smallest plate) |
| Bodyweight exercises | +1 rep or add weight vest |

### Example

```
Week 1: Bench Press 80kg × 8, 8, 8  (bottom of 8-12 range)
Week 2: Bench Press 80kg × 9, 9, 8
Week 3: Bench Press 80kg × 10, 10, 9
Week 4: Bench Press 80kg × 11, 11, 10
Week 5: Bench Press 80kg × 12, 12, 12  ← hit top of range on ALL sets
Week 6: Bench Press 82.5kg × 8, 8, 8  ← weight increase, reset to bottom
```

## Suggestion Algorithm

After each set is logged, Iron evaluates:

```typescript
function suggestNextSession(exercise: Exercise, recentSets: Set[]): Suggestion {
  const targetRepsHigh = exercise.repRange[1]  // e.g., 12
  const targetRepsLow = exercise.repRange[0]   // e.g., 8
  const allSetsAtTop = recentSets.every(s => s.reps >= targetRepsHigh)
  const anySetBelow = recentSets.some(s => s.reps < targetRepsLow)

  if (allSetsAtTop) {
    return {
      action: 'increase_weight',
      newWeight: exercise.currentWeight + exercise.increment,
      newTargetReps: targetRepsLow,
      message: `All sets at ${targetRepsHigh} reps. Increase to ${newWeight}kg × ${targetRepsLow}.`
    }
  }

  if (anySetBelow) {
    return {
      action: 'hold',
      message: `Some sets below ${targetRepsLow}. Repeat ${exercise.currentWeight}kg, aim for ${targetRepsLow}+ on all sets.`
    }
  }

  return {
    action: 'add_reps',
    message: `Try to add 1 rep per set next session.`
  }
}
```

## Volume Tracking

Weekly volume per muscle group is tracked as **total sets to failure/near-failure**:

| Level | Weekly Sets per Muscle Group |
|-------|----------------------------|
| Minimum Effective Volume (MEV) | 8-10 sets |
| Maximum Recoverable Volume (MRV) | 18-22 sets |
| Target range | 12-16 sets |

Iron warns when you're below MEV or approaching MRV for any muscle group.

## Deload Logic

Iron tracks **cumulative fatigue** via a simple heuristic:

```
fatigue_score = consecutive_weeks_without_deload × avg_rpe_last_week
```

Triggers:
- After **4 consecutive weeks** of training → suggest deload
- If **2+ exercises stall** (no rep/weight increase for 2 sessions) → suggest deload
- If **readiness score** averages below 3/5 for a week → suggest deload

Deload prescription:
- Same exercises, same reps
- Reduce weight by **40-50%**
- Reduce sets by **30-40%**
- Duration: 1 week

## Stall Detection

An exercise is considered **stalled** when:
- Same weight AND same or fewer reps for **3 consecutive sessions**

Stall-breaking suggestions (in order):
1. Reduce weight by 10%, rebuild
2. Change rep range (e.g., switch from 8-12 to 5-8 for a cycle)
3. Swap exercise variation (e.g., flat bench → incline bench)

## Warm-Up Set Generator

For compound exercises, Iron generates warm-up sets:

```
Working weight: 100kg
Warm-up:
  Set 1: bar only (20kg) × 10
  Set 2: 40% (40kg) × 8
  Set 3: 60% (60kg) × 5
  Set 4: 80% (80kg) × 3
```

Formula:
- Always start with empty bar (barbell) or ~20% (dumbbells)
- 3-4 warm-up sets ramping to 80% of working weight
- Reps decrease as weight increases (10 → 8 → 5 → 3)
- Rest between warm-up sets: 60s (shorter than working sets)
