# app/services/ai_services/weekly_workout_feedback_service.rb
module AiServices
  class WeeklyWorkoutFeedbackService
    def initialize(user, stats: nil)
      @user = user
      @stats = stats
      @client = AiServices::BaseClient.new
    end

    def generate
      ## Create instance of the workout service calc method
      stats = @stats || WeeklyProgressCalculator.new(@user).calculate

      return no_workout_message if stats[:total_workouts].zero?

      prompt = build_prompt(stats)
      response = @client.chat_completion(
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: prompt }
        ],
        model: "gpt-4o-mini",
        temperature: 0.7,
        max_tokens: 300
      )

      # Extract the feedback text from the response (OpenAI gem returns an object)
      response.choices[0].message.content || fallback_message
    rescue StandardError => e
      Rails.logger.error("Failed to generate weekly feedback: #{e.message}")
      fallback_message
    end

    private

    def system_prompt
      <<~PROMPT
        You are an enthusiastic and supportive personal fitness trainer providing weekly progress feedback.
        Your tone should be motivating, positive, and personalized.
        Keep responses concise (2-3 paragraphs).
        Always acknowledge specific achievements and provide actionable encouragement.
      PROMPT
    end

    def build_prompt(stats)
      <<~PROMPT
        Please provide personalized weekly workout feedback for a user with the following stats:

        - Total Workouts Completed: #{stats[:total_workouts]}
        - Total Sets: #{stats[:total_sets]}
        - Total Volume (lbs): #{stats[:total_volume]}
        - Total Duration: #{stats[:total_duration]} minutes
        - Current Streak: #{stats[:streak]} days
        - Most Common Exercise: #{stats[:most_common_exercise] || 'Various exercises'}

        Provide:
        1. Acknowledgment of their specific accomplishments this week
        2. One specific observation about their workout patterns
        3. Suggest exercises to balance their routine and improve their overall fitness
        4. Brief motivational encouragement to keep going
      PROMPT
    end

    def no_workout_message
      <<~MESSAGE
        Hey there! 👋

        We noticed you haven't logged any workouts this week yet. No worries - every journey has its own pace!

        Remember, even a short 15-minute session counts. Your next workout is always the most important one.
        Ready to get back on track? Let's do this! 💪
      MESSAGE
    end

    def fallback_message
      <<~MESSAGE
        Great work this week! 🎉

        We're tracking your progress and you're making strides. Keep up the consistency -#{' '}
        every workout brings you closer to your goals. Stay strong! 💪
      MESSAGE
    end
  end
end
