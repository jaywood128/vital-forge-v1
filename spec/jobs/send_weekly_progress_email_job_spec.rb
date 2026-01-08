require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe SendWeeklyProgressEmailJob, type: :job do
  # Clear Sidekiq job queue before each test
  before do
    Sidekiq::Worker.clear_all
  end

  let(:user) do
    User.create!(
      email: 'test@example.com',
      password: 'Password123!',
      first_name: 'Test',
      last_name: 'User'
    )
  end
  
  describe '#perform' do
    context 'when user exists and has workouts' do
      let(:exercise) do
        Exercise.create!(
          name: 'Bench Press',
          exercise_type: 'Strength',
          muscle_group: 'Chest',
          equipment: 'Barbell'
        )
      end

      before do
        # Create some workout data for the user
        workout = user.workouts.create!(
          name: 'Test Workout',
          workout_date: 2.days.ago,
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
      end

      it 'sends an email to the user' do
        Sidekiq::Testing.inline! do
          expect {
            described_class.perform_async(user.id)
          }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end

      it 'calculates weekly stats' do
        calculator = instance_double(WeeklyProgressCalculator)
        allow(WeeklyProgressCalculator).to receive(:new).with(user).and_return(calculator)
        allow(calculator).to receive(:calculate).and_return({
          total_workouts: 3,
          total_sets: 12,
          total_volume: 3600,
          total_duration: 90,
          streak: 3,
          most_common_exercise: 'Bench Press'
        })

        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        expect(calculator).to have_received(:calculate)
      end

      it 'logs success message' do
        allow(Rails.logger).to receive(:info)

        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        expect(Rails.logger).to have_received(:info)
          .with(/Sent weekly progress email to user #{user.id}/)
      end
    end

    context 'when user has no workouts this week' do
      it 'does not send an email' do
        Sidekiq::Testing.inline! do
          expect {
            described_class.perform_async(user.id)
          }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end

      it 'logs skip message' do
        allow(Rails.logger).to receive(:info)

        Sidekiq::Testing.inline! do
          described_class.perform_async(user.id)
        end

        expect(Rails.logger).to have_received(:info)
          .with(/Skipped weekly progress email for user #{user.id} - no workouts this week/)
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

      it 'does not send an email' do
        Sidekiq::Testing.inline! do
          expect {
            described_class.perform_async(999999)
          }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    context 'when email sending fails' do
      let(:exercise) do
        Exercise.create!(
          name: 'Test Exercise',
          exercise_type: 'Strength',
          muscle_group: 'Chest',
          equipment: 'Barbell'
        )
      end

      before do
        workout = user.workouts.create!(
          name: 'Test Workout',
          workout_date: 2.days.ago,
          completed: true
        )
        
        # Mock the entire mail delivery chain
        mail_message = double('Mail::Message')
        allow(WorkoutMailer).to receive(:weekly_progress).and_return(mail_message)
        allow(mail_message).to receive(:deliver_now).and_raise(Net::SMTPServerBusy.new('SMTP connection failed'))
      end

      it 'raises error for retry' do
        expect {
          Sidekiq::Testing.inline! do
            described_class.perform_async(user.id)
          end
        }.to raise_error(Net::SMTPServerBusy)
      end

      it 'logs error message' do
        allow(Rails.logger).to receive(:error)

        expect {
          Sidekiq::Testing.inline! do
            described_class.perform_async(user.id)
          end
        }.to raise_error(Net::SMTPServerBusy)

        expect(Rails.logger).to have_received(:error)
          .with(/Failed to send weekly progress email to user #{user.id}/)
      end
    end
  end

  describe 'job queueing' do
    it 'enqueues the job in the default queue' do
      Sidekiq::Testing.fake! do
        described_class.perform_async(user.id)
        expect(described_class.jobs.size).to eq(1)
        expect(described_class.jobs.first['queue']).to eq('default')
      end
    end

    it 'stores user_id as argument' do
      Sidekiq::Testing.fake! do
        described_class.perform_async(user.id)
        expect(described_class.jobs.first['args']).to eq([user.id])
      end
    end
  end

  describe 'retry behavior' do
    it 'is configured to retry on StandardError' do
      expect(described_class.sidekiq_options_hash['retry']).to be_truthy
    end
  end
end
