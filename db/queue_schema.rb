# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_04_021202) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "exercise_sets", force: :cascade do |t|
    t.bigint "workout_exercise_id", null: false
    t.integer "set_number", null: false
    t.integer "reps", null: false
    t.decimal "weight", precision: 6, scale: 2
    t.string "weight_unit", default: "lbs"
    t.integer "rest_after_seconds"
    t.integer "rpe"
    t.boolean "to_failure", default: false
    t.text "notes"
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workout_exercise_id", "set_number"], name: "index_exercise_sets_on_workout_exercise_and_number"
    t.index ["workout_exercise_id", "set_number"], name: "unique_set_number_per_exercise", unique: true
    t.index ["workout_exercise_id"], name: "index_exercise_sets_on_workout_exercise_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "exercise_type", null: false
    t.string "equipment", null: false
    t.string "muscle_group"
    t.string "difficulty_level"
    t.text "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipment"], name: "index_exercises_on_equipment"
    t.index ["exercise_type"], name: "index_exercises_on_exercise_type"
    t.index ["muscle_group"], name: "index_exercises_on_muscle_group"
    t.index ["name"], name: "index_exercises_on_name", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "exercise_sets", force: :cascade do |t|
    t.bigint "workout_exercise_id", null: false
    t.integer "set_number", null: false
    t.integer "reps", null: false
    t.decimal "weight", precision: 6, scale: 2
    t.string "weight_unit", default: "lbs"
    t.integer "rest_after_seconds"
    t.integer "rpe"
    t.boolean "to_failure", default: false
    t.text "notes"
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "exercises", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "exercise_type", null: false
    t.string "equipment", null: false
    t.string "muscle_group"
    t.string "difficulty_level"
    t.text "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "primary_goal"
    t.integer "training_days_per_week"
    t.integer "preferred_workout_duration"
    t.string "experience_level"
    t.boolean "onboarding_completed", default: false, null: false
    t.datetime "onboarding_completed_at"
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "failed_login_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "last_login_at"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "weekly_feedbacks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "week_start", null: false
    t.text "feedback_text", null: false
    t.jsonb "stats_snapshot"
    t.datetime "generated_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "workout_exercises", force: :cascade do |t|
    t.bigint "workout_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "order_position", default: 0, null: false
    t.text "notes"
    t.integer "rest_between_sets"
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "workout_template_exercises", force: :cascade do |t|
    t.bigint "workout_template_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "order_position", default: 0, null: false
    t.integer "recommended_sets", null: false
    t.string "recommended_reps", null: false
    t.integer "rest_seconds"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "workout_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "goal_type", null: false
    t.string "difficulty_level"
    t.integer "days_per_week", null: false
    t.integer "estimated_duration_minutes"
    t.integer "total_exercises"
    t.string "source"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "workouts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "workout_date", null: false
    t.integer "duration_minutes"
    t.string "workout_type"
    t.integer "calories_burned"
    t.text "notes"
    t.integer "intensity_level"
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "user_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "primary_goal"
    t.integer "training_days_per_week"
    t.integer "preferred_workout_duration"
    t.string "experience_level"
    t.boolean "onboarding_completed", default: false, null: false
    t.datetime "onboarding_completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_preferences_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "failed_login_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "last_login_at"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.string "phone_number"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
  end

  create_table "weekly_feedbacks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "week_start", null: false
    t.text "feedback_text", null: false
    t.jsonb "stats_snapshot"
    t.datetime "generated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "email_sent", default: false, null: false
    t.index ["user_id", "week_start", "email_sent"], name: "index_weekly_feedbacks_on_user_week_email"
    t.index ["user_id", "week_start"], name: "index_weekly_feedbacks_on_user_id_and_week_start", unique: true
    t.index ["user_id"], name: "index_weekly_feedbacks_on_user_id"
    t.index ["week_start"], name: "index_weekly_feedbacks_on_week_start"
  end

  create_table "workout_exercises", force: :cascade do |t|
    t.bigint "workout_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "order_position", default: 0, null: false
    t.text "notes"
    t.integer "rest_between_sets"
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_workout_exercises_on_exercise_id"
    t.index ["workout_id", "order_position"], name: "index_workout_exercises_on_workout_and_order"
    t.index ["workout_id"], name: "index_workout_exercises_on_workout_id"
  end

  create_table "workout_template_exercises", force: :cascade do |t|
    t.bigint "workout_template_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "order_position", default: 0, null: false
    t.integer "recommended_sets", null: false
    t.string "recommended_reps", null: false
    t.integer "rest_seconds"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_workout_template_exercises_on_exercise_id"
    t.index ["workout_template_id", "order_position"], name: "index_template_exercises_on_template_and_order"
    t.index ["workout_template_id"], name: "index_workout_template_exercises_on_workout_template_id"
  end

  create_table "workout_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "goal_type", null: false
    t.string "difficulty_level"
    t.integer "days_per_week", null: false
    t.integer "estimated_duration_minutes"
    t.integer "total_exercises"
    t.string "source"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["days_per_week"], name: "index_workout_templates_on_days_per_week"
    t.index ["difficulty_level"], name: "index_workout_templates_on_difficulty_level"
    t.index ["goal_type"], name: "index_workout_templates_on_goal_type"
    t.index ["is_active"], name: "index_workout_templates_on_is_active"
  end

  create_table "workouts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "workout_date", null: false
    t.integer "duration_minutes"
    t.string "workout_type"
    t.integer "calories_burned"
    t.text "notes"
    t.integer "intensity_level"
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "workout_template_id"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.time "scheduled_time", comment: "Optional time of day when workout is scheduled"
    t.index ["completed"], name: "index_workouts_on_completed"
    t.index ["user_id", "started_at", "completed_at"], name: "index_workouts_on_user_active"
    t.index ["user_id", "workout_date"], name: "index_workouts_on_user_and_date"
    t.index ["user_id"], name: "index_workouts_on_user_id"
    t.index ["workout_template_id"], name: "index_workouts_on_workout_template_id"
    t.index ["workout_type"], name: "index_workouts_on_workout_type"
  end

  add_foreign_key "exercise_sets", "workout_exercises", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "user_preferences", "users", on_delete: :cascade
  add_foreign_key "weekly_feedbacks", "users"
  add_foreign_key "workout_exercises", "exercises"
  add_foreign_key "workout_exercises", "workouts", on_delete: :cascade
  add_foreign_key "workout_template_exercises", "exercises"
  add_foreign_key "workout_template_exercises", "workout_templates", on_delete: :cascade
  add_foreign_key "workouts", "users", on_delete: :cascade
  add_foreign_key "workouts", "workout_templates"
end
