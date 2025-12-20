# VitalForge API Documentation

## 📚 How to Access Swagger UI

### Start Your Rails Server
```bash
./bin/dev-server
# or
bin/rails server
```

### Visit Swagger UI
Once your server is running, visit:

```
http://localhost:3000/api-docs
```

You'll see an interactive Swagger UI where you can:
- ✅ Browse all API endpoints
- ✅ See request/response examples
- ✅ View schema definitions
- ✅ Test endpoints interactively (for JSON APIs)
- ✅ Export to Postman

## 📁 Documentation Files

### Swagger/OpenAPI Spec
- **Location**: `swagger/v1/swagger.yaml`
- **Format**: OpenAPI 3.0.1
- **URL**: http://localhost:3000/api-docs/v1/swagger.yaml

### RSpec Request Specs
- **Location**: `spec/requests/`
- **Files**:
  - `authentication_spec.rb` - Login/logout specs
  - `users_spec.rb` - User registration specs

## 🔄 Updating Documentation

### Method 1: Manual Edit (Current Setup)
Edit the file directly:
```bash
vim swagger/v1/swagger.yaml
```

Refresh browser to see changes immediately.

### Method 2: Auto-Generate from RSpec (Future)
When you add JSON API endpoints, run:
```bash
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
```

This will generate documentation from your request specs.

## 📦 Import to Postman

### Option 1: Import from URL
1. Open Postman
2. Click "Import"
3. Select "Link"
4. Enter: `http://localhost:3000/api-docs/v1/swagger.yaml`
5. Click "Import"

### Option 2: Import from File
1. Download: `swagger/v1/swagger.yaml`
2. Open Postman
3. Click "Import"
4. Select "File"
5. Choose the downloaded file

## 🎯 Current Endpoints Documented

### Authentication
- `POST /api/v1/login` - User login (web/session-based)
- `POST /api/v1/mobile/login` - User login (mobile/JWT)
- `DELETE /api/v1/logout` - User logout (web)
- `DELETE /api/v1/mobile/logout` - User logout (mobile)

### Users
- `POST /api/v1/users` - Create user account (web)
- `POST /api/v1/mobile/users` - Create user account (mobile)
- `GET /api/v1/current_user` - Get current user info

### Workout Templates
- `GET /api/v1/workout_templates` - List all active templates (public)
  - Returns `has_active_workout` flag if authenticated
  - Note: Filtering by goal_type/difficulty/days is done on frontend
- `GET /api/v1/workout_templates/:id` - Get template with exercises (public)
  - Returns `has_active_workout` flag if authenticated
- `POST /api/v1/workout_templates/:id/start` - Start workout from template (requires auth)
  - Body: `{ "scheduled_time": "HH:MM" }` (optional)
  - Returns 409 Conflict if duplicate active workout exists

### Workouts
- `GET /api/v1/workouts` - List user's workouts (requires auth)
  - Query params: `start_date`, `end_date` for date range filtering
  - Includes `scheduled_time` in response
- `GET /api/v1/workouts/:id` - Get workout details (requires auth)
  - Includes `scheduled_time` in response
- `PATCH /api/v1/workouts/:id/start` - Begin active workout (requires auth)
- `PATCH /api/v1/workouts/:id/complete` - Finish workout (requires auth)

### Exercise Sets
- `PATCH /api/v1/exercise_sets/:id` - Update set performance (requires auth)

### User Preferences
- `GET /api/v1/user_preference` - Get user preferences (requires auth)
- `POST /api/v1/user_preference` - Create preferences (requires auth)
- `PATCH /api/v1/user_preference` - Update preferences (requires auth)

## 📋 API Endpoint Details

### Workout Template Starter Flow

#### 1. Browse Templates (Public)
```http
GET /api/v1/workout_templates
```

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Push Pull Legs",
      "description": "Classic 6-day split for muscle building",
      "goal_type": "physique",
      "difficulty_level": "Intermediate",
      "days_per_week": 6,
      "estimated_duration_minutes": 45,
      "total_exercises": 6,
      "source": "Bodybuilding.com",
      "has_active_workout": false
    }
  ]
}
```

**Notes:**
- `has_active_workout` is `true` if the authenticated user already has an active workout from this template
- Frontend can filter by `goal_type`, `difficulty_level`, or `days_per_week` after receiving all templates

#### 2. View Template Details (Public)
```http
GET /api/v1/workout_templates/1
```

**Response:**
```json
{
  "data": {
    "id": 1,
    "name": "Push Pull Legs",
    "description": "...",
    "has_active_workout": false,
    "exercises": [
      {
        "id": 101,
        "order_position": 1,
        "recommended_sets": 4,
        "recommended_reps": "8-12",
        "rest_seconds": 90,
        "notes": "Focus on chest contraction",
        "exercise": {
          "id": 5,
          "name": "Barbell Bench Press",
          "muscle_group": "Chest",
          "equipment": "Barbell",
          "exercise_type": "Strength"
        }
      }
    ]
  }
}
```

**Note:** `has_active_workout` is `true` if the authenticated user already has an active workout from this template.

#### 3. Start Workout from Template (Authenticated - with optional scheduled time)
```http
POST /api/v1/workout_templates/1/start
Authorization: Bearer {jwt_token}
OR
Cookie: session_id=...
X-CSRF-Token: ...

Content-Type: application/json

{
  "scheduled_time": "06:00"
}
```

**Request Body (optional):**
- `scheduled_time`: Time in "HH:MM" format (e.g., "06:00" for 6:00 AM, "17:30" for 5:30 PM)

**Success Response (201 Created):**
```json
{
  "workout": {
    "id": 123,
    "name": "Push Pull Legs",
    "workout_template_id": 1,
    "workout_date": "2025-11-28",
    "scheduled_time": "06:00",
    "started_at": null,
    "completed": false,
    "workout_exercises": [
      {
        "id": 456,
        "order_position": 1,
        "completed": false,
        "exercise": {
          "id": 5,
          "name": "Barbell Bench Press"
        },
        "exercise_sets": [
          {
            "id": 789,
            "set_number": 1,
            "reps": 10,
            "weight": null,
            "completed": false
          },
          {
            "id": 790,
            "set_number": 2,
            "reps": 10,
            "weight": null,
            "completed": false
          }
        ]
      }
    ]
  }
}
```

**Duplicate Conflict Response (409 Conflict):**
```json
{
  "error": "You already have an active workout from this template. Complete it first or view your in-progress workouts.",
  "active_workout_id": 100
}
```

#### 4. Begin Workout (Authenticated)
```http
PATCH /api/v1/workouts/123/start
Authorization: Bearer {jwt_token}
```

**Response:**
```json
{
  "workout": {
    "id": 123,
    "started_at": "2025-11-28T08:00:00Z",
    "completed": false
  }
}
```

#### 4.5. Get Workouts with Date Range Filtering (Authenticated)
```http
GET /api/v1/workouts?start_date=2025-11-01&end_date=2025-11-30
Authorization: Bearer {jwt_token}
OR
Cookie: session_id=...
X-CSRF-Token: ...
```

**Query Parameters (all optional):**
- `start_date`: Start of date range (ISO format: YYYY-MM-DD)
- `end_date`: End of date range (ISO format: YYYY-MM-DD)
- Can provide both, just `start_date`, or just `end_date`

**Response:**
```json
{
  "data": [
    {
      "id": 123,
      "name": "Push Pull Legs",
      "workout_date": "2025-11-15",
      "scheduled_time": "06:00",
      "started_at": "2025-11-15T06:05:00Z",
      "completed_at": "2025-11-15T06:50:00Z",
      "completed": true,
      "workout_exercises": [
        {
          "id": 456,
          "order_position": 1,
          "completed": true,
          "exercise": {
            "id": 5,
            "name": "Barbell Bench Press"
          },
          "exercise_sets": [...]
        }
      ]
    }
  ]
}
```

**Use Cases:**
- Calendar view: Get all workouts for current month
- Week view: Get workouts for 7-day period
- Filter past vs upcoming workouts
- ICS file generation for calendar integration

#### 5. Update Set Performance (Authenticated)
```http
PATCH /api/v1/exercise_sets/789
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "exercise_set": {
    "reps": 12,
    "weight": 135,
    "weight_unit": "lbs",
    "rpe": 7,
    "completed": true
  }
}
```

**Response:**
```json
{
  "exercise_set": {
    "id": 789,
    "set_number": 1,
    "reps": 12,
    "weight": 135.0,
    "weight_unit": "lbs",
    "rpe": 7,
    "completed": true
  }
}
```

**Auto-Completion Logic:**
- When all sets in an exercise are completed → `workout_exercise.completed = true`
- When all exercises in a workout are completed → `workout.completed = true` (auto)

#### 6. Complete Workout (Authenticated)
```http
PATCH /api/v1/workouts/123/complete
Authorization: Bearer {jwt_token}
```

**Response:**
```json
{
  "workout": {
    "id": 123,
    "started_at": "2025-11-28T08:00:00Z",
    "completed_at": "2025-11-28T08:47:00Z",
    "duration_minutes": 47,
    "completed": true
  }
}
```

---

## 🚀 Custom Workouts (Future Feature)

When you build custom workout creation, you'll want to:

### 1. Create API Namespace
```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :workouts
    resources :exercises
  end
end
```

### 2. Create API Controller
```ruby
# app/controllers/api/v1/workouts_controller.rb
class Api::V1::WorkoutsController < ApplicationController
  skip_before_action :require_authentication, only: []
  before_action :set_user
  
  # GET /api/v1/workouts
  def index
    workouts = @user.workouts.includes(:exercises)
    render json: workouts, status: :ok
  end
  
  # POST /api/v1/workouts
  def create
    workout = @user.workouts.build(workout_params)
    
    if workout.save
      render json: workout, status: :created
    else
      render json: { errors: workout.errors }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_user
    @user = current_user
  end
  
  def workout_params
    params.require(:workout).permit(:name, :performed_at, :notes)
  end
end
```

### 3. Write Request Spec
```ruby
# spec/requests/api/v1/workouts_spec.rb
require 'swagger_helper'

RSpec.describe 'Workouts API', type: :request do
  path '/api/v1/workouts' do
    post 'Creates a workout' do
      tags 'Workouts'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :workout, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          performed_at: { type: :string, format: :datetime },
          notes: { type: :string }
        },
        required: ['name', 'performed_at']
      }
      
      response '201', 'workout created' do
        let(:workout) { { name: 'Morning Workout', performed_at: Time.current } }
        run_test!
      end
      
      response '422', 'invalid request' do
        let(:workout) { { name: '' } }
        run_test!
      end
    end
  end
end
```

### 4. Generate Swagger
```bash
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
```

This will auto-generate OpenAPI documentation from your specs!

## 🎨 Swagger UI Features

### Interactive Testing
1. Click on any endpoint
2. Click "Try it out"
3. Fill in parameters
4. Click "Execute"
5. See live response

### Schema Exploration
- View all data models
- See required vs optional fields
- Understand data types
- Copy example values

### Export Options
- OpenAPI JSON/YAML
- Postman Collection
- cURL commands
- Code snippets (multiple languages)

## 🔐 Authentication in Swagger

Your current setup uses session-based auth, which works great for HTML forms but is tricky in Swagger UI.

### For Testing with Postman
1. First, make a `POST /login` request
2. Copy the session cookie from response
3. Add cookie to subsequent requests

### For React Frontend
```typescript
// React component
const API_BASE = 'http://localhost:3000/api/v1';

// Get CSRF token from meta tag
const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');

// Make API request
fetch(`${API_BASE}/workouts`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  credentials: 'include', // Important: sends cookies
  body: JSON.stringify({
    workout: {
      name: 'Morning Workout',
      performed_at: new Date().toISOString()
    }
  })
});
```

## 📝 Documentation Best Practices

### 1. Keep Examples Realistic
```yaml
example: "john.doe@example.com"  # Good
example: "string"                # Bad
```

### 2. Add Descriptions
```yaml
description: "User email address (must be unique)"
```

### 3. Mark Required Fields
```yaml
required:
  - email
  - password
```

### 4. Document Error Responses
```yaml
'422':
  description: Validation failed
  content:
    application/json:
      schema:
        $ref: '#/components/schemas/ValidationErrors'
```

### 5. Use Tags for Organization
```yaml
tags:
  - Authentication
  - Workouts
  - Exercises
```

## 🛠 Troubleshooting

### Swagger UI not loading?
```bash
# Check if server is running
curl http://localhost:3000/api-docs

# Check routes
bin/rails routes | grep api-docs

# Check initializers
ls config/initializers/rswag*
```

### YAML syntax error?
```bash
# Validate YAML
ruby -r yaml -e "YAML.load_file('swagger/v1/swagger.yaml')"
```

### Want to see raw YAML?
Visit: http://localhost:3000/api-docs/v1/swagger.yaml

## 📚 Additional Resources

- [OpenAPI Specification](https://swagger.io/specification/)
- [rswag Documentation](https://github.com/rswag/rswag)
- [Swagger UI Features](https://swagger.io/tools/swagger-ui/)
- [Postman Integration](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/)

## 🎯 Quick Commands

```bash
# Start server
./bin/dev-server

# Visit Swagger UI
open http://localhost:3000/api-docs

# Generate docs from specs (future)
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize

# Run request specs
bundle exec rspec spec/requests

# Validate Swagger YAML
ruby -r yaml -e "YAML.load_file('swagger/v1/swagger.yaml')"
```

---

**Happy API Documentation! 🎉**

