namespace :test do
  desc "Test Weekly Feedback API endpoint"
  task weekly_feedback_api: :environment do
    user = User.first

    unless user
      puts "❌ No users found in database. Please create a user first."
      exit
    end

    puts "=" * 70
    puts "Testing Weekly Feedback API Endpoint"
    puts "=" * 70
    puts "\n🔍 Testing for user: #{user.email} (ID: #{user.id})"

    # Test 1: Check if feedback exists
    feedback = user.weekly_feedbacks
      .where("week_start >= ?", Date.current.beginning_of_week)
      .first

    if feedback
      puts "\n✅ Found cached feedback for this week:"
      puts "   Week Start: #{feedback.week_start}"
      puts "   Generated: #{feedback.generated_at}"
      puts "   Feedback Preview: #{feedback.feedback_text[0..100]}..."
      puts "\n📊 Stats Snapshot:"
      feedback.stats_snapshot&.each do |key, value|
        puts "   #{key}: #{value}"
      end
    else
      puts "\n⚠️  No cached feedback found for this week"
      puts "   Generating feedback now..."

      # Generate it
      GenerateWeeklyFeedbackJob.perform_async(user.id)
      puts "   Job queued! Check Sidekiq dashboard: http://localhost:3000/sidekiq"
      puts "   Wait 5-10 seconds, then run this task again to see cached feedback."
    end

    puts "\n" + "=" * 70
    puts "API Endpoint Details:"
    puts "=" * 70
    puts "  GET /api/v1/weekly_feedbacks/current"
    puts "  Authentication: Required (session or JWT)"
    puts "  Response (cached): 200 OK with feedback data"
    puts "  Response (generating): 202 Accepted"
    puts "\n💡 Test with curl:"
    puts '  curl -H "Cookie: _session_id=..." http://localhost:3000/api/v1/weekly_feedbacks/current'
    puts "\n✅ Test complete!"
  end
end
