# 012 — Server-Side Personal Records + Paginated Workouts

**Date:** 2026-05-22
**Branch:** `012-personal-records-server-side` (both Rails + React Native repos)
**Depends on:** `011-personal-records-progress` (merged)

---

## Context

Branch 011 implemented client-side PR detection and the exercise-progress chart. Both work by fetching the full `GET /api/v1/workouts` payload and computing results in JavaScript. This approach was intentional (documented in `BACKLOG.md`) — no measured performance problem existed at that point.

This branch implements the server-side approach:
- A `personal_records` table stores confirmed PR milestones
- PR detection moves to Rails, removing the client-side `prDetection.ts` module entirely
- `GET /api/v1/workouts` becomes cursor-paginated — the full payload is no longer sent
- The exercise-progress 1RM chart switches from scanning all workouts to querying PR history

Client-side PR detection and pagination are mutually exclusive — adding pagination breaks the chart and badge logic. This branch resolves that by making Rails the source of truth for PRs.

---

## Design Decisions

**PR detection fires at workout completion, not on each set log.**
Mid-workout sets can be edited before the workout is finished — logging 180×12 then correcting it to 170×12 would create a stale PR row if we wrote on every set log. Deferring to completion ensures only final, confirmed values are persisted. The in-session PR toast still fires immediately (driven by the set log response, not a DB write).

**`personal_records` is append-only.**
Rows are never updated. Each row is a snapshot of a PR milestone at a point in time. The current best is the row with the highest `estimated_1rm` for a given user + exercise.

**`on_delete: :restrict` on the `exercise_set` FK.**
Deleting a workout that contains a PR should recalculate records for affected exercises — not silently leave stale rows (`nullify`) or silently wipe history (`cascade`). `restrict` forces the deletion to be handled explicitly. Workout deletion with PR recalculation is documented in `BACKLOG.md` as a follow-up feature.

**Cursor pagination, not offset pagination.**
Offset pagination (`page=2&per=25`) is fragile — inserting a new workout while paginating causes rows to shift, producing duplicates or gaps. Cursor pagination uses the last seen workout ID as a bookmark, immune to inserts.

**Backfill as a rake task, not a schema migration.**
Schema migrations should only change structure. Data migrations that run complex business logic belong in rake tasks — they can be re-run if they fail, tested in isolation, and don't block `db:migrate`.

**`maxWeight` and `volume` metrics on the exercise-progress screen remain client-side for now.**
With pagination, these charts cover only the last 25 workouts. This is a known limitation documented below. Server-side endpoints for volume and max weight history are deferred — no measured need yet.

---

## 1. Database

### `personal_records` table

| Column | Type | Constraints |
|---|---|---|
| `id` | bigint | PK |
| `user_id` | bigint | FK → users, NOT NULL |
| `exercise_id` | bigint | FK → exercises, NOT NULL |
| `set_id` | bigint | FK → exercise_sets, on_delete: :restrict |
| `estimated_1rm` | decimal(6,2) | NOT NULL |
| `weight` | decimal(6,2) | NOT NULL — denormalized for read performance |
| `reps` | integer | NOT NULL — denormalized for read performance |
| `recorded_at` | datetime | NOT NULL |
| `created_at` | datetime | Rails standard |
| `updated_at` | datetime | Rails standard |

`weight` and `reps` are stored directly on the row (denormalized) to avoid joining back to `exercise_sets` on every chart query. They represent the values at the time the PR was recorded and are treated as immutable.

### Indexes

```ruby
add_index :personal_records, [:user_id, :exercise_id, :recorded_at]
add_index :personal_records, [:user_id, :exercise_id, :estimated_1rm]
add_index :personal_records, :set_id
```

First index: covers history queries (exercise progress chart, ordered by date).
Second index: covers current-best lookups (badge display, active workout baseline).
Third index: covers FK constraint checks on set deletion.

---

## 2. Rails Backend

### 2a — Epley helper module

```ruby
# app/controllers/concerns/epley_1rm.rb
module Epley1RM
  def epley_1rm(weight, reps)
    return weight.to_f if reps == 1
    weight.to_f * (1 + reps.to_f / 30)
  end
end
```

Shared concern included in any controller that needs 1RM calculation. The `reps == 1` guard returns weight directly — a single-rep lift is its own 1RM.

### 2b — PersonalRecord model

```ruby
class PersonalRecord < ApplicationRecord
  belongs_to :user
  belongs_to :exercise
  belongs_to :exercise_set, optional: true

  validates :estimated_1rm, :weight, :reps, :recorded_at, presence: true

  def self.current_best_for(user_id:, exercise_id:)
    where(user_id: user_id, exercise_id: exercise_id)
      .order(estimated_1rm: :desc)
      .first
  end
end
```

`exercise_set` is `optional: true` because `on_delete: :restrict` at the DB level handles enforcement. `current_best_for` is a named scope used by both the set log check and the completion persist step.

### 2c — `exercise_sets#update` — in-memory PR check

No DB write. Returns `is_new_pr` flag in response so the mobile client can fire the PR toast immediately.

```ruby
def update
  @exercise_set.update!(exercise_set_params)
  is_new_pr = pr_candidate?(@exercise_set)
  render json: {
    exercise_set: @exercise_set,
    personal_record: { is_new_pr: is_new_pr }
  }
end

private

def pr_candidate?(set)
  return false unless set.completed? &&
    set.weight.present? && set.weight > 0 &&
    set.reps.present? && set.reps > 0

  new_1rm = epley_1rm(set.weight, set.reps)
  current_best = PersonalRecord.current_best_for(
    user_id: current_user.id,
    exercise_id: set.workout_exercise.exercise_id
  )
  current_best.nil? || new_1rm > current_best.estimated_1rm
end
```

`current_best.nil?` handles the first-ever set for an exercise — no prior record means any completed weighted set is a PR.

### 2d — `workouts#complete` — persist PRs

Runs after marking the workout complete. Takes the best set per exercise (highest estimated 1RM), compares to stored best, inserts only if it beats the record.

```ruby
def complete
  @workout.update!(completed: true, completed_at: Time.current)
  persist_prs(@workout)
  render json: { workout: @workout }
end

private

def persist_prs(workout)
  workout.workout_exercises.includes(:exercise, :exercise_sets).each do |we|
    best_set = we.exercise_sets
      .select { |s|
        s.completed? &&
        s.weight.present? && s.weight > 0 &&
        s.reps.present? && s.reps > 0
      }
      .max_by { |s| epley_1rm(s.weight, s.reps) }
    next unless best_set

    new_1rm = epley_1rm(best_set.weight, best_set.reps)
    current_best = PersonalRecord.current_best_for(
      user_id: current_user.id,
      exercise_id: we.exercise.id
    )
    next if current_best.present? && new_1rm <= current_best.estimated_1rm

    PersonalRecord.create!(
      user_id: current_user.id,
      exercise_id: we.exercise.id,
      set_id: best_set.id,
      estimated_1rm: new_1rm.round(2),
      weight: best_set.weight,
      reps: best_set.reps,
      recorded_at: Time.current
    )
  end
end
```

`includes(:exercise, :exercise_sets)` eager-loads associations to avoid N+1 queries — without it, each loop iteration fires separate DB queries.

### 2e — `personal_records#index`

Single endpoint, two modes controlled by the `exercise_id` param.

```ruby
def index
  records = if params[:exercise_id]
    # Full PR history for one exercise — used by exercise-progress chart
    PersonalRecord
      .where(user_id: current_user.id, exercise_id: params[:exercise_id])
      .order(recorded_at: :asc)
  else
    # Current best per exercise — used by workout-detail badges + active workout baseline
    PersonalRecord
      .where(user_id: current_user.id)
      .select('DISTINCT ON (exercise_id) *')
      .order('exercise_id, estimated_1rm DESC')
  end
  render json: records
end
```

`DISTINCT ON (exercise_id)` is PostgreSQL syntax that returns one row per unique `exercise_id`. Combined with `ORDER BY estimated_1rm DESC`, it selects the row with the highest 1RM for each exercise.

### 2f — `workouts#index` — cursor pagination

```ruby
FILTER_RANGES = {
  'this_week'  => -> { 1.week.ago.beginning_of_day },
  'this_month' => -> { 1.month.ago.beginning_of_day },
  'this_year'  => -> { 1.year.ago.beginning_of_day },
}.freeze

def index
  workouts = current_user.workouts
    .where(completed: true)
    .order(workout_date: :desc, id: :desc)
    .includes(workout_exercises: [:exercise, :exercise_sets])

  if (range = FILTER_RANGES[params[:filter]])
    workouts = workouts.where('workout_date >= ?', range.call)
  end

  if params[:cursor].present?
    cursor = Workout.find_by(id: params[:cursor])
    if cursor
      workouts = workouts.where(
        'workout_date < ? OR (workout_date = ? AND id < ?)',
        cursor.workout_date, cursor.workout_date, cursor.id
      )
    end
  end

  workouts = workouts.limit(25)

  render json: {
    workouts: workouts,
    next_cursor: workouts.size == 25 ? workouts.last.id : nil
  }
end
```

The cursor is the ID of the last workout received. The `OR` clause handles the tiebreaker when two workouts share the same date. `next_cursor: null` signals the mobile client that it has reached the end of the list.

### 2g — Routes

```ruby
namespace :api do
  namespace :v1 do
    resources :personal_records, only: [:index]
    resources :workouts, only: [:index, :show, :create, :update] do
      member { post :complete }
    end
    resources :exercise_sets, only: [:update]
  end
end
```

---

## 3. Mobile Client

### 3a — New TypeScript types

```typescript
export type PersonalRecord = {
  exercise_id: number;
  set_id: number | null;
  estimated_1rm: number;
  weight: number;
  reps: number;
  recorded_at: string;
};

export type WorkoutsPage = {
  workouts: WorkoutDetail[];
  next_cursor: number | null;
};

export type LogSetResponse = {
  exercise_set: ExerciseSet;
  personal_record: { is_new_pr: boolean };
};
```

### 3b — `workoutsApi.ts` changes

**`logSet`** — update response type to `LogSetResponse`.

**`getWorkouts`** — cursor pagination with RTK Query infinite scroll pattern:

```typescript
getWorkouts: builder.query<WorkoutsPage, { cursor?: number; filter?: string }>({
  query: (params) => ({ url: '/api/v1/workouts', params }),
  serializeQueryArgs: ({ endpointName, queryArgs }) =>
    `${endpointName}-${queryArgs.filter ?? 'all'}`,
  merge: (cache, newPage) => {
    cache.workouts.push(...newPage.workouts);
    cache.next_cursor = newPage.next_cursor;
  },
  forceRefetch: ({ currentArg, previousArg }) => currentArg !== previousArg,
  providesTags: ['Workouts'],
}),
```

`serializeQueryArgs` keeps all pages under one cache key per filter so pages merge rather than replace. `merge` appends new pages to the existing list. `forceRefetch` ensures a new cursor triggers a fresh request.

**`getPersonalRecords`** — new query:

```typescript
getPersonalRecords: builder.query<PersonalRecord[], { exerciseId?: number }>({
  query: ({ exerciseId } = {}) => ({
    url: '/api/v1/personal_records',
    params: exerciseId ? { exercise_id: exerciseId } : {},
  }),
  providesTags: ['PersonalRecords'],
}),
```

### 3c — `active-workout.tsx`

**Remove:** `useGetWorkoutsQuery`, `detectPRSetIds`, `prSetIds`, `previousBest` calculation.

**Add:** Read `result.personal_record.is_new_pr` from the `logSet` response and fire the toast:

```typescript
const result = await logSetFn({ ... }).unwrap();
if (result.personal_record.is_new_pr) {
  setPRToastVisible(true);
}
```

The screen no longer loads historical workouts. PR detection is fully delegated to Rails.

### 3d — `workout-detail.tsx`

Replace `detectPRSetIds(allWorkouts)` with:

```typescript
const { data: personalRecords = [] } = useGetPersonalRecordsQuery({});
const prSetIds = useMemo(
  () => new Set(personalRecords.map((pr) => pr.set_id).filter(Boolean)),
  [personalRecords]
);
```

`SetHistoryRow`'s `isPR` prop interface is unchanged.

### 3e — `exercise-progress.tsx`

For the `'1rm'` metric, replace the workouts-derived series with:

```typescript
const { data: prHistory = [] } = useGetPersonalRecordsQuery({ exerciseId });
```

Each data point is a confirmed PR milestone (not estimated 1RM from every set). The chart shows a clean strength progression line — only the moments a new best was set.

`maxWeight` and `volume` metrics continue to use the paginated workouts payload. See Known Limitations.

### 3f — `workout-history.tsx` (new screen — backlog 007)

Infinite scroll list of completed workouts with preset time filter chips.

```
[ This Week ]  [ This Month ]  [ This Year ]  [ All ]

Pull Day                              May 20 2026
12 sets · 48 min
──────────────────────────────────────────────────
Push Day                              May 18 2026
10 sets · 42 min
──────────────────────────────────────────────────
                                  [ Loading... ]
```

- Filter chips pass `filter` param (`this_week` | `this_month` | `this_year` | `all`) → Rails filters by `start_date`
- Scrolling near the bottom fires `getWorkouts({ cursor: next_cursor, filter })`
- `next_cursor: null` stops pagination
- Pull-to-refresh resets the cache and fetches from the top

### 3g — Deletions

| File | Action |
|---|---|
| `src/lib/stats/prDetection.ts` | Delete — replaced by server-side detection |
| `src/lib/stats/exerciseHistory.ts` | Update — remove `'1rm'` series computation, keep `maxWeight` and `volume` |
| `__tests__/lib/stats/prDetection.test.ts` | Delete with source file |

Client-side `calculateEpley1RM` is no longer called anywhere and can be removed.

---

## 4. Backfill Migration

Schema migration creates the table. Rake task populates it from existing workout data.

**Run order:**
```bash
rails db:migrate
rails personal_records:backfill
```

The rake task iterates users in batches, fetches completed sets per exercise in chronological order, tracks running best estimated 1RM, and inserts a `personal_records` row each time a new best is found. This replays history accurately — each row represents the moment a new best was first achieved.

`User.find_each` loads users in batches of 1,000 to avoid loading the entire users table into memory.

---

## 5. Edge Cases

| Case | Handling |
|---|---|
| First set ever for an exercise | `current_best.nil?` → it IS the PR, insert row |
| Bodyweight set (weight null) | Guard clause returns false before any calculation |
| Weight or reps zero | Guard clause: `weight > 0 && reps > 0` |
| Tie — same estimated 1RM as current best | Strict `>` not `>=` — not a new record, no insert |
| Workout completed with no logged sets | No valid `best_set` found, `next unless best_set` skips |
| Set edited after workout completion | Known limitation — see below |
| Workout deleted | `on_delete: :restrict` blocks deletion; recalculation logic documented in BACKLOG.md |

---

## 6. Known Limitations

**`maxWeight` and `volume` charts cover only paginated data.**
With 25 workouts per page, the exercise-progress chart for these two metrics only reflects recent history. A server-side endpoint for volume and max weight history is deferred until there is evidence of user need.

**Set edited after workout completion.**
If a set is edited on the workout-detail screen after a workout is marked complete, the corresponding `personal_records` row is not recalculated. The stored PR reflects the value at completion time. Recalculation on post-completion edit is out of scope for this branch.

---

## 7. Testing

### Rails (RSpec request specs)

| Spec | Covers |
|---|---|
| `exercise_sets#update` returns `is_new_pr: true` when 1RM beats stored best | Toast trigger |
| `exercise_sets#update` returns `is_new_pr: false` when 1RM does not beat best | No false positive |
| `exercise_sets#update` returns `is_new_pr: true` when no prior record exists | First-set edge case |
| `exercise_sets#update` returns `is_new_pr: false` for bodyweight set | Bodyweight guard |
| `workouts#complete` inserts a `personal_records` row for best set | Persist path |
| `workouts#complete` does not insert when best set does not beat stored best | Tie/no-PR guard |
| `workouts#complete` skips exercises with no completed weighted sets | Zero sets edge case |
| `personal_records#index` returns current best per exercise (no param) | Badge + baseline |
| `personal_records#index` returns full history for one exercise (with `exercise_id`) | Progress chart |
| `workouts#index` returns 25 workouts with `next_cursor` | Pagination |
| `workouts#index` with cursor returns the correct next page | Cursor navigation |
| `workouts#index` returns `next_cursor: null` when fewer than 25 results returned | End of list |

### Mobile (Jest)

| Test | Covers |
|---|---|
| `active-workout` — `logSet` response with `is_new_pr: true` shows PR toast | New toast path |
| `active-workout` — `logSet` response with `is_new_pr: false` shows no toast | No false positive |
| `workout-detail` — trophy badge driven by `useGetPersonalRecordsQuery` mock | Replaced dependency |
| `workout-history` — renders list, loads next page near bottom of scroll | Infinite scroll |
| `workout-history` — filter chip changes `filter` param on query | Filter chips |
