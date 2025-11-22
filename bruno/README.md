# Bruno Collection - VitalForge Auth

This folder contains a Bruno collection for testing the VitalForge authentication API.

## Requests

- Auth/Csrf → GET `{{baseUrl}}/api/v1/csrf`
- Auth/Login → POST `{{baseUrl}}/api/v1/session`
- Auth/CurrentUser → GET `{{baseUrl}}/api/v1/current_user`
- Auth/Logout → DELETE `{{baseUrl}}/api/v1/session`

## Usage

1. Open this folder in Bruno.
2. Ensure cookie jar is enabled (Bruno manages cookies automatically).
3. Environment variables:
   - `baseUrl` (default: `http://localhost:3000`)
   - `email`, `password` (for your test user)
4. Run in order:
   - GET Csrf → this sets `CSRF-TOKEN` cookie
   - POST Login → Headers: `X-CSRF-Token` = cookie value; Body nested under `user`
   - GET CurrentUser → should return 200 with user JSON
   - DELETE Logout → Headers: `X-CSRF-Token` required; returns 204

Notes:
- Do not hand-write a `Cookie` header; let the cookie jar send cookies.
- 401 = invalid credentials; 422 = CSRF verification failed (likely missing/incorrect header or cookies).
