Rails.application.config.session_store :cookie_store,
  key: "_vital_forge_session",
  # Secure cookies in production and staging (both use HTTPS)
  secure: !Rails.env.development?,
  httponly: true,
  # Use :lax for better compatibility; change to :none if you need true cross-site requests
  same_site: :lax,
  expire_after: 2.weeks
