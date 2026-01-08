require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe WeeklyProgressReportJob, type: :job do
  # Clear Sidekiq job queue before each test
  before do
    Sidekiq::Worker.clear_all
  end

  # Include ActiveJob test helpers
  include ActiveJob::TestHelper
  
  describe '#perform' do
    context 'with multiple users' do
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

      let!(:user3) do
        User.create!(
          email: 'user3@example.com',
          password: 'Password123!',
          first_name: 'User',
          last_name: 'Three'
        )
      end

      it 'queues individual email jobs for each user' do
        Sidekiq::Testing.fake! do
          described_class.new.perform

          # Should queue one SendWeeklyProgressEmailJob per user
          expect(SendWeeklyProgressEmailJob.jobs.size).to eq(3)
        end
      end

      it 'passes correct user_id to each job' do
        Sidekiq::Testing.fake! do
          described_class.new.perform

          user_ids = SendWeeklyProgressEmailJob.jobs.map { |job| job['args'].first }
          expect(user_ids).to match_array([user1.id, user2.id, user3.id])
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

      it 'logs finish message' do
        allow(Rails.logger).to receive(:info)

        Sidekiq::Testing.fake! do
          described_class.new.perform
        end

        expect(Rails.logger).to have_received(:info)
          .with("Queued 3 weekly progress email jobs for 3 users")
      end
    end

    context 'with no users' do
      it 'handles empty user list gracefully' do
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
        end
      end
    end

    context 'with large number of users' do
      before do
        # Create 100 users
        100.times do |i|
          User.create!(
            email: "user#{i}@example.com",
            password: 'Password123!',
            first_name: 'User',
            last_name: i.to_s
          )
        end
      end

      it 'processes all users without memory issues' do
        Sidekiq::Testing.fake! do
          expect {
            described_class.new.perform
          }.not_to raise_error

          expect(SendWeeklyProgressEmailJob.jobs.size).to eq(100)
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
        # Use a generic error instead
        allow(SendWeeklyProgressEmailJob).to receive(:perform_async).and_raise(StandardError.new("Connection failed"))
      end
    
      it 'raises error for retry' do
        expect {
          described_class.new.perform
        }.to raise_error(StandardError, "Connection failed")  # Match the error message
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
