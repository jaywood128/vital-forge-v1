namespace :test do
  desc "Test OpenAI BaseClient connection"
  task openai_connection: :environment do
    puts "🔍 Testing OpenAI BaseClient connection..."
    puts "=" * 60

    begin
      client = AiServices::BaseClient.new
      puts "✅ Client initialized successfully"

      puts "\n📤 Sending test request to OpenAI..."
      response = client.chat_completion(
        messages: [ { role: "user", content: "Say hello in exactly 5 words" } ],
        model: "gpt-4o-mini"
      )

      content = response.dig("choices", 0, "message", "content")
      puts "✅ Response received!"
      puts "\n💬 OpenAI says: #{content}"
      puts "\n🎉 OpenAI integration is working!"

    rescue StandardError => e
      puts "❌ Error: #{e.message}"
      puts "\n💡 Troubleshooting:"
      puts "   1. Check that OPENAI_API_KEY is set in your .env file"
      puts "   2. Verify your API key is valid at platform.openai.com"
      puts "   3. Check your internet connection"
    end
  end

  desc "Test Weekly Workout Feedback Service"
  task weekly_feedback: :environment do
    user = User.first

    unless user
      puts "❌ No users found in database. Please create a user first."
      exit
    end

    puts "🔍 Testing Weekly Workout Feedback for: #{user.email}"
    puts "=" * 60

    puts "\n📊 Calculating weekly stats..."
    stats = WeeklyProgressCalculator.new(user).calculate

    puts "\n📈 Weekly Stats:"
    puts "  Total Workouts: #{stats[:total_workouts]}"
    puts "  Total Sets: #{stats[:total_sets]}"
    puts "  Total Volume: #{stats[:total_volume]} lbs"
    puts "  Total Duration: #{stats[:total_duration]} minutes"
    puts "  Streak: #{stats[:streak]} days"
    puts "  Most Common Exercise: #{stats[:most_common_exercise] || 'N/A'}"

    puts "\n🤖 Generating AI Feedback..."
    puts "-" * 60

    begin
      service = AiServices::WeeklyWorkoutFeedbackService.new(user)
      feedback = service.generate

      puts "\n#{feedback}"
      puts "\n" + "=" * 60
      puts "✅ Feedback generated successfully!"

    rescue StandardError => e
      puts "❌ Error generating feedback: #{e.message}"
      puts "\n💡 Check that your OPENAI_API_KEY is set correctly"
    end
  end
end
