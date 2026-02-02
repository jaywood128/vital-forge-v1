# 📚 API Documentation with Rswag

This guide explains how to document your API endpoints using **Rswag** (Swagger/OpenAPI for Rails).

## 📋 Documented Endpoints (OpenAPI 3.0)

All API endpoints are documented and generated from RSpec request specs:

| Spec file | Endpoints |
|-----------|-----------|
| `spec/requests/api/v1/auth_swagger_spec.rb` | `GET /api/v1/health`, `GET /api/v1/csrf`, `POST /api/v1/login`, `GET /api/v1/current_user`, `DELETE /api/v1/logout`, `POST /api/v1/signup` |
| `spec/requests/api/v1/mobile/auth_swagger_spec.rb` | `POST /api/v1/mobile/login`, `GET /api/v1/mobile/current_user`, `DELETE /api/v1/mobile/logout` |
| `spec/requests/api/v1/workouts_swagger_spec.rb` | `GET /api/v1/workouts`, `GET /api/v1/workouts/:id`, `PATCH /api/v1/workouts/:id/start`, `PATCH /api/v1/workouts/:id/complete`, `POST /api/v1/workout_templates/:id/start` |
| `spec/requests/api/v1/workout_templates_swagger_spec.rb` | `GET /api/v1/workout_templates`, `GET /api/v1/workout_templates/:id` |
| `spec/requests/api/v1/exercise_sets_swagger_spec.rb` | `PATCH /api/v1/exercise_sets/:id` |
| `spec/requests/api/v1/user_preferences_swagger_spec.rb` | `GET /api/v1/user_preference`, `POST /api/v1/user_preference`, `PATCH /api/v1/user_preference` |
| `spec/requests/api/v1/weekly_feedbacks_swagger_spec.rb` | `GET /api/v1/weekly_feedbacks/current` |

**Generate/update OpenAPI YAML:**
```bash
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
```
This writes `swagger/v1/swagger.yaml`. The spec is served at **http://localhost:3000/openapi/v1/swagger.yaml** (via `Rswag::Api::Engine`). Then view Swagger UI at **http://localhost:3000/api-docs** (when server is running).

**If you see "Failed to load API definition" / "Not Found":**
1. Run the command above to generate the YAML.
2. Restart the Rails server so it picks up the new file.

---

## 🎯 Why Rswag?

Since VitalForge uses a **separate Next.js frontend**, we need:
1. **Clear API contracts** - Frontend devs know exactly what to send/receive
2. **Interactive testing** - Test endpoints directly in the browser
3. **Auto-generated docs** - Documentation stays in sync with code
4. **Type safety** - OpenAPI specs can generate TypeScript types

---

## 🚀 Quick Start

### 1. View Current Documentation
Start your Rails server:
```bash
bin/dev
```

Visit: **http://localhost:3000/api-docs**

You'll see the Swagger UI with all documented endpoints.

### 2. Test an Endpoint
1. Click on an endpoint (e.g., `POST /api/v1/login`)
2. Click **"Try it out"**
3. Fill in the request body
4. Click **"Execute"**
5. See the response

---

## 📝 How to Document New Endpoints

### Step 1: Write a Request Spec

Create a spec file in `spec/requests/api/v1/`:

```ruby
# spec/requests/api/v1/workouts_spec.rb
require "swagger_helper"

RSpec.describe "Workouts API", type: :request do
  # You need a valid user session for authenticated endpoints
  let(:user) { User.create!(email: "test@example.com", password: "Password123!", first_name: "Test", last_name: "User") }
  let(:auth_headers) do
    # Get CSRF token
    get api_v1_current_user_path, as: :json
    csrf_token = cookies["CSRF-TOKEN"]
    
    # Login
    post api_v1_login_path, 
      params: { user: { email: user.email, password: "Password123!" } },
      headers: { "X-CSRF-Token" => csrf_token },
      as: :json
    
    # Return headers for subsequent requests
    { "X-CSRF-Token" => cookies["CSRF-TOKEN"] }
  end

  path "/api/v1/workouts" do
    get "List all workouts" do
      tags "Workouts"
      produces "application/json"
      description "Returns all workouts for the authenticated user"
      
      response "200", "workouts found" do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer, example: 1 },
                  name: { type: :string, example: "Morning Workout" },
                  performed_at: { type: :string, format: "date-time" },
                  notes: { type: :string, nullable: true },
                  created_at: { type: :string, format: "date-time" },
                  updated_at: { type: :string, format: "date-time" }
                },
                required: ["id", "name", "performed_at"]
              }
            }
          }
        
        before do
          # Setup: Create test data
          auth_headers
          Workout.create!(user: user, name: "Test Workout", performed_at: Time.current)
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]).to be_an(Array)
          expect(data["data"].first["name"]).to eq("Test Workout")
        end
      end
      
      response "401", "unauthorized" do
        schema type: :object,
          properties: {
            error: { type: :string, example: "Authentication required" }
          }
        
        run_test!
      end
    end

    post "Create a workout" do
      tags "Workouts"
      consumes "application/json"
      produces "application/json"
      description "Creates a new workout for the authenticated user"
      
      parameter name: :workout, in: :body, schema: {
        type: :object,
        properties: {
          name: { 
            type: :string, 
            example: "Evening Run",
            description: "Name of the workout"
          },
          performed_at: { 
            type: :string, 
            format: "date-time",
            example: "2025-11-22T10:00:00Z",
            description: "When the workout was performed"
          },
          notes: { 
            type: :string, 
            example: "Felt great!",
            description: "Optional notes about the workout",
            nullable: true
          }
        },
        required: ["name", "performed_at"]
      }
      
      response "201", "workout created" do
        let(:workout) do
          {
            name: "Morning Run",
            performed_at: Time.current.iso8601,
            notes: "Great session"
          }
        end
        
        before { auth_headers }
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["name"]).to eq("Morning Run")
        end
      end
      
      response "422", "invalid request" do
        let(:workout) { { name: "" } }
        
        before { auth_headers }
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["errors"]).to be_present
        end
      end
      
      response "401", "unauthorized" do
        let(:workout) { { name: "Test" } }
        
        run_test!
      end
    end
  end
end
```

### Step 2: Generate the Documentation

Run this command to generate the OpenAPI spec from your tests:

```bash
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
```

This will:
1. Run your specs
2. Generate `swagger/v1/swagger.yaml`
3. Update the Swagger UI

### Step 3: View Your New Docs

Refresh **http://localhost:3000/api-docs** to see your new endpoints!

---

## 🎨 Best Practices

### 1. Use Descriptive Examples

```ruby
# ❌ Bad - Generic
properties: {
  name: { type: :string, example: "string" }
}

# ✅ Good - Realistic
properties: {
  name: { 
    type: :string, 
    example: "Morning Cardio Session",
    description: "A descriptive name for the workout"
  }
}
```

### 2. Document All Response Codes

```ruby
response "200", "success" do
  # ...
end

response "401", "unauthorized" do
  # ...
end

response "422", "validation error" do
  # ...
end

response "404", "not found" do
  # ...
end
```

### 3. Use Tags to Organize

```ruby
path "/api/v1/workouts" do
  get "List workouts" do
    tags "Workouts"  # Groups endpoints in Swagger UI
    # ...
  end
end

path "/api/v1/exercises" do
  get "List exercises" do
    tags "Exercises"  # Separate section
    # ...
  end
end
```

### 4. Document Authentication

```ruby
# In spec/swagger_helper.rb, add security schemes:
config.openapi_specs = {
  "v1/swagger.yaml" => {
    openapi: "3.0.1",
    info: {
      title: "VitalForge API V1",
      version: "v1"
    },
    components: {
      securitySchemes: {
        csrf_token: {
          type: :apiKey,
          name: "X-CSRF-Token",
          in: :header,
          description: "CSRF token from cookies"
        },
        session_cookie: {
          type: :apiKey,
          name: "Cookie",
          in: :header,
          description: "Session cookie (set automatically after login)"
        }
      }
    },
    security: [
      { csrf_token: [], session_cookie: [] }
    ]
  }
}
```

Then in your specs:
```ruby
path "/api/v1/workouts" do
  get "List workouts" do
    tags "Workouts"
    security [ { csrf_token: [], session_cookie: [] } ]
    # ...
  end
end
```

---

## 🔧 Common Patterns

### Pattern 1: Authenticated Endpoint

```ruby
let(:user) { User.create!(email: "test@example.com", password: "Password123!", first_name: "Test", last_name: "User") }

before do
  # Get CSRF token
  get api_v1_current_user_path, as: :json
  csrf_token = cookies["CSRF-TOKEN"]
  
  # Login
  post api_v1_login_path,
    params: { user: { email: user.email, password: "Password123!" } },
    headers: { "X-CSRF-Token" => csrf_token },
    as: :json
end

response "200", "success" do
  run_test!
end
```

### Pattern 2: Nested Resources

```ruby
path "/api/v1/workouts/{workout_id}/exercises" do
  parameter name: :workout_id, in: :path, type: :integer, description: "Workout ID"
  
  get "List exercises for a workout" do
    tags "Workout Exercises"
    produces "application/json"
    
    response "200", "exercises found" do
      let(:workout) { Workout.create!(user: user, name: "Test", performed_at: Time.current) }
      let(:workout_id) { workout.id }
      
      before { auth_headers }
      
      run_test!
    end
  end
end
```

### Pattern 3: Query Parameters

```ruby
path "/api/v1/workouts" do
  get "List workouts with filters" do
    tags "Workouts"
    produces "application/json"
    
    parameter name: :start_date, in: :query, type: :string, format: :date, required: false, description: "Filter by start date"
    parameter name: :end_date, in: :query, type: :string, format: :date, required: false, description: "Filter by end date"
    parameter name: :page, in: :query, type: :integer, required: false, description: "Page number"
    parameter name: :per_page, in: :query, type: :integer, required: false, description: "Items per page"
    
    response "200", "workouts found" do
      let(:start_date) { "2025-01-01" }
      let(:end_date) { "2025-12-31" }
      let(:page) { 1 }
      let(:per_page) { 20 }
      
      before { auth_headers }
      
      run_test!
    end
  end
end
```

---

## 🌐 Exporting for Next.js

### Option 1: Generate TypeScript Types

Use **openapi-typescript** to generate TypeScript types from your OpenAPI spec:

```bash
# In your Next.js project
npm install --save-dev openapi-typescript

# Generate types
npx openapi-typescript http://localhost:3000/api-docs/v1/swagger.yaml -o types/api.ts
```

Then use in your Next.js code:
```typescript
import type { paths } from './types/api';

type WorkoutsResponse = paths['/api/v1/workouts']['get']['responses']['200']['content']['application/json'];

async function getWorkouts(): Promise<WorkoutsResponse> {
  const res = await fetch('http://localhost:3000/api/v1/workouts', {
    credentials: 'include',
    headers: {
      'X-CSRF-Token': getCsrfToken()
    }
  });
  return res.json();
}
```

### Option 2: Import into Postman/Bruno

1. Download the spec: `http://localhost:3000/api-docs/v1/swagger.yaml`
2. Import into Postman or Bruno
3. All endpoints are ready to test

---

## 🛠 Troubleshooting

### Issue: Specs Pass But Docs Don't Generate

**Problem:** `rswag:specs:swaggerize` doesn't update `swagger.yaml`

**Solution:**
1. Check `spec/swagger_helper.rb` is configured correctly
2. Ensure specs use `require "swagger_helper"` (not `rails_helper`)
3. Run with verbose output: `RAILS_ENV=test bundle exec rake rswag:specs:swaggerize --trace`

### Issue: Authentication Fails in Swagger UI

**Problem:** Can't test authenticated endpoints in Swagger UI

**Solution:**
Session-based auth doesn't work well in Swagger UI. Options:
1. **Use Postman/Bruno** for testing (better for session auth)
2. **Add a test token endpoint** (for Swagger UI only)
3. **Document the manual flow** in your API docs

### Issue: Schema Validation Errors

**Problem:** `run_test!` fails with "Response body doesn't match schema"

**Solution:**
1. Check your schema matches the actual response
2. Use `nullable: true` for optional fields
3. Test manually first: `puts response.body` in the spec

---

## 📊 Current API Documentation

### Documented Endpoints

✅ **Authentication**
- `POST /login` - HTML login (for ERB pages)
- `DELETE /logout` - HTML logout
- `POST /api/v1/login` - JSON login (for Next.js)
- `DELETE /api/v1/logout` - JSON logout
- `GET /api/v1/current_user` - Get current user
- `GET /api/v1/csrf` - Get CSRF token

✅ **Users**
- `POST /users` - Create user account

### To Be Documented

🔲 **Workouts**
- `GET /api/v1/workouts` - List workouts
- `POST /api/v1/workouts` - Create workout
- `GET /api/v1/workouts/:id` - Get workout
- `PATCH /api/v1/workouts/:id` - Update workout
- `DELETE /api/v1/workouts/:id` - Delete workout

🔲 **Exercises**
- `GET /api/v1/exercises` - List exercises
- `GET /api/v1/exercises/:id` - Get exercise

🔲 **Workout Exercises**
- `POST /api/v1/workouts/:workout_id/exercises` - Add exercise to workout
- `DELETE /api/v1/workouts/:workout_id/exercises/:id` - Remove exercise

---

## 🎓 Learning Resources

- [Rswag Documentation](https://github.com/rswag/rswag)
- [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- [Swagger UI](https://swagger.io/tools/swagger-ui/)
- [openapi-typescript](https://github.com/drwpow/openapi-typescript)

---

## 🚦 Quick Commands

```bash
# Generate API docs from specs
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize

# Run only API specs
bundle exec rspec spec/requests/api

# View docs
open http://localhost:3000/api-docs

# Download OpenAPI spec
curl http://localhost:3000/api-docs/v1/swagger.yaml > openapi.yaml
```

---

**Happy API Documenting! 🎉**

