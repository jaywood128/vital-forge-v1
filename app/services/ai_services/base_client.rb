# app/services/ai_services/base_client.rb
module AiServices
  class BaseClient
    attr_reader :client

    def initialize(api_key: nil, timeout: 60, max_retries: 2)
      @api_key = api_key || ENV.fetch("OPENAI_API_KEY")
      @timeout = timeout
      @max_retries = max_retries
      @client = build_client
    end

    def chat_completion(messages:, model: "gpt-4o-mini", **options)
      client.chat.completions.create(
        messages: messages,
        model: model,
        **options
      )
    rescue ::OpenAI::Errors::APIError => e
      Rails.logger.error("OpenAI API Error: #{e.message}")
      raise
    rescue StandardError => e
      Rails.logger.error("OpenAI Client Error: #{e.message}")
      raise
    end

    private

    def build_client
      ::OpenAI::Client.new(
        api_key: @api_key,
        timeout: @timeout,
        max_retries: @max_retries
      )
    end
  end
end
