Rails.application.config.session_store :cookie_store,
  key: "_vital_forge_session",
  # In production this must remain true because SameSite=None requires Secure
  secure: Rails.env.production?,
  httponly: true,
  # Allow cross-site requests (e.g., localhost:3001 -> localhost:3000) in dev
  # while keeping production cross-site capable with Secure=true.
  same_site: :lax,
  expire_after: 2.weeks
