# Railway Production Deployment Checklist

After pushing the Swagger Basic Auth changes to production, follow these steps to enable and test the API documentation.

## 1. Set Environment Variables in Railway

Navigate to your Railway service (vital-forge-v1) → Variables tab and add:

```bash
SWAGGER_ENABLED=true
SWAGGER_BASIC_AUTH_USERNAME=<choose-secure-username>
SWAGGER_BASIC_AUTH_PASSWORD=<generate-strong-password>
```

**Password Generation Tip**: Use a password manager to generate a strong random password (24+ characters with mixed case, numbers, and symbols).

Example using command line:
```bash
# Generate a secure random password
openssl rand -base64 24
```

## 2. Redeploy the Service

After adding the environment variables:
- Railway will automatically trigger a new deployment
- Wait for the deployment to complete (check the Deployments tab)
- Verify the service is running and healthy at `https://api.forge-fitness-journal.app/api/v1/health`

## 3. Test Swagger Access

### Test 1: Verify Auth Prompt
1. Visit `https://api.forge-fitness-journal.app/api-docs` in a browser
2. You should see a browser Basic Auth login prompt
3. ✅ **Expected**: Login prompt appears
4. ❌ **If 404**: Check that `SWAGGER_ENABLED=true` is set

### Test 2: Verify Auth Protection
1. Click "Cancel" on the auth prompt
2. ✅ **Expected**: "401 Unauthorized" error
3. ❌ **If you see Swagger UI**: Auth is not working correctly

### Test 3: Verify Valid Credentials
1. Visit `https://api.forge-fitness-journal.app/api-docs` again
2. Enter the username and password you set in Railway
3. ✅ **Expected**: Swagger UI loads and displays API endpoints
4. ❌ **If 401**: Double-check credentials match Railway variables exactly (case-sensitive)

### Test 4: Verify OpenAPI Spec Access
1. While on the Swagger UI page, check that the spec loads (UI will show endpoints, not errors)
2. Directly visit `https://api.forge-fitness-journal.app/openapi/v1/swagger.yaml`
3. ✅ **Expected**: Browser prompts for auth, then displays YAML content
4. ❌ **If blank or error**: Check Railway logs for errors

### Test 5: Verify Disabling Works
1. In Railway, set `SWAGGER_ENABLED=false` or remove the variable
2. Redeploy/restart
3. Visit `https://api.forge-fitness-journal.app/api-docs`
4. ✅ **Expected**: 404 Not Found
5. Re-enable by setting `SWAGGER_ENABLED=true` and redeploying

## 4. Share Credentials with Collaborators

### Secure Sharing Methods

**Option 1: Password Manager (Recommended)**
- Store credentials in 1Password/Bitwarden/LastPass
- Share via secure vault sharing feature
- Collaborator adds to their own password manager

**Option 2: Encrypted Messaging**
- Use Signal, encrypted email, or similar secure channel
- Send username and password separately
- Delete messages after collaborator confirms receipt

**What to Share**:
```
Swagger API Documentation Access:
URL: https://api.forge-fitness-journal.app/api-docs
Username: [your_username]
Password: [your_password]

Instructions: Visit the URL, enter credentials when prompted.
```

### Rotating Credentials

To change credentials (e.g., when a collaborator leaves):
1. Generate new password
2. Update `SWAGGER_BASIC_AUTH_PASSWORD` in Railway
3. Redeploy service
4. Share new credentials with authorized collaborators
5. Old password is immediately invalid

## 5. Monitor and Troubleshoot

### Check Railway Logs
```bash
# From terminal with Railway CLI
railway logs -s vital-forge-v1 -e production
```

Look for:
- Swagger middleware initialization
- Any authentication errors
- 401/404 responses to `/api-docs` or `/openapi/*`

### Common Issues

**Issue**: 404 on `/api-docs`
- **Fix**: Set `SWAGGER_ENABLED=true` in Railway and redeploy

**Issue**: No auth prompt, Swagger loads without login
- **Fix**: Check that middleware is loaded (logs should show it at startup)
- **Fix**: Verify credentials are set in Railway variables

**Issue**: Auth prompt loops (keeps asking for credentials)
- **Fix**: Check username/password exactly match Railway variables (case-sensitive)
- **Fix**: Clear browser cached credentials for that domain

**Issue**: Swagger UI loads but can't fetch spec
- **Fix**: Check that `swagger/v1/swagger.yaml` exists in repo
- **Fix**: Verify `/openapi/v1/swagger.yaml` is accessible with same credentials

## 6. Files Changed (For Reference)

The following files were modified to implement Swagger Basic Auth:

1. **`Gemfile`**: Moved `rswag-api` and `rswag-ui` out of `:development` group
2. **`config/routes.rb`**: Added `SWAGGER_ENABLED` flag check
3. **`config/application.rb`**: Added SwaggerAuth middleware
4. **`config/initializers/rswag_ui.rb`**: Enabled Rswag's built-in basic auth
5. **`lib/middleware/swagger_auth.rb`**: New middleware for HTTP Basic Auth
6. **`lib/constraints/swagger_basic_auth.rb`**: New constraint for credential validation
7. **`.env`**: Added local testing credentials (not committed)
8. **`documentation/SWAGGER_SETUP.md`**: New documentation file

## 7. Security Notes

- ✅ Credentials are stored in Railway environment variables (not in git)
- ✅ TLS/HTTPS protects credentials in transit
- ✅ `secure_compare` prevents timing attacks
- ✅ Two layers of auth (middleware + Rswag built-in)
- ⚠️ Basic Auth is only as secure as the password strength
- ⚠️ Consider also protecting `/sidekiq` web UI similarly

## 8. Next Steps (Optional)

Consider also protecting other admin routes:
- `/sidekiq` - Sidekiq Web UI (currently unprotected)

You can use the same middleware pattern for these routes.
