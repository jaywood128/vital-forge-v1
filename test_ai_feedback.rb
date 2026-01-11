#!/usr/bin/env ruby
# Quick test script for AI feedback service
# Run with: ruby test_ai_feedback.rb

require_relative 'config/environment'

puts "=" * 70
puts "Testing AI Services Setup"
puts "=" * 70

# Test 1: Check if classes load
print "\n1. Loading AiServices::BaseClient... "
begin
  client = AiServices::BaseClient.new
  puts "✅ SUCCESS"
rescue StandardError => e
  puts "❌ FAILED: #{e.message}"
  exit 1
end

# Test 2: Simple API call
print "2. Testing OpenAI API connection... "
begin
  response = client.chat_completion(
    messages: [ { role: "user", content: "Say 'test successful' in 2 words" } ]
  )
  result = response.dig("choices", 0, "message", "content")
  puts "✅ SUCCESS"
  puts "   Response: #{result}"
rescue StandardError => e
  puts "❌ FAILED: #{e.message}"
  puts "   Make sure OPENAI_API_KEY is set in your .env file"
  exit 1
end

# Test 3: Load WeeklyWorkoutFeedbackService
print "\n3. Loading AiServices::WeeklyWorkoutFeedbackService... "
begin
  user = User.first
  unless user
    puts "⚠️  No users found. Skipping service test."
    exit 0
  end

  service = AiServices::WeeklyWorkoutFeedbackService.new(user)
  puts "✅ SUCCESS"
rescue StandardError => e
  puts "❌ FAILED: #{e.message}"
  exit 1
end

# Test 4: Generate feedback
print "4. Generating AI feedback for #{user.email}... "
begin
  feedback = service.generate
  puts "✅ SUCCESS\n"
  puts "=" * 70
  puts "Generated Feedback:"
  puts "=" * 70
  puts feedback
  puts "=" * 70
  puts "\n✅ All tests passed!"
rescue StandardError => e
  puts "❌ FAILED: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
