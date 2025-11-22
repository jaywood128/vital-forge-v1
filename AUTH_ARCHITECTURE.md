# 🔐 Authentication Architecture: Next.js + Rails API

This document explains the authentication flow between our **Next.js frontend** and **Rails 8 backend**.

## 🏗 Overview

We use a **Cookie-based Session Authentication** mechanism.
This is more secure than JWTs in local storage because it leverages `HttpOnly` cookies, which cannot be accessed by JavaScript (preventing XSS attacks).

### 🧩 The Components

1.  **Rails Backend**: Acts as the session authority. Sets `HttpOnly` cookies.
2.  **Next.js Frontend**: Sends credentials, receives cookies, and includes them in subsequent requests via `credentials: 'include'`.

---

## 🍪 Cross-Site Request Forgery (CSRF) Protection

Since our frontend (e.g., `localhost:3001`) and backend (`localhost:3000`) run on different origins (ports), we must handle Cross-Origin Resource Sharing (CORS) and CSRF carefully.

### 1. The `SameSite` Cookie Policy

We explicitly set the `SameSite` attribute on our session and CSRF cookies to allow cross-site requests in production.

**File:** `app/controllers/application_controller.rb` & `app/controllers/api/v1/sessions_controller.rb`

```ruby
cookies["CSRF-TOKEN"] = {
  value: form_authenticity_token,
  # PRODUCTION: :none allows the cookie to be sent in cross-site requests (secure must be true)
  # DEVELOPMENT: :lax is standard for local development
  same_site: Rails.env.production? ? :none : :lax,
  secure: Rails.env.production? # Must be true if same_site is :none
}
```

### 2. CORS Configuration

We allow the Next.js origin to make requests and—crucially—send credentials (cookies).

**File:** `config/initializers/cors.rb`

We use strict **Environment Variable Whitelisting**. The API will ONLY accept requests from domains listed in `ALLOWED_ORIGINS`.

```ruby
# config/initializers/cors.rb
allow do
  origins do |source, env|
    # Loads from ENV or defaults to localhost:3001
    allowed_origins = ENV.fetch('ALLOWED_ORIGINS', 'http://localhost:3001').split(',')
    allowed_origins.include?(source)
  end
  
  resource '*',
    headers: :any,
    credentials: true # ALLOWS COOKIES TO BE SENT/RECEIVED
end
```

**Configuration:**
*   **Development**: Defaults to `http://localhost:3001`.
*   **Production**: Set `ALLOWED_ORIGINS="https://your-app.com,https://admin.your-app.com"`

This prevents unauthorized domains from making requests, even if they somehow got a valid token (though the HttpOnly cookie prevents them from reading it anyway).

---

## 🔄 The Login Flow

1.  **Frontend**: `POST /api/v1/login` with email/password.
2.  **Backend**:
    *   Validates user.
    *   Resets the session (prevents session fixation).
    *   Sets `session[:user_id]` (encrypted HTTP-only cookie).
    *   Sets `CSRF-TOKEN` (readable cookie).
3.  **Frontend**: Receives `200 OK`. The browser automatically stores the cookies.

## 📡 Making Authenticated Requests

For every subsequent request (e.g., `GET /api/v1/workouts`), the frontend **MUST** include:

1.  `credentials: 'include'` (to send the session cookie).
2.  `X-CSRF-Token` header (value read from the `CSRF-TOKEN` cookie).

### Example (Next.js / Fetch)

```javascript
// 1. Get the CSRF token from the cookie (using a library like 'js-cookie')
import Cookies from 'js-cookie';
const csrfToken = Cookies.get('CSRF-TOKEN');

// 2. Make the request
const response = await fetch('http://localhost:3000/api/v1/dashboard', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken // REQUIRED for non-GET requests
  },
  credentials: 'include' // REQUIRED to send the session cookie
});
```

---

## 🛡 Error Handling

We return **JSON errors** instead of HTML pages for API issues.

**File:** `app/controllers/api/v1/base_controller.rb`

*   **401 Unauthorized**: When `logged_in?` is false.
*   **422 Unprocessable Entity**: When CSRF token is missing/invalid (`ActionController::InvalidAuthenticityToken`).

```ruby
rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_authenticity_token

def render_invalid_authenticity_token
  render json: { error: "Invalid or missing CSRF token" }, status: :unprocessable_entity
end
```

---

## 📝 Summary for Developers

*   **Always** use `credentials: 'include'` in frontend fetch calls.
*   **Always** read the `CSRF-TOKEN` cookie and send it as `X-CSRF-Token` header for mutations (POST/PUT/DELETE).
*   **Never** try to access the session cookie via JavaScript (it's HttpOnly).

