namespace :test do
  desc "Test weekly progress email for first user"
  task weekly_email: :environment do
    user = User.first

    unless user
      puts "❌ No users found in database. Please create a user first."
      exit
    end

    puts "🔍 Testing weekly progress email for: #{user.email}"
    puts "📊 Calculating stats..."

    stats = WeeklyProgressCalculator.new(user).calculate

    puts "\n📈 Weekly Stats:"
    puts "  Total Workouts: #{stats[:total_workouts]}"
    puts "  Total Sets: #{stats[:total_sets]}"
    puts "  Total Volume: #{stats[:total_volume]} lbs"
    puts "  Total Duration: #{stats[:total_duration]} minutes"
    puts "  Streak: #{stats[:streak]} days"
    puts "  Most Common Exercise: #{stats[:most_common_exercise] || 'N/A'}"

    if stats[:total_workouts] == 0
      puts "\n⚠️  User has no workouts this week. Email will NOT be sent."
      puts "💡 Tip: Add some workout data first!"
    else
      puts "\n📧 Sending email..."
      WorkoutMailer.weekly_progress(user, stats).deliver_now
      puts "✅ Email sent! Check MailCatcher at http://localhost:1080"
    end
  end
end

