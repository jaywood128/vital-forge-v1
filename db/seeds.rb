# VitalForge Seeds - Exercise Catalog and Test Data
# This file is idempotent and can be run multiple times safely

puts "🌱 Seeding VitalForge database..."

# Clear existing data (development/test only!)
if Rails.env.development? || Rails.env.test?
  puts "  🧹 Clearing existing data..."
  ExerciseSet.destroy_all
  WorkoutExercise.destroy_all
  Workout.destroy_all
  WorkoutTemplateExercise.destroy_all
  WorkoutTemplate.destroy_all
  UserPreference.destroy_all
  Exercise.destroy_all
  User.destroy_all
  puts "  ✅ Cleared existing data"
end

puts "  📚 Creating exercise catalog..."

# ==============================================================================
# COMPOUND EXERCISES - Core strength builders
# ==============================================================================

Exercise.find_or_create_by!(name: "Barbell Squat") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Barbell"
  e.muscle_group = "Legs"
  e.difficulty_level = "Intermediate"
  e.description = "The king of leg exercises targeting quads, glutes, and hamstrings"
  e.instructions = "Stand with feet shoulder-width apart, bar resting on upper traps. Keep chest up and core braced throughout the movement. Descend by pushing hips back and bending knees until thighs are parallel to ground. Drive through heels to return to starting position. Keep knees tracking over toes and avoid letting them cave inward to prevent injury."
end

Exercise.find_or_create_by!(name: "Barbell Deadlift") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Barbell"
  e.muscle_group = "Back"
  e.difficulty_level = "Advanced"
  e.description = "Full-body compound movement targeting entire posterior chain"
  e.instructions = "Position feet hip-width apart with bar over mid-foot. Grip bar just outside legs, keeping back flat and chest up. Engage lats and drive through heels, extending hips and knees simultaneously. Keep bar close to body throughout the lift. Lower with control by pushing hips back first, then bending knees. Never round your lower back as this can cause serious injury."
end

Exercise.find_or_create_by!(name: "Barbell Bench Press") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Bench"
  e.muscle_group = "Chest"
  e.difficulty_level = "Intermediate"
  e.description = "Classic upper body press for chest, shoulders, and triceps"
  e.instructions = "Lie on bench with eyes under the bar, feet flat on floor. Grip bar slightly wider than shoulders, unrack and position over chest. Lower bar to mid-chest with elbows at 45-degree angle. Press bar up in slight arc back to starting position. Keep shoulder blades retracted and avoid bouncing the bar off your chest to prevent shoulder and sternum injuries."
end

Exercise.find_or_create_by!(name: "Barbell Overhead Press") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Barbell"
  e.muscle_group = "Shoulders"
  e.difficulty_level = "Intermediate"
  e.description = "Standing press for building shoulder, upper chest, and triceps strength"
  e.instructions = "Stand with feet shoulder-width apart, bar resting on front delts. Grip bar just outside shoulders with elbows slightly forward. Press bar straight up, moving head back slightly to clear the bar path. Lock out overhead with bar over mid-foot. Lower with control back to shoulders. Engage core throughout and avoid excessive back arch which can strain the lower back."
end

Exercise.find_or_create_by!(name: "Barbell Row") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Barbell"
  e.muscle_group = "Back"
  e.difficulty_level = "Intermediate"
  e.description = "Horizontal pull targeting lats, rhomboids, and mid-back muscles"
  e.instructions = "Hinge at hips with slight knee bend, back flat and chest up. Grip bar with hands shoulder-width apart, arms extended. Pull bar to lower chest by driving elbows back and squeezing shoulder blades together. Lower with control to full extension. Keep core tight and avoid using momentum or excessive body swing which can strain the lower back."
end

# ==============================================================================
# CHEST ISOLATION EXERCISES
# ==============================================================================

Exercise.find_or_create_by!(name: "Incline Dumbbell Press") do |e|
  e.exercise_type = "Hypertrophy"
  e.equipment = "Dumbbells"
  e.muscle_group = "Chest"
  e.difficulty_level = "Intermediate"
  e.description = "Targets upper chest, front deltoids, and triceps"
  e.instructions = "Set bench to 30-45 degree incline, sit with dumbbells at shoulders. Press dumbbells up and slightly together at top, keeping wrists neutral. Lower with control until dumbbells are level with chest. Maintain contact with bench and avoid arching lower back excessively. Keep shoulder blades retracted throughout to protect shoulder joints."
end

Exercise.find_or_create_by!(name: "Dumbbell Flyes") do |e|
  e.exercise_type = "Hypertrophy"
  e.equipment = "Dumbbells"
  e.muscle_group = "Chest"
  e.difficulty_level = "Intermediate"
  e.description = "Isolation movement for chest stretch and development"
  e.instructions = "Lie on flat bench with dumbbells pressed above chest, palms facing each other. With slight elbow bend, lower dumbbells out to sides in wide arc. Feel stretch in chest but don't go beyond shoulder level. Squeeze chest to bring dumbbells back together at top. Use controlled tempo and avoid heavy weights to prevent shoulder strain."
end

# ==============================================================================
# BACK ISOLATION EXERCISES
# ==============================================================================

Exercise.find_or_create_by!(name: "Pull-ups") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Bodyweight"
  e.muscle_group = "Back"
  e.difficulty_level = "Intermediate"
  e.description = "Bodyweight vertical pull for lats and upper back"
  e.instructions = "Hang from bar with overhand grip slightly wider than shoulders, arms fully extended. Pull yourself up by driving elbows down and back until chin clears bar. Lower with control to full extension. Keep core engaged and avoid excessive swinging or kipping. If unable to perform full pull-ups, use resistance bands or assisted pull-up machine."
end

Exercise.find_or_create_by!(name: "Bent-Over Dumbbell Row") do |e|
  e.exercise_type = "Hypertrophy"
  e.equipment = "Dumbbells"
  e.muscle_group = "Back"
  e.difficulty_level = "Intermediate"
  e.description = "Unilateral back exercise for lats and rhomboids"
  e.instructions = "Place one knee and hand on bench for support, other foot on ground. Hold dumbbell in free hand with arm extended. Pull dumbbell to hip by driving elbow back and up, keeping it close to body. Squeeze shoulder blade at top, then lower with control. Keep back flat and avoid rotating torso to prevent lower back strain."
end

Exercise.find_or_create_by!(name: "Cable Row") do |e|
  e.exercise_type = "Hypertrophy"
  e.equipment = "Cable"
  e.muscle_group = "Back"
  e.difficulty_level = "Beginner"
  e.description = "Seated row for mid-back thickness and strength"
  e.instructions = "Sit at cable machine with feet braced, knees slightly bent. Grip handles with arms extended, maintaining slight lean back. Pull handles to torso by driving elbows back, squeezing shoulder blades together. Keep chest up and avoid excessive rocking. Return to start with control, feeling stretch in lats. Maintain neutral spine throughout to avoid lower back issues."
end

# ==============================================================================
# BICEPS ISOLATION EXERCISES
# ==============================================================================

Exercise.find_or_create_by!(name: "Barbell Curl") do |e|
  e.exercise_type = "Hypertrophy"
  e.equipment = "Barbell"
  e.muscle_group = "Arms"
  e.difficulty_level = "Beginner"
  e.description = "Classic biceps builder emphasizing controlled eccentric phase"
  e.instructions = "Stand with feet shoulder-width apart, holding barbell with underhand grip. Keep elbows close to sides and curl bar up to shoulders, squeezing biceps at top. Lower bar slowly over 3-4 seconds (eccentric phase) to maximize muscle tension. Avoid swinging or using momentum by keeping core tight and body still. Don't hyperextend elbows at bottom to protect joint."
end

Exercise.find_or_create_by!(name: "Cable Curl") do |e|
  e.exercise_type = "Hypertrophy"
  e.equipment = "Cable"
  e.muscle_group = "Arms"
  e.difficulty_level = "Beginner"
  e.description = "Constant tension biceps exercise using cable machine"
  e.instructions = "Stand facing cable machine with low pulley attachment. Grip handle with underhand grip, arm extended. Curl handle up to shoulder while keeping elbow stationary at side. Squeeze biceps at top, then lower with control. Cable provides constant tension throughout range of motion. Keep wrists neutral and avoid excessive shoulder movement."
end

# ==============================================================================
# TRICEPS ISOLATION EXERCISES
# ==============================================================================

Exercise.find_or_create_by!(name: "Overhead Triceps Extension") do |e|
  e.exercise_type = "Hypertrophy"
  e.equipment = "Dumbbells"
  e.muscle_group = "Arms"
  e.difficulty_level = "Intermediate"
  e.description = "Targets long head of triceps with overhead position"
  e.instructions = "Hold dumbbell overhead with both hands, arms extended. Keep elbows pointed forward and close together. Lower dumbbell behind head by bending elbows until forearms touch biceps. Extend arms back to starting position, squeezing triceps. Keep core engaged and avoid arching lower back. Start with lighter weight to avoid elbow strain."
end

Exercise.find_or_create_by!(name: "Cable Pushdown") do |e|
  e.exercise_type = "Hypertrophy"
  e.equipment = "Cable"
  e.muscle_group = "Arms"
  e.difficulty_level = "Beginner"
  e.description = "Cable exercise targeting all three heads of triceps"
  e.instructions = "Stand facing cable machine with high pulley attachment. Grip bar with overhand grip, elbows at sides. Push bar down by extending elbows until arms are straight, squeezing triceps. Return to start with control, keeping upper arms stationary. Avoid leaning forward or using body weight. Keep elbows tucked to sides throughout movement."
end

# ==============================================================================
# SHOULDER ISOLATION EXERCISES
# ==============================================================================

Exercise.find_or_create_by!(name: "Dumbbell Lateral Raise") do |e|
  e.exercise_type = "Hypertrophy"
  e.equipment = "Dumbbells"
  e.muscle_group = "Shoulders"
  e.difficulty_level = "Beginner"
  e.description = "Isolation exercise for side deltoid development"
  e.instructions = "Stand with dumbbells at sides, slight bend in elbows. Raise dumbbells out to sides until arms are parallel to floor, leading with elbows. Pause at top, then lower with control. Keep torso still and avoid swinging or using momentum. Use lighter weight to maintain proper form and prevent shoulder impingement. Focus on feeling tension in side delts."
end

# ==============================================================================
# QUAD-FOCUSED LEG EXERCISES
# ==============================================================================

Exercise.find_or_create_by!(name: "Leg Press") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Machine"
  e.muscle_group = "Legs"
  e.difficulty_level = "Beginner"
  e.description = "Machine-based quad and glute developer"
  e.instructions = "Sit in leg press machine with feet shoulder-width apart on platform. Release safety and lower platform by bending knees until they reach 90 degrees. Press through heels to extend legs back to start. Keep lower back pressed against pad throughout movement. Avoid locking knees at top and don't let knees cave inward to protect joint health."
end

Exercise.find_or_create_by!(name: "Front Squat") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Barbell"
  e.muscle_group = "Legs"
  e.difficulty_level = "Advanced"
  e.description = "Quad-dominant squat variation with barbell on front deltoids"
  e.instructions = "Rest barbell on front deltoids with elbows high and chest up. Feet shoulder-width apart, toes slightly out. Descend by sitting back and down, keeping torso upright and knees tracking over toes. Maintain high elbows throughout to prevent bar from rolling. Drive through full foot to stand back up. More quad-focused than back squat and requires good mobility."
end

# ==============================================================================
# KETTLEBELL EXERCISES
# ==============================================================================

Exercise.find_or_create_by!(name: "Kettlebell Swing") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Kettlebells"
  e.muscle_group = "FullBody"
  e.difficulty_level = "Intermediate"
  e.description = "Dynamic movement engaging core, glutes, hamstrings, and shoulders"
  e.instructions = "Stand with feet shoulder-width apart, kettlebell on floor in front. Hinge at hips to grip bell with both hands, then hike it back between legs. Explosively drive hips forward to swing bell to chest height, arms straight. Let bell swing back down and immediately repeat. Power comes from hip thrust, not arms. Keep core braced and spine neutral throughout to protect lower back."
end

Exercise.find_or_create_by!(name: "Kettlebell Clean and Press") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Kettlebells"
  e.muscle_group = "FullBody"
  e.difficulty_level = "Advanced"
  e.description = "Compound exercise strengthening shoulders, triceps, core, and legs"
  e.instructions = "Start with kettlebell between feet, hinge down and grip handle. In one motion, pull bell up while rotating wrist so bell rests on forearm in rack position. Press bell overhead by extending arm fully. Lower bell back to rack, then guide it down between legs. Requires coordination and practice to master the clean portion. Keep wrist straight when bell is racked to avoid strain."
end

Exercise.find_or_create_by!(name: "Kettlebell Snatch") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Kettlebells"
  e.muscle_group = "FullBody"
  e.difficulty_level = "Advanced"
  e.description = "Explosive movement targeting upper body, core, and power development"
  e.instructions = "Similar to swing but more explosive, pulling kettlebell from between legs to overhead in one fluid motion. As bell reaches chest height, punch hand through handle so bell flips over wrist. Lock out arm overhead with bell resting on forearm. Requires significant practice and technique work. Master swings and cleans first before attempting snatches to avoid injury."
end

Exercise.find_or_create_by!(name: "Kettlebell Deadlift") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Kettlebells"
  e.muscle_group = "Legs"
  e.difficulty_level = "Beginner"
  e.description = "Lower body exercise engaging glutes, hamstrings, and quadriceps"
  e.instructions = "Stand with feet hip-width apart, kettlebell on floor between feet. Hinge at hips, bend knees and grip bell handle with both hands. Keep back flat, chest up, and drive through heels to stand while squeezing glutes. Lower by pushing hips back first, then bending knees. Excellent for learning hip hinge pattern before progressing to barbell deadlifts."
end

Exercise.find_or_create_by!(name: "Kettlebell Goblet Squat") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Kettlebells"
  e.muscle_group = "Legs"
  e.difficulty_level = "Beginner"
  e.description = "Squat variation holding kettlebell at chest for quad and glute development"
  e.instructions = "Hold kettlebell by horns at chest level with elbows pointing down. Stand with feet slightly wider than shoulders, toes out. Sit back and down between legs, keeping chest up and kettlebell close to body. Descend until elbows touch inside of knees. Drive through heels to stand, squeezing glutes at top. Kettlebell acts as counterbalance making it easier to maintain upright torso."
end

# ==============================================================================
# ADDITIONAL POPULAR EXERCISES
# ==============================================================================

Exercise.find_or_create_by!(name: "Push-ups") do |e|
  e.exercise_type = "Strength"
  e.equipment = "Bodyweight"
  e.muscle_group = "Chest"
  e.difficulty_level = "Beginner"
  e.description = "Bodyweight pressing movement for chest, shoulders, and triceps"
  e.instructions = "Start in plank position with hands slightly wider than shoulders. Lower body by bending elbows until chest nearly touches floor. Push back up to starting position, fully extending arms. Keep core tight and body in straight line throughout. Avoid sagging hips or piking up. Modify on knees if needed to maintain proper form."
end

Exercise.find_or_create_by!(name: "Plank") do |e|
  e.exercise_type = "Stability"
  e.equipment = "Bodyweight"
  e.muscle_group = "Core"
  e.difficulty_level = "Beginner"
  e.description = "Isometric core exercise building stability and endurance"
  e.instructions = "Support body on forearms and toes in straight line from head to heels. Keep core engaged, glutes tight, and don't let hips sag or pike up. Breathe normally and hold position for time. Focus on quality over duration - maintain perfect form. Build up gradually from 20-30 seconds to avoid lower back strain."
end

puts "  ✅ Created #{Exercise.count} exercises"

# ==============================================================================
# WORKOUT TEMPLATES - Curated Programs
# ==============================================================================

puts "  📋 Creating workout templates..."

# Template 1: Push Pull Legs (PPL) - Physique Focus
ppl = WorkoutTemplate.find_or_create_by!(name: "Push Pull Legs") do |t|
  t.description = "The classic 3-day split targeting all muscle groups with optimal recovery time. Perfect for building muscle mass and aesthetics."
  t.goal_type = "physique"
  t.difficulty_level = "Intermediate"
  t.days_per_week = 6
  t.estimated_duration_minutes = 45
  t.total_exercises = 6
  t.source = "Bodybuilding.com"
end

# PPL - Push Day Exercises
[
  { exercise: "Barbell Bench Press", order: 1, sets: 4, reps: "8-12", rest: 90, notes: "Focus on chest contraction at the top" },
  { exercise: "Incline Dumbbell Press", order: 2, sets: 3, reps: "10-12", rest: 60, notes: "Target upper chest" },
  { exercise: "Dumbbell Flyes", order: 3, sets: 3, reps: "12-15", rest: 60, notes: "Stretch at bottom, squeeze at top" },
  { exercise: "Barbell Overhead Press", order: 4, sets: 3, reps: "8-10", rest: 90, notes: "Keep core tight" },
  { exercise: "Dumbbell Lateral Raise", order: 5, sets: 3, reps: "12-15", rest: 45, notes: "Lead with elbows" },
  { exercise: "Cable Pushdown", order: 6, sets: 3, reps: "12-15", rest: 45, notes: "Full extension at bottom" }
].each do |ex_data|
  exercise = Exercise.find_by(name: ex_data[:exercise])
  next unless exercise

  WorkoutTemplateExercise.find_or_create_by!(
    workout_template: ppl,
    exercise: exercise,
    order_position: ex_data[:order]
  ) do |wte|
    wte.recommended_sets = ex_data[:sets]
    wte.recommended_reps = ex_data[:reps]
    wte.rest_seconds = ex_data[:rest]
    wte.notes = ex_data[:notes]
  end
end

# Template 2: Upper/Lower Split - Strength Focus
upper_lower = WorkoutTemplate.find_or_create_by!(name: "Upper/Lower Split") do |t|
  t.description = "Perfect for building strength with compound movements and balanced volume. Ideal for intermediate lifters focused on progressive overload."
  t.goal_type = "strength"
  t.difficulty_level = "Intermediate"
  t.days_per_week = 4
  t.estimated_duration_minutes = 60
  t.total_exercises = 8
  t.source = "T-Nation"
end

# Upper/Lower - Upper Day Exercises
[
  { exercise: "Barbell Bench Press", order: 1, sets: 4, reps: "5", rest: 180, notes: "Heavy compound movement" },
  { exercise: "Barbell Row", order: 2, sets: 4, reps: "5", rest: 180, notes: "Match bench press volume" },
  { exercise: "Barbell Overhead Press", order: 3, sets: 3, reps: "6-8", rest: 120, notes: "Strict form" },
  { exercise: "Pull-ups", order: 4, sets: 3, reps: "8-10", rest: 90, notes: "Add weight if needed" },
  { exercise: "Incline Dumbbell Press", order: 5, sets: 3, reps: "8-10", rest: 90, notes: "Upper chest focus" },
  { exercise: "Cable Row", order: 6, sets: 3, reps: "10-12", rest: 60, notes: "Squeeze at contraction" },
  { exercise: "Barbell Curl", order: 7, sets: 3, reps: "8-10", rest: 60, notes: "Controlled eccentric" },
  { exercise: "Overhead Triceps Extension", order: 8, sets: 3, reps: "10-12", rest: 60, notes: "Full range of motion" }
].each do |ex_data|
  exercise = Exercise.find_by(name: ex_data[:exercise])
  next unless exercise

  WorkoutTemplateExercise.find_or_create_by!(
    workout_template: upper_lower,
    exercise: exercise,
    order_position: ex_data[:order]
  ) do |wte|
    wte.recommended_sets = ex_data[:sets]
    wte.recommended_reps = ex_data[:reps]
    wte.rest_seconds = ex_data[:rest]
    wte.notes = ex_data[:notes]
  end
end

# Template 3: Arnold Split - Advanced Physique
arnold = WorkoutTemplate.find_or_create_by!(name: "Arnold Split") do |t|
  t.description = "High-volume bodybuilding routine inspired by the Austrian Oak himself. For advanced lifters seeking maximum muscle growth."
  t.goal_type = "physique"
  t.difficulty_level = "Advanced"
  t.days_per_week = 6
  t.estimated_duration_minutes = 75
  t.total_exercises = 10
  t.source = "Arnold Schwarzenegger - Encyclopedia of Modern Bodybuilding"
end

# Arnold Split - Chest/Back Day
[
  { exercise: "Barbell Bench Press", order: 1, sets: 5, reps: "8-12", rest: 90, notes: "Pyramid up in weight" },
  { exercise: "Barbell Row", order: 2, sets: 5, reps: "8-12", rest: 90, notes: "Superset with bench" },
  { exercise: "Incline Dumbbell Press", order: 3, sets: 4, reps: "10-12", rest: 60, notes: "Focus on upper chest" },
  { exercise: "Pull-ups", order: 4, sets: 4, reps: "10-15", rest: 60, notes: "Wide grip" },
  { exercise: "Dumbbell Flyes", order: 5, sets: 4, reps: "12-15", rest: 60, notes: "Deep stretch" },
  { exercise: "Bent-Over Dumbbell Row", order: 6, sets: 4, reps: "10-12", rest: 60, notes: "Each arm" },
  { exercise: "Cable Row", order: 7, sets: 3, reps: "12-15", rest: 45, notes: "Squeeze hard" },
  { exercise: "Push-ups", order: 8, sets: 3, reps: "AMRAP", rest: 45, notes: "Burnout set" },
  { exercise: "Cable Curl", order: 9, sets: 3, reps: "12-15", rest: 45, notes: "Peak contraction" },
  { exercise: "Cable Pushdown", order: 10, sets: 3, reps: "12-15", rest: 45, notes: "Full extension" }
].each do |ex_data|
  exercise = Exercise.find_by(name: ex_data[:exercise])
  next unless exercise

  WorkoutTemplateExercise.find_or_create_by!(
    workout_template: arnold,
    exercise: exercise,
    order_position: ex_data[:order]
  ) do |wte|
    wte.recommended_sets = ex_data[:sets]
    wte.recommended_reps = ex_data[:reps]
    wte.rest_seconds = ex_data[:rest]
    wte.notes = ex_data[:notes]
  end
end

# Template 4: Full Body Workout - Beginner Strength
full_body = WorkoutTemplate.find_or_create_by!(name: "Full Body Workout") do |t|
  t.description = "Comprehensive routine hitting all major muscle groups in one session. Perfect for beginners building a foundation."
  t.goal_type = "strength"
  t.difficulty_level = "Beginner"
  t.days_per_week = 3
  t.estimated_duration_minutes = 50
  t.total_exercises = 7
  t.source = "Starting Strength"
end

# Full Body Exercises
[
  { exercise: "Barbell Squat", order: 1, sets: 3, reps: "5", rest: 180, notes: "Core lift - focus on form" },
  { exercise: "Barbell Bench Press", order: 2, sets: 3, reps: "5", rest: 180, notes: "Retract shoulder blades" },
  { exercise: "Barbell Deadlift", order: 3, sets: 1, reps: "5", rest: 240, notes: "One heavy set only" },
  { exercise: "Barbell Overhead Press", order: 4, sets: 3, reps: "5", rest: 120, notes: "Alternate with bench" },
  { exercise: "Barbell Row", order: 5, sets: 3, reps: "5", rest: 120, notes: "Pull to lower chest" },
  { exercise: "Pull-ups", order: 6, sets: 3, reps: "5-8", rest: 90, notes: "Use assistance if needed" },
  { exercise: "Plank", order: 7, sets: 3, reps: "60 sec", rest: 60, notes: "Core stability" }
].each do |ex_data|
  exercise = Exercise.find_by(name: ex_data[:exercise])
  next unless exercise

  WorkoutTemplateExercise.find_or_create_by!(
    workout_template: full_body,
    exercise: exercise,
    order_position: ex_data[:order]
  ) do |wte|
    wte.recommended_sets = ex_data[:sets]
    wte.recommended_reps = ex_data[:reps]
    wte.rest_seconds = ex_data[:rest]
    wte.notes = ex_data[:notes]
  end
end

# Template 5: 5/3/1 Program - Strength Focus
five_three_one = WorkoutTemplate.find_or_create_by!(name: "5/3/1 Program") do |t|
  t.description = "Jim Wendler's proven strength program for consistent progressive overload. Built around four main lifts with accessory work."
  t.goal_type = "strength"
  t.difficulty_level = "Intermediate"
  t.days_per_week = 4
  t.estimated_duration_minutes = 55
  t.total_exercises = 5
  t.source = "Jim Wendler - 5/3/1"
end

# 5/3/1 - Squat Day
[
  { exercise: "Barbell Squat", order: 1, sets: 3, reps: "5/3/1", rest: 180, notes: "Main lift - follow 5/3/1 progression" },
  { exercise: "Leg Press", order: 2, sets: 5, reps: "10-15", rest: 90, notes: "Boring But Big accessory" },
  { exercise: "Front Squat", order: 3, sets: 3, reps: "8-10", rest: 120, notes: "Quad emphasis" },
  { exercise: "Kettlebell Swing", order: 4, sets: 3, reps: "15-20", rest: 60, notes: "Hip power" },
  { exercise: "Plank", order: 5, sets: 3, reps: "60 sec", rest: 60, notes: "Core work" }
].each do |ex_data|
  exercise = Exercise.find_by(name: ex_data[:exercise])
  next unless exercise

  WorkoutTemplateExercise.find_or_create_by!(
    workout_template: five_three_one,
    exercise: exercise,
    order_position: ex_data[:order]
  ) do |wte|
    wte.recommended_sets = ex_data[:sets]
    wte.recommended_reps = ex_data[:reps]
    wte.rest_seconds = ex_data[:rest]
    wte.notes = ex_data[:notes]
  end
end

# Template 6: Bro Split - Physique Focus
bro_split = WorkoutTemplate.find_or_create_by!(name: "Bro Split") do |t|
  t.description = "Classic bodybuilding split focusing one muscle group per day. High volume for maximum hypertrophy."
  t.goal_type = "physique"
  t.difficulty_level = "Intermediate"
  t.days_per_week = 5
  t.estimated_duration_minutes = 60
  t.total_exercises = 8
  t.source = "Bodybuilding.com"
end

# Bro Split - Chest Day
[
  { exercise: "Barbell Bench Press", order: 1, sets: 4, reps: "8-10", rest: 90, notes: "Flat bench focus" },
  { exercise: "Incline Dumbbell Press", order: 2, sets: 4, reps: "10-12", rest: 75, notes: "Upper chest" },
  { exercise: "Dumbbell Flyes", order: 3, sets: 3, reps: "12-15", rest: 60, notes: "Stretch and squeeze" },
  { exercise: "Cable Row", order: 4, sets: 3, reps: "12-15", rest: 60, notes: "Decline angle" },
  { exercise: "Push-ups", order: 5, sets: 3, reps: "15-20", rest: 45, notes: "Burnout" },
  { exercise: "Cable Pushdown", order: 6, sets: 4, reps: "12-15", rest: 45, notes: "Triceps focus" },
  { exercise: "Overhead Triceps Extension", order: 7, sets: 3, reps: "12-15", rest: 45, notes: "Long head emphasis" },
  { exercise: "Plank", order: 8, sets: 3, reps: "45 sec", rest: 45, notes: "Core finisher" }
].each do |ex_data|
  exercise = Exercise.find_by(name: ex_data[:exercise])
  next unless exercise

  WorkoutTemplateExercise.find_or_create_by!(
    workout_template: bro_split,
    exercise: exercise,
    order_position: ex_data[:order]
  ) do |wte|
    wte.recommended_sets = ex_data[:sets]
    wte.recommended_reps = ex_data[:reps]
    wte.rest_seconds = ex_data[:rest]
    wte.notes = ex_data[:notes]
  end
end

puts "  ✅ Created #{WorkoutTemplate.count} workout templates"

# ==============================================================================
# DEVELOPMENT TEST DATA
# ==============================================================================

if Rails.env.development?
  puts "  👤 Creating test user..."

  user = User.find_or_create_by!(email: "test@vitalforge.com") do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
    u.first_name = "Test"
    u.last_name = "User"
  end

  puts "  ✅ Test user: #{user.email} (password: password123)"

  # Create sample workout
  puts "  🏋️ Creating sample workout..."

  workout = user.workouts.find_or_create_by!(
    name: "Monday Push Day",
    workout_date: Date.today
  ) do |w|
    w.workout_type = "Strength"
    w.completed = false
    w.notes = "Focus on progressive overload"
  end

  # Add bench press to workout
  bench_press = Exercise.find_by(name: "Barbell Bench Press")
  if bench_press
    workout_exercise = workout.workout_exercises.find_or_create_by!(
      exercise: bench_press,
      order_position: 1
    ) do |we|
      we.rest_between_sets = 120
      we.notes = "Warm up with bar first"
    end

    # Add sets if they don't exist
    if workout_exercise.exercise_sets.empty?
      workout_exercise.exercise_sets.create!([
        { set_number: 1, reps: 10, weight: 135, rpe: 6, weight_unit: "lbs" },
        { set_number: 2, reps: 8, weight: 155, rpe: 7, weight_unit: "lbs" },
        { set_number: 3, reps: 6, weight: 175, rpe: 8, weight_unit: "lbs" },
        { set_number: 4, reps: 6, weight: 185, rpe: 9, weight_unit: "lbs" }
      ])
    end
  end

  # Add overhead press to workout
  ohp = Exercise.find_by(name: "Barbell Overhead Press")
  if ohp
    workout_exercise2 = workout.workout_exercises.find_or_create_by!(
      exercise: ohp,
      order_position: 2
    ) do |we|
      we.rest_between_sets = 90
    end

    if workout_exercise2.exercise_sets.empty?
      workout_exercise2.exercise_sets.create!([
        { set_number: 1, reps: 10, weight: 95, rpe: 6, weight_unit: "lbs" },
        { set_number: 2, reps: 8, weight: 105, rpe: 7, weight_unit: "lbs" },
        { set_number: 3, reps: 6, weight: 115, rpe: 9, weight_unit: "lbs" }
      ])
    end
  end

  puts "  ✅ Sample workout created with #{workout.workout_exercises.count} exercises"
  puts "  📊 Total sets logged: #{workout.total_sets}"
end

puts ""
puts "🎉 Seeding complete!"
puts ""
puts "📊 Database Summary:"
puts "  - Exercises: #{Exercise.count}"
puts "  - Workout Templates: #{WorkoutTemplate.count}"
puts "  - Users: #{User.count}"
puts "  - Workouts: #{Workout.count}"
puts ""

if Rails.env.development?
  puts "🔍 Quick test commands:"
  puts "  rails console"
  puts "  > Exercise.by_equipment('Kettlebells').pluck(:name)"
  puts "  > Exercise.by_muscle('Chest').pluck(:name)"
  puts "  > User.first.workouts.first.total_volume"
  puts ""
end
