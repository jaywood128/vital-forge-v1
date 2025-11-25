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
- `POST /login` - User login
- `DELETE /logout` - User logout

### Users
- `GET /signup` - Show registration form
- `POST /users` - Create user account

### Dashboard
- `GET /dashboard` - Protected dashboard (requires auth)

## 🚀 Future: JSON API Endpoints

When you build JSON API endpoints for your React frontend, you'll want to:

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

