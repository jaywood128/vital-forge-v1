Rails.application.config.session_store :cookie_store,
  key: "_vital_forge_session",
  secure: Rails.env.production?,   # must be true with SameSite=None
  httponly: true,
  same_site: Rails.env.production? ? :none : :lax,
  expire_after: 2.weeks

