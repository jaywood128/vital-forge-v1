require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe GenerateWeeklyFeedbackJob, type: :job do
  # Clear Sidekiq job queue before each test
  before do
    Sidekiq::Worker.clear_all
    # Enable AI features for testing
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ENABLE_AI_FEATURES", "false").and_return("true")
  end

  let(:user) do
    User.create!(
      email: 'test@example.com',
      password: 'Password123!',
      first_name: 'Test',
      last_name: 'User'
    )
  end

  let(:exercise) do
    Exercise.create!(
      name: 'Bench Press',
      exercise_type: 'Strength',
      muscle_group: 'Chest',
      equipment: 'Barbell'
    )
  end

  let(:weekly_stats) do
    {
      total_workouts: 3,
      total_sets: 12,
      total_volume: 3600,
      total_duration: 90,
      streak: 3,
      most_common_exercise: 'Bench Press'
    }
  end

  let(:ai_feedback_text) do
    "Great work this week! You completed 3 workouts and maintained a 3-day streak. Keep pushing forward!"
  end

  describe '#perform' do
    context 'when user exists and has workouts' do
      before do
        # Create workout data
        workout = user.workouts.create!(
          name: 'Test Workout',
          workout_date: 3.days.ago,
          duration_minutes: 45,
          completed: true
        )
        workout_exercise = workout.workout_exercises.create!(
          exercise: exercise,
          order_position: 1,
          completed: true
        )
        workout_exercise.exercise_sets.create!(
          set_number: 1,
          weight: 100,
          reps: 10,
          completed: true
        )

        # Mock the calculator to avoid actual calculation
        calculator = instance_double(WeeklyProgressCalculator)
        allow(WeeklyProgressCalculator).to receive(:new).with(user).and_return(calculator)
        allow(calculator).to receive(:calculate).and_return(weekly_stats)

        # Mock the AI service to avoid actual OpenAI API calls
        ai_service = instance_double(AiServices::WeeklyWorkoutFeedbackService)
        allow(AiServices::WeeklyWorkoutFeedbackService).to receive(:new)
          .with(user, stats: weekly_stats)
          .and_return(ai_service)
        allow(ai_service).to receive(:generate).and_return(ai_feedback_text)
      end

      it 'calculates weekly stats' do
        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        expect(WeeklyProgressCalculator).to have_received(:new).with(user)
      end

      it 'passes stats to AI service to avoid recalculation' do
        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        expect(AiServices::WeeklyWorkoutFeedbackService).to have_received(:new)
          .with(user, stats: weekly_stats)
      end

      it 'generates AI feedback' do
        ai_service = instance_double(AiServices::WeeklyWorkoutFeedbackService)
        allow(AiServices::WeeklyWorkoutFeedbackService).to receive(:new).and_return(ai_service)
        allow(ai_service).to receive(:generate).and_return(ai_feedback_text)

        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        expect(ai_service).to have_received(:generate)
      end

      it 'creates a WeeklyFeedback record' do
        expect {
          Sidekiq::Testing.inline! do
            described_class.perform_async(user.id)
          end
        }.to change { WeeklyFeedback.count }.by(1)
      end

      it 'stores feedback text correctly' do
        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        feedback = WeeklyFeedback.last
        expect(feedback.feedback_text).to eq(ai_feedback_text)
      end

      it 'stores stats snapshot correctly' do
        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        feedback = WeeklyFeedback.last
        expect(feedback.stats_snapshot).to eq(weekly_stats.stringify_keys)
      end

      it 'sets week_start to current week beginning' do
        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        feedback = WeeklyFeedback.last
        expect(feedback.week_start).to eq(Date.current.beginning_of_week)
      end

      it 'sets generated_at timestamp' do
        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        feedback = WeeklyFeedback.last
        expect(feedback.generated_at).to be_within(1.second).of(Time.current)
      end

      it 'associates feedback with correct user' do
        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        feedback = WeeklyFeedback.last
        expect(feedback.user).to eq(user)
      end

      it 'logs start message' do
        allow(Rails.logger).to receive(:info)

        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        expect(Rails.logger).to have_received(:info)
          .with("Generating AI feedback for user #{user.id}")
      end

      it 'logs success message with email' do
        allow(Rails.logger).to receive(:info)

        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        expect(Rails.logger).to have_received(:info)
          .with("Successfully saved AI feedback for user #{user.id} (#{user.email})")
      end
    end

    context 'when user does not exist' do
      it 'handles missing user gracefully' do
        expect {
          Sidekiq::Testing.inline! do
            described_class.perform_async(999999)
          end
        }.not_to raise_error
      end

      it 'does not create WeeklyFeedback record' do
        expect {
          Sidekiq::Testing.inline! do
            described_class.perform_async(999999)
          end
        }.not_to change { WeeklyFeedback.count }
      end

      it 'does not call WeeklyProgressCalculator' do
        allow(WeeklyProgressCalculator).to receive(:new)

        Sidekiq::Testing.inline! do
          described_class.perform_async(999999)
        end

        expect(WeeklyProgressCalculator).not_to have_received(:new)
      end

      it 'does not call AI service' do
        allow(AiServices::WeeklyWorkoutFeedbackService).to receive(:new)

        Sidekiq::Testing.inline! do
          described_class.perform_async(999999)
        end

        expect(AiServices::WeeklyWorkoutFeedbackService).not_to have_received(:new)
      end
    end

    context 'when AI service fails' do
      before do
        # Create workout data
        workout = user.workouts.create!(
          name: 'Test Workout',
          workout_date: 3.days.ago,
          completed: true
        )

        # Mock calculator
        calculator = instance_double(WeeklyProgressCalculator)
        allow(WeeklyProgressCalculator).to receive(:new).and_return(calculator)
        allow(calculator).to receive(:calculate).and_return(weekly_stats)

        # Mock AI service to raise an error
        ai_service = instance_double(AiServices::WeeklyWorkoutFeedbackService)
        allow(AiServices::WeeklyWorkoutFeedbackService).to receive(:new).and_return(ai_service)
        allow(ai_service).to receive(:generate).and_raise(StandardError.new("OpenAI API timeout"))
      end

      it 'raises error for Sidekiq retry' do
        expect {
          Sidekiq::Testing.inline! do
            described_class.perform_async(user.id)
          end
        }.to raise_error(StandardError, "OpenAI API timeout")
      end

      it 'logs error message' do
        allow(Rails.logger).to receive(:error)

        expect {
          Sidekiq::Testing.inline! do
            described_class.perform_async(user.id)
          end
        }.to raise_error(StandardError)

        expect(Rails.logger).to have_received(:error)
          .with("Failed to save weekly feedback for user #{user.id}: OpenAI API timeout")
      end

      it 'does not create WeeklyFeedback record on failure' do
        expect {
          Sidekiq::Testing.inline! do
            begin
              described_class.perform_async(user.id)
            rescue StandardError
              # Swallow error for count check
            end
          end
        }.not_to change { WeeklyFeedback.count }
      end
    end

    context 'when database save fails' do
      before do
        # Create workout
        workout = user.workouts.create!(
          name: 'Test Workout',
          workout_date: 3.days.ago,
          completed: true
        )

        # Mock successful AI generation
        calculator = instance_double(WeeklyProgressCalculator)
        allow(WeeklyProgressCalculator).to receive(:new).and_return(calculator)
        allow(calculator).to receive(:calculate).and_return(weekly_stats)

        ai_service = instance_double(AiServices::WeeklyWorkoutFeedbackService)
        allow(AiServices::WeeklyWorkoutFeedbackService).to receive(:new).and_return(ai_service)
        allow(ai_service).to receive(:generate).and_return(ai_feedback_text)

        # Mock database error
        allow(WeeklyFeedback).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new)
      end

      it 'raises error for Sidekiq retry' do
        expect {
          Sidekiq::Testing.inline! do
            described_class.perform_async(user.id)
          end
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'logs error message' do
        allow(Rails.logger).to receive(:error)

        expect {
          Sidekiq::Testing.inline! do
            described_class.perform_async(user.id)
          end
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(Rails.logger).to have_received(:error)
          .with(/Failed to save weekly feedback for user #{user.id}/)
      end
    end
  end

  describe 'job configuration' do
    it 'is queued in the :ai queue' do
      Sidekiq::Testing.fake! do
        described_class.perform_async(user.id)
        expect(described_class.jobs.first['queue']).to eq('ai')
      end
    end

    it 'stores user_id as argument' do
      Sidekiq::Testing.fake! do
        described_class.perform_async(user.id)
        expect(described_class.jobs.first['args']).to eq([ user.id ])
      end
    end

    it 'is configured to retry 3 times' do
      expect(described_class.sidekiq_options_hash['retry']).to eq(3)
    end

    it 'uses the ai queue for isolation' do
      expect(described_class.sidekiq_options_hash['queue']).to eq(:ai)
    end
  end

  describe 'integration with WeeklyProgressReportJob' do
    it 'can be called from WeeklyProgressReportJob' do
      Sidekiq::Testing.fake! do
        # Simulate the coordinator job queuing this job
        described_class.perform_async(user.id)

        expect(described_class.jobs.size).to eq(1)
        expect(described_class.jobs.first['args']).to eq([ user.id ])
      end
    end
  end

  describe 'preventing duplicate feedback for same week (idempotency)' do
    before do
      # Create existing feedback for this week
      WeeklyFeedback.create!(
        user: user,
        feedback_text: "Old feedback",
        week_start: Date.current.beginning_of_week,
        generated_at: 1.day.ago,
        stats_snapshot: weekly_stats,
        email_sent: false
      )
    end

    it 'does not create additional WeeklyFeedback records when one exists' do
      allow(Rails.logger).to receive(:info)

      expect {
        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end
      }.not_to change { WeeklyFeedback.count }

      expect(Rails.logger).to have_received(:info)
        .with("Generating AI feedback for user #{user.id}")
      expect(Rails.logger).to have_received(:info)
        .with("Feedback already exists for user #{user.id} week #{Date.current.beginning_of_week}")
    end

    it 'preserves existing feedback text when record already exists' do
      Sidekiq::Testing.inline! do
        described_class.perform_async(user.id)
      end

      feedback = WeeklyFeedback.find_by(user: user, week_start: Date.current.beginning_of_week)
      expect(feedback.feedback_text).to eq("Old feedback")
    end

    it 'handles race condition gracefully with RecordNotUnique' do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)

      # Remove the existing feedback to allow the job to proceed past the early check
      WeeklyFeedback.where(user: user, week_start: Date.current.beginning_of_week).destroy_all

      # Simulate race condition: find_by returns nil (no record), but create! fails
      allow(WeeklyFeedback).to receive(:find_by).and_return(nil)
      allow(WeeklyFeedback).to receive(:find_or_create_by!)
        .and_raise(ActiveRecord::RecordNotUnique.new("duplicate key"))

      expect {
        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end
      }.not_to raise_error

      expect(Rails.logger).to have_received(:info)
        .with(/Feedback already exists for user #{user.id} week.*race condition/)
    end
  end
end
