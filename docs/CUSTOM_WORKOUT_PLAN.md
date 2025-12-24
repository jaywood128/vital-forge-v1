# Custom Workout Creation Plan

## Overview

This document outlines the future implementation of custom workout creation, allowing users to build workouts from scratch without using templates.

## Current State

**Implemented:**
- Workout Templates (browse and start from templates)
- Template-based workout creation with pre-populated exercises and sets

**Not Yet Implemented:**
- Creating empty custom workouts
- Adding exercises to workouts manually
- Adding sets to exercises manually
- Removing exercises and sets
- Reordering exercises

## Architecture

### Database Support

The current database schema **already supports** custom workouts:
- `workouts.workout_template_id` is **nullable** - if null, it's a custom workout
- All relationships work the same way for both template-based and custom workouts

### Differentiation

```ruby
# Template-based workout
workout.workout_template_id # => 1 (has a template)

# Custom workout
workout.workout_template_id # => nil (no template)
```

## API Endpoints to Implement

### 1. Create Empty Custom Workout

**Endpoint:** `POST /api/v1/workouts`

**Purpose:** Create a new empty workout that the user will build manually

**Request:**
```json
{
  "workout": {
    "name": "My Custom Leg Day",
    "workout_type": "Strength",
    "workout_date": "2025-11-28",
    "description": "Heavy squats and accessories",
    "notes": "Focus on form"
  }
}
```

**Response:**
```json
{
  "workout": {
    "id": 123,
    "user_id": 1,
    "workout_template_id": null,
    "name": "My Custom Leg Day",
    "workout_type": "Strength",
    "workout_date": "2025-11-28",
    "description": "Heavy squats and accessories",
    "notes": "Focus on form",
    "started_at": null,
    "completed_at": null,
    "completed": false,
    "workout_exercises": []
  }
}
```

**Controller Action:**
```ruby
# app/controllers/api/v1/workouts_controller.rb
def create
  workout = current_user.workouts.build(workout_params)
  
  if workout.save
    render json: { workout: serialize_workout(workout) }, status: :created
  else
    render json: { errors: workout.errors }, status: :unprocessable_entity
  end
end

private

def workout_params
  params.require(:workout).permit(
    :name, :description, :workout_date, :workout_type,
    :notes, :intensity_level, :calories_burned
  )
end
```

---

### 2. Add Exercise to Workout

**Endpoint:** `POST /api/v1/workouts/:workout_id/exercises`

**Purpose:** Add an exercise from the catalog to a workout

**Request:**
```json
{
  "workout_exercise": {
    "exercise_id": 5,
    "order_position": 1,
    "rest_between_sets": 90,
    "notes": "Focus on depth"
  }
}
```

**Response:**
```json
{
  "workout_exercise": {
    "id": 456,
    "workout_id": 123,
    "exercise_id": 5,
    "order_position": 1,
    "rest_between_sets": 90,
    "notes": "Focus on depth",
    "completed": false,
    "exercise": {
      "id": 5,
      "name": "Barbell Squat",
      "muscle_group": "Legs",
      "equipment": "Barbell"
    },
    "exercise_sets": []
  }
}
```

**Controller:**
```ruby
# app/controllers/api/v1/workout_exercises_controller.rb
class Api::V1::WorkoutExercisesController < Api::V1::BaseController
  include DualAuthenticatable
  
  def create
    workout = current_user.workouts.find(params[:workout_id])
    workout_exercise = workout.workout_exercises.build(workout_exercise_params)
    
    if workout_exercise.save
      render json: { 
        workout_exercise: serialize_workout_exercise(workout_exercise) 
      }, status: :created
    else
      render json: { errors: workout_exercise.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    workout = current_user.workouts.find(params[:workout_id])
    workout_exercise = workout.workout_exercises.find(params[:id])
    
    workout_exercise.destroy
    head :no_content
  end
  
  private
  
  def workout_exercise_params
    params.require(:workout_exercise).permit(
      :exercise_id, :order_position, :rest_between_sets, :notes
    )
  end
end
```

**Routes:**
```ruby
resources :workouts do
  resources :exercises, controller: 'workout_exercises', only: [:create, :destroy]
end
```

---

### 3. Add Set to Exercise

**Endpoint:** `POST /api/v1/workout_exercises/:workout_exercise_id/sets`

**Purpose:** Add a set to an exercise in a workout

**Request:**
```json
{
  "exercise_set": {
    "set_number": 1,
    "reps": 10,
    "weight": 135,
    "weight_unit": "lbs",
    "completed": false
  }
}
```

**Response:**
```json
{
  "exercise_set": {
    "id": 789,
    "workout_exercise_id": 456,
    "set_number": 1,
    "reps": 10,
    "weight": 135.0,
    "weight_unit": "lbs",
    "rpe": null,
    "to_failure": false,
    "notes": null,
    "completed": false
  }
}
```

**Controller:**
```ruby
# app/controllers/api/v1/exercise_sets_controller.rb (extend existing)
def create
  workout_exercise = current_user
    .workouts
    .joins(:workout_exercises)
    .find_by!(workout_exercises: { id: params[:workout_exercise_id] })
  
  exercise_set = workout_exercise.exercise_sets.build(exercise_set_params)
  
  if exercise_set.save
    render json: { exercise_set: exercise_set }, status: :created
  else
    render json: { errors: exercise_set.errors }, status: :unprocessable_entity
  end
end

def destroy
  exercise_set = ExerciseSet
    .joins(workout_exercise: { workout: :user })
    .where(workouts: { user_id: current_user.id })
    .find(params[:id])
  
  exercise_set.destroy
  head :no_content
end

private

def exercise_set_params
  params.require(:exercise_set).permit(
    :set_number, :reps, :weight, :weight_unit,
    :rest_after_seconds, :rpe, :to_failure, :notes, :completed
  )
end
```

**Routes:**
```ruby
resources :workout_exercises, only: [] do
  resources :sets, controller: 'exercise_sets', only: [:create]
end

resources :exercise_sets, only: [:update, :destroy]
```

---

### 4. Update Exercise Order

**Endpoint:** `PATCH /api/v1/workout_exercises/:id/reorder`

**Purpose:** Change the order of exercises in a workout

**Request:**
```json
{
  "workout_exercise": {
    "order_position": 3
  }
}
```

**Response:**
```json
{
  "workout_exercise": {
    "id": 456,
    "order_position": 3
  }
}
```

**Controller:**
```ruby
def reorder
  workout = current_user.workouts.find(params[:workout_id])
  workout_exercise = workout.workout_exercises.find(params[:id])
  
  if workout_exercise.update(order_position: params[:order_position])
    render json: { workout_exercise: workout_exercise }, status: :ok
  else
    render json: { errors: workout_exercise.errors }, status: :unprocessable_entity
  end
end
```

---

## Complete Custom Workout Flow

### Step-by-Step User Experience

1. **User clicks "Create Custom Workout"**
   ```
   POST /api/v1/workouts
   { name: "My Leg Day", workout_date: "2025-11-28" }
   ```

2. **User searches exercise catalog**
   ```
   GET /api/v1/exercises?muscle_group=Legs&equipment=Barbell
   ```

3. **User adds "Barbell Squat" to workout**
   ```
   POST /api/v1/workouts/123/exercises
   { exercise_id: 5, order_position: 1 }
   ```

4. **User adds 3 sets to the exercise**
   ```
   POST /api/v1/workout_exercises/456/sets
   { set_number: 1, reps: 10, weight: 135 }
   
   POST /api/v1/workout_exercises/456/sets
   { set_number: 2, reps: 10, weight: 185 }
   
   POST /api/v1/workout_exercises/456/sets
   { set_number: 3, reps: 10, weight: 225 }
   ```

5. **User adds more exercises** (repeat steps 3-4)

6. **User starts the workout**
   ```
   PATCH /api/v1/workouts/123/start
   ```

7. **User performs sets** (same as template-based workouts)
   ```
   PATCH /api/v1/exercise_sets/789
   { reps: 12, weight: 135, completed: true }
   ```

8. **User completes workout**
   ```
   PATCH /api/v1/workouts/123/complete
   ```

---

## Frontend Components Needed

### 1. Custom Workout Builder
- Form to create workout (name, date, type)
- Exercise search/filter interface
- Drag-and-drop exercise ordering
- Add/remove exercises
- Add/remove sets

### 2. Exercise Catalog Browser
- Search by name
- Filter by muscle group
- Filter by equipment
- Filter by exercise type
- Preview exercise details (instructions, video)

### 3. Set Builder
- Quick add multiple sets
- Copy set from previous
- Set templates (e.g., "5x5", "3x8-12")

---

## Service Objects to Create

### WorkoutBuilder
Encapsulates the logic for building custom workouts

```ruby
# app/services/workout_builder.rb
class WorkoutBuilder
  def initialize(user:, workout_params:)
    @user = user
    @workout_params = workout_params
  end
  
  def call
    @user.workouts.create!(@workout_params)
  end
end
```

### ExerciseAdder
Adds an exercise to a workout with proper ordering

```ruby
# app/services/exercise_adder.rb
class ExerciseAdder
  def initialize(workout:, exercise_id:, position: nil)
    @workout = workout
    @exercise_id = exercise_id
    @position = position || next_position
  end
  
  def call
    @workout.workout_exercises.create!(
      exercise_id: @exercise_id,
      order_position: @position,
      completed: false
    )
  end
  
  private
  
  def next_position
    (@workout.workout_exercises.maximum(:order_position) || 0) + 1
  end
end
```

---

## Testing Strategy

### Model Tests
- Test workout creation without template_id
- Test exercise ordering
- Test set number uniqueness per exercise

### Request Tests
- Test creating empty workout
- Test adding exercises to workout
- Test adding sets to exercise
- Test removing exercises
- Test removing sets
- Test reordering exercises

### Integration Tests
- Test complete custom workout flow
- Test mixing template-based and custom workouts
- Test data integrity when deleting

---

## Routes Summary

```ruby
namespace :api do
  namespace :v1 do
    resources :workouts do
      member do
        patch :start
        patch :complete
      end
      
      resources :exercises, controller: 'workout_exercises', only: [:create, :destroy] do
        member do
          patch :reorder
        end
      end
    end
    
    resources :workout_exercises, only: [] do
      resources :sets, controller: 'exercise_sets', only: [:create]
    end
    
    resources :exercise_sets, only: [:update, :destroy]
    
    resources :exercises, only: [:index, :show]
  end
end
```

---

## Implementation Priority

### Phase 1: Core CRUD
1. Create empty workout
2. Add exercise to workout
3. Add set to exercise
4. Update set
5. Delete set
6. Delete exercise

### Phase 2: Enhancements
1. Reorder exercises
2. Copy workout
3. Save workout as template
4. Exercise search/filter
5. Set templates

### Phase 3: Advanced Features
1. Exercise substitutions
2. Superset support
3. Rest timer integration
4. Progress tracking
5. Workout history comparison

---

## Database Queries

### Get Custom Workouts Only
```ruby
current_user.workouts.where(workout_template_id: nil)
```

### Get Template-Based Workouts Only
```ruby
current_user.workouts.where.not(workout_template_id: nil)
```

### Get Workout with All Details
```ruby
workout = current_user.workouts
  .includes(workout_exercises: [:exercise, :exercise_sets])
  .find(params[:id])
```

---

## Security Considerations

### Authorization Checks
- Users can only modify their own workouts
- Use scoped queries: `current_user.workouts.find(id)`
- Verify ownership through associations

### Validation
- Validate exercise exists in catalog
- Validate set_number uniqueness per exercise
- Validate order_position is positive
- Validate reps and weight are positive

---

## Performance Optimization

### Eager Loading
```ruby
# Avoid N+1 queries
workout = Workout.includes(
  workout_exercises: [
    :exercise,
    exercise_sets: []
  ]
).find(id)
```

### Caching
- Cache exercise catalog (rarely changes)
- Cache user's recent workouts
- Cache workout templates

---

## Future Enhancements

1. **Workout Templates from Custom Workouts**
   - Allow users to save custom workouts as personal templates
   - Share templates with community

2. **Exercise Substitutions**
   - Suggest alternative exercises
   - Equipment-based substitutions

3. **Supersets and Circuits**
   - Group exercises together
   - Track rest between groups

4. **Progressive Overload Tracking**
   - Suggest weight increases
   - Track volume over time

5. **Workout Analytics**
   - Volume per muscle group
   - Training frequency
   - Progress charts

---

## Documentation Updates Needed

When implementing custom workouts:
1. Update API_DOCUMENTATION.md with new endpoints
2. Update DATABASE_SCHEMA.md (no changes needed, already supports it)
3. Update README.md with custom workout feature
4. Create CUSTOM_WORKOUT_GUIDE.md for frontend developers
5. Update Swagger/OpenAPI documentation

---

## Estimated Implementation Time

- **Phase 1 (Core CRUD):** 2-3 days
  - Backend: 1 day
  - Frontend: 1-2 days
  - Testing: 0.5 days

- **Phase 2 (Enhancements):** 2-3 days
  - Backend: 1 day
  - Frontend: 1-2 days
  - Testing: 0.5 days

- **Phase 3 (Advanced):** 1-2 weeks
  - Depends on feature complexity

---

**Total Estimated Time:** 1-2 weeks for full custom workout feature

---

**Last Updated:** 2025-11-28  
**Status:** Planning Phase  
**Priority:** Medium (after template starter is complete)

