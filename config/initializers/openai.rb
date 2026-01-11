require "openai"

# Validate that the API key is present at boot time
# if Rails.env.production? && ENV["OPENAI_API_KEY"].blank?
#   Rails.logger.warn "WARNING: OPENAI_API_KEY is not set. OpenAI services will fail."
# end
