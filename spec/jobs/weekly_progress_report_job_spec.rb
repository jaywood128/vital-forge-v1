require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe WeeklyProgressReportJob, type: :job do
  # Clear Sidekiq job queue before each test
  before do
    Sidekiq::Worker.clear_all
  end

  # Include ActiveJob test helpers
  include ActiveJob::TestHelper

  let(:exercise) do
    Exercise.create!(
      name: 'Bench Press',
      exercise_type: 'Strength',
      muscle_group: 'Chest',
      equipment: 'Barbell'
    )
  end

  describe '#perform' do
    context 'with users who have workouts this week' do
      let!(:user1) do
        User.create!(
          email: 'user1@example.com',
          password: 'Password123!',
          first_name: 'User',
          last_name: 'One'
        )
      end

      let!(:user2) do
        User.create!(
          email: 'user2@example.com',
          password: 'Password123!',
          first_name: 'User',
          last_name: 'Two'
        )
      end

      let!(:user3_no_workout) do
        User.create!(
          email: 'user3@example.com',
          password: 'Password123!',
          first_name: 'User',
          last_name: 'Three'
        )
      end

      before do
        # User 1: has a workout from 3 days ago
        workout1 = user1.workouts.create!(
          name: 'Test Workout 1',
          workout_date: 3.days.ago,
          duration_minutes: 45,
          completed: true
        )
        we1 = workout1.workout_exercises.create!(exercise: exercise, order_position: 1, completed: true)
        we1.exercise_sets.create!(set_number: 1, weight: 100, reps: 10, completed: true)

        # User 2: has a workout from yesterday
        workout2 = user2.workouts.create!(
          name: 'Test Workout 2',
          workout_date: 1.day.ago,
          duration_minutes: 30,
          completed: true
        )
        we2 = workout2.workout_exercises.create!(exercise: exercise, order_position: 1, completed: true)
        we2.exercise_sets.create!(set_number: 1, weight: 80, reps: 12, completed: true)

        # User 3: No workouts (should be skipped)
      end

      it 'only queues jobs for users with workouts this week' do
        Sidekiq::Testing.fake! do
          described_class.new.perform

          # Should only queue jobs for user1 and user2 (not user3)
          expect(SendWeeklyProgressEmailJob.jobs.size).to eq(2)
          expect(GenerateWeeklyFeedbackJob.jobs.size).to eq(2)
        end
      end

      it 'passes correct user_ids to email jobs' do
        Sidekiq::Testing.fake! do
          described_class.new.perform

          user_ids = SendWeeklyProgressEmailJob.jobs.map { |job| job['args'].first }
          expect(user_ids).to match_array([ user1.id, user2.id ])
          expect(user_ids).not_to include(user3_no_workout.id)
        end
      end

      it 'passes correct user_ids to AI feedback jobs' do
        Sidekiq::Testing.fake! do
          described_class.new.perform

          user_ids = GenerateWeeklyFeedbackJob.jobs.map { |job| job['args'].first }
          expect(user_ids).to match_array([ user1.id, user2.id ])
          expect(user_ids).not_to include(user3_no_workout.id)
        end
      end

      it 'logs start message' do
        allow(Rails.logger).to receive(:info)

        Sidekiq::Testing.fake! do
          described_class.new.perform
        end

        expect(Rails.logger).to have_received(:info)
          .with("Starting weekly progress report generation for all users")
      end

      it 'logs comprehensive summary with skip count' do
        allow(Rails.logger).to receive(:info)

        Sidekiq::Testing.fake! do
          described_class.new.perform
        end

        # Should log the new comprehensive summary
        expect(Rails.logger).to have_received(:info)
          .with(/2 email jobs \+ 2 AI feedback jobs queued for 2 active users \(1 users skipped - no workouts this week\)/)
      end
    end

    context 'with no users who worked out' do
      let!(:inactive_user) do
        User.create!(
          email: 'inactive@example.com',
          password: 'Password123!',
          first_name: 'Inactive',
          last_name: 'User'
        )
      end

      it 'handles no active users gracefully' do
        expect {
          Sidekiq::Testing.fake! do
            described_class.new.perform
          end
        }.not_to raise_error
      end

      it 'queues zero jobs' do
        Sidekiq::Testing.fake! do
          described_class.new.perform
          expect(SendWeeklyProgressEmailJob.jobs.size).to eq(0)
          expect(GenerateWeeklyFeedbackJob.jobs.size).to eq(0)
        end
      end

      it 'logs that all users were skipped' do
        allow(Rails.logger).to receive(:info)

        Sidekiq::Testing.fake! do
          described_class.new.perform
        end

        expect(Rails.logger).to have_received(:info)
          .with(/0 active users \(1 users skipped - no workouts this week\)/)
      end
    end

    context 'with large number of active users' do
      before do
        # Create 50 users with workouts this week
        50.times do |i|
          user = User.create!(
            email: "user#{i}@example.com",
            password: 'Password123!',
            first_name: 'User',
            last_name: i.to_s
          )
          workout = user.workouts.create!(
            name: "Workout #{i}",
            workout_date: 2.days.ago,
            duration_minutes: 30,
            completed: true
          )
          we = workout.workout_exercises.create!(exercise: exercise, order_position: 1, completed: true)
          we.exercise_sets.create!(set_number: 1, weight: 100, reps: 10, completed: true)
        end
      end

      it 'processes all active users efficiently' do
        Sidekiq::Testing.fake! do
          expect {
            described_class.new.perform
          }.not_to raise_error

          expect(SendWeeklyProgressEmailJob.jobs.size).to eq(50)
          expect(GenerateWeeklyFeedbackJob.jobs.size).to eq(50)
        end
      end
    end

    context 'when job queueing fails' do
      let!(:user) do
        User.create!(
          email: 'test@example.com',
          password: 'Password123!',
          first_name: 'Test',
          last_name: 'User'
        )
      end

      before do
        # Create a workout so user is included
        workout = user.workouts.create!(
          name: 'Test Workout',
          workout_date: 2.days.ago,
          completed: true
        )
        we = workout.workout_exercises.create!(exercise: exercise, order_position: 1, completed: true)
        we.exercise_sets.create!(set_number: 1, weight: 100, reps: 10, completed: true)

        # Mock failure
        allow(SendWeeklyProgressEmailJob).to receive(:perform_async).and_raise(StandardError.new("Connection failed"))
      end

      it 'raises error for retry' do
        expect {
          described_class.new.perform
        }.to raise_error(StandardError, "Connection failed")
      end

      it 'logs error message' do
        allow(Rails.logger).to receive(:error)

        expect {
          described_class.new.perform
        }.to raise_error(StandardError)

        expect(Rails.logger).to have_received(:error)
          .with(/Failed to generate weekly progress reports: Connection failed/)
      end
    end
  end

  describe 'scheduled execution' do
    it 'is scheduled to run via sidekiq-cron' do
      # This tests that the job is configured in schedule.yml
      schedule_file = Rails.root.join('config', 'schedule.yml')
      expect(File.exist?(schedule_file)).to be true

      schedule = YAML.load_file(schedule_file)
      expect(schedule['weekly_progress_report']).to be_present
      expect(schedule['weekly_progress_report']['class']).to eq('WeeklyProgressReportJob')
      expect(schedule['weekly_progress_report']['cron']).to eq('0 8 * * 1')
    end
  end
end
