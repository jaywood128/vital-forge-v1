require 'rails_helper'

RSpec.describe WorkoutMailer, type: :mailer do
  describe '#weekly_progress' do
    let(:user) do
      User.create!(
        email: 'test@example.com',
        password: 'Password123!',
        first_name: 'John',
        last_name: 'Doe'
      )
    end

    let(:stats) do
      {
        total_workouts: 5,
        total_sets: 20,
        total_volume: 5000,
        total_duration: 225,
        streak: 3,
        most_common_exercise: 'Bench Press'
      }
    end

    let(:mail) { described_class.weekly_progress(user, stats) }

    it 'renders the headers' do
      expect(mail.subject).to match(/Your Weekly Fitness Progress/)
      expect(mail.to).to eq([ user.email ])
      expect(mail.from).to eq([ 'noreply@vitalforge.com' ])
    end

    it 'includes the subject with VitalForge branding' do
      puts "mail.subject: #{mail.subject}"
      expect(mail.subject).to include('VitalForge')
    end

    describe 'HTML body' do
      it 'includes user first name' do
        expect(mail.html_part.body.encoded).to include(user.first_name)
      end

      it 'includes total workouts stat' do
        expect(mail.html_part.body.encoded).to include('5')
      end

      it 'includes total sets stat' do
        expect(mail.html_part.body.encoded).to include('20')
      end

      it 'includes total volume stat' do
        expect(mail.html_part.body.encoded).to include('5,000') # With delimiter
      end

      it 'includes total duration stat' do
        expect(mail.html_part.body.encoded).to include('225')
      end

      it 'includes streak information when streak exists' do
        expect(mail.html_part.body.encoded).to include('3')
      end

      it 'includes most common exercise' do
        expect(mail.html_part.body.encoded).to include('Bench Press')
      end

      it 'has proper HTML structure' do
        expect(mail.html_part.body.encoded).to include('<html>')
        expect(mail.html_part.body.encoded).to include('</html>')
      end

      it 'includes VitalForge branding' do
        expect(mail.html_part.body.encoded).to include('VitalForge')
      end
    end

    describe 'text body' do
      it 'includes user first name' do
        expect(mail.text_part.body.encoded).to include(user.first_name)
      end

      it 'includes all stats' do
        body = mail.text_part.body.encoded
        expect(body).to include('5') # workouts
        expect(body).to include('20') # sets
        expect(body).to include('5,000') # volume
        expect(body).to include('225') # duration
      end

      it 'includes streak when present' do
        expect(mail.text_part.body.encoded).to include('3')
      end

      it 'includes most common exercise' do
        expect(mail.text_part.body.encoded).to include('Bench Press')
      end

      it 'is properly formatted as plain text' do
        expect(mail.text_part.body.encoded).not_to include('<html>')
        expect(mail.text_part.body.encoded).not_to include('<div>')
      end
    end

    context 'with low stats' do
      let(:stats) do
        {
          total_workouts: 1,
          total_sets: 3,
          total_volume: 300,
          total_duration: 20,
          streak: 1,
          most_common_exercise: 'Squats'
        }
      end

      it 'still sends email with low numbers' do
        expect(mail.html_part.body.encoded).to include('1')
        expect(mail.html_part.body.encoded).to include('300')
      end
    end

    context 'with high stats' do
      let(:stats) do
        {
          total_workouts: 15,
          total_sets: 100,
          total_volume: 25000,
          total_duration: 540,
          streak: 7,
          most_common_exercise: 'Deadlift'
        }
      end

      it 'formats large numbers with delimiters' do
        expect(mail.html_part.body.encoded).to include('25,000') # Volume with delimiter
      end
    end

    describe 'multipart email' do
      it 'is a multipart message' do
        expect(mail).to be_multipart
      end

      it 'has both HTML and text parts' do
        expect(mail.html_part).to be_present
        expect(mail.text_part).to be_present
      end

      it 'has correct content types' do
        expect(mail.html_part.content_type).to include('text/html')
        expect(mail.text_part.content_type).to include('text/plain')
      end
    end
  end
end
