require 'rails_helper'

RSpec.describe WeeklyProgressCalculator do
  let(:user) do
    User.create!(
      email: 'test@example.com',
      password: 'Password123!',
      first_name: 'Test',
      last_name: 'User'
    )
  end

  let(:calculator) { described_class.new(user) }

  describe '#calculate' do
    context 'with no workouts' do
      it 'returns zero stats' do
        stats = calculator.calculate

        expect(stats[:total_workouts]).to eq(0)
        expect(stats[:total_sets]).to eq(0)
        expect(stats[:total_volume]).to eq(0)
        expect(stats[:total_duration]).to eq(0)
        expect(stats[:streak]).to eq(0)
        expect(stats[:most_common_exercise]).to be_nil
      end
    end

    context 'with workouts this week' do
      let(:bench_press) do
        Exercise.create!(
          name: 'Bench Press',
          exercise_type: 'Strength',
          muscle_group: 'Chest',
          equipment: 'Barbell'
        )
      end

      let(:squats) do
        Exercise.create!(
          name: 'Squats',
          exercise_type: 'Strength',
          muscle_group: 'Legs',
          equipment: 'Barbell'
        )
      end

      let!(:workout1) do
        user.workouts.create!(
          name: 'Morning Workout',
          workout_date: 2.days.ago,
          duration_minutes: 45,
          completed: true
        )
      end

      let!(:workout2) do
        user.workouts.create!(
          name: 'Evening Workout',
          workout_date: 1.day.ago,
          duration_minutes: 30,
          completed: true
        )
      end

      before do
        # Workout 1: Bench Press with 3 sets
        workout_exercise1 = workout1.workout_exercises.create!(
          exercise: bench_press,
          order_position: 1,
          completed: true
        )
        workout_exercise1.exercise_sets.create!(set_number: 1, weight: 100, reps: 10, completed: true)
        workout_exercise1.exercise_sets.create!(set_number: 2, weight: 100, reps: 8, completed: true)
        workout_exercise1.exercise_sets.create!(set_number: 3, weight: 100, reps: 6, completed: true)

        # Workout 2: Squats with 2 sets
        workout_exercise2 = workout2.workout_exercises.create!(
          exercise: squats,
          order_position: 1,
          completed: true
        )
        workout_exercise2.exercise_sets.create!(set_number: 1, weight: 200, reps: 5, completed: true)
        workout_exercise2.exercise_sets.create!(set_number: 2, weight: 200, reps: 5, completed: true)
      end

      it 'calculates total workouts correctly' do
        stats = calculator.calculate
        expect(stats[:total_workouts]).to eq(2)
      end

      it 'calculates total sets correctly' do
        stats = calculator.calculate
        expect(stats[:total_sets]).to eq(5)
      end

      it 'calculates total volume correctly' do
        stats = calculator.calculate
        # (100*10) + (100*8) + (100*6) + (200*5) + (200*5)
        # 1000 + 800 + 600 + 1000 + 1000 = 4400
        expect(stats[:total_volume]).to eq(4400)
      end

      it 'calculates total duration correctly' do
        stats = calculator.calculate
        expect(stats[:total_duration]).to eq(75) # 45 + 30
      end
    end

    context 'with old workouts outside time window' do
      let(:exercise) do
        Exercise.create!(
          name: 'Deadlift',
          exercise_type: 'Strength',
          muscle_group: 'Back',
          equipment: 'Barbell'
        )
      end

      let!(:old_workout) do
        user.workouts.create!(
          name: 'Old Workout',
          workout_date: 2.weeks.ago,
          duration_minutes: 60,
          completed: true
        )
      end

      before do
        workout_exercise = old_workout.workout_exercises.create!(
          exercise: exercise,
          order_position: 1,
          completed: true
        )
        workout_exercise.exercise_sets.create!(set_number: 1, weight: 50, reps: 10, completed: true)
      end

      it 'does not include old workouts' do
        stats = calculator.calculate
        expect(stats[:total_workouts]).to eq(0)
      end
    end

    context 'calculating workout streak' do
      it 'calculates consecutive days correctly' do
        # Create workouts for 3 consecutive days
        user.workouts.create!(name: 'Day 1', workout_date: Date.current, completed: true)
        user.workouts.create!(name: 'Day 2', workout_date: 1.day.ago, completed: true)
        user.workouts.create!(name: 'Day 3', workout_date: 2.days.ago, completed: true)

        stats = calculator.calculate
        expect(stats[:streak]).to eq(3)
      end

      it 'handles non-consecutive days' do
        user.workouts.create!(name: 'Today', workout_date: Date.current, completed: true)
        user.workouts.create!(name: 'Gap', workout_date: 3.days.ago, completed: true) # Gap!

        stats = calculator.calculate
        expect(stats[:streak]).to eq(1) # Only current day
      end

      it 'returns 0 streak when no workouts' do
        stats = calculator.calculate
        expect(stats[:streak]).to eq(0)
      end
    end

    context 'with null values in sets' do
      let(:exercise) do
        Exercise.create!(
          name: 'Test Exercise',
          exercise_type: 'Strength',
          muscle_group: 'Arms',
          equipment: 'Dumbbells'
        )
      end

      let!(:workout) do
        user.workouts.create!(
          name: 'Test Workout',
          workout_date: 1.day.ago,
          completed: true
        )
      end

      before do
        workout_exercise = workout.workout_exercises.create!(
          exercise: exercise,
          order_position: 1,
          completed: true
        )
        # Set with nil weight should be treated as 0
        workout_exercise.exercise_sets.create!(set_number: 1, weight: nil, reps: 10, completed: true)
        workout_exercise.exercise_sets.create!(set_number: 2, weight: 100, reps: 1, completed: true)
      end

      it 'handles nil values gracefully' do
        expect {
          stats = calculator.calculate
          expect(stats[:total_volume]).to eq(100) # (nil*10) + (100*1) = 100
        }.not_to raise_error
      end
    end

    context 'with different users' do
      let(:other_user) do
        User.create!(
          email: 'other@example.com',
          password: 'Password123!',
          first_name: 'Other',
          last_name: 'User'
        )
      end

      let(:exercise) do
        Exercise.create!(
          name: 'Shared Exercise',
          exercise_type: 'Strength',
          muscle_group: 'Chest',
          equipment: 'Barbell'
        )
      end

      before do
        # Create workout for original user
        workout = user.workouts.create!(
          name: 'User Workout',
          workout_date: 1.day.ago,
          completed: true
        )
        workout_exercise = workout.workout_exercises.create!(
          exercise: exercise,
          order_position: 1,
          completed: true
        )
        workout_exercise.exercise_sets.create!(set_number: 1, weight: 100, reps: 10, completed: true)

        # Create workout for other user
        other_workout = other_user.workouts.create!(
          name: 'Other User Workout',
          workout_date: 1.day.ago,
          completed: true
        )
        other_workout_exercise = other_workout.workout_exercises.create!(
          exercise: exercise,
          order_position: 1,
          completed: true
        )
        other_workout_exercise.exercise_sets.create!(set_number: 1, weight: 200, reps: 10, completed: true)
      end

      it 'only calculates stats for the specified user' do
        stats = calculator.calculate
        expect(stats[:total_workouts]).to eq(1)
        expect(stats[:total_volume]).to eq(1000) # Not 3000!
      end
    end
  end

  describe 'time window' do
    it 'uses 1 week ago as start date' do
      calculator = described_class.new(user)
      expect(calculator.instance_variable_get(:@start_date)).to be_within(1.second).of(1.week.ago.beginning_of_day)
    end

    it 'uses current time as end date' do
      calculator = described_class.new(user)
      expect(calculator.instance_variable_get(:@end_date)).to be_within(1.second).of(Time.current.end_of_day)
    end
  end
end
