# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root directory where Swagger JSON files are generated
  # NOTE: If you're using rswag-api to expose the generated Swagger as JSON,
  # then set this to a directory within the Rails.root that's served by the
  # web server
  config.swagger_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each
  config.swagger_docs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "VitalForge API V1",
        version: "v1",
        description: "VitalForge Fitness Tracking Application API - Authentication, Workouts, Templates, Exercise Sets, User Preferences, and Weekly AI Feedback",
        contact: {
          name: "VitalForge Team",
          email: "support@vitalforge.com"
        }
      },
      paths: {},
      servers: [
        {
          url: "http://localhost:3000",
          description: "Development server"
        },
        {
          url: "https://api.vitalforge.com",
          description: "Production server"
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT",
            description: "JWT token for mobile authentication. To test: 1) Call /api/v1/mobile/login or /api/v1/mobile/signup, 2) Copy the 'token' from response, 3) Click 'Authorize' button and paste token (without 'Bearer' prefix)"
          },
          csrf_token: {
            type: :apiKey,
            name: "X-CSRF-Token",
            in: :header,
            description: "CSRF protection token (required for web POST/PUT/DELETE)"
          },
          session_cookie: {
            type: :apiKey,
            name: "Cookie",
            in: :header,
            description: "Session cookie (automatically set after web login)"
          }
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              email: { type: :string, format: :email, example: "john.doe@example.com" },
              first_name: { type: :string, example: "John" },
              last_name: { type: :string, example: "Doe" },
              full_name: { type: :string, example: "John Doe" },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: [ "id", "email" ]
          },
          UserRegistration: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: "john.doe@example.com" },
              password: { type: :string, format: :password, example: "SecurePass123!" },
              password_confirmation: { type: :string, format: :password, example: "SecurePass123!" },
              first_name: { type: :string, example: "John" },
              last_name: { type: :string, example: "Doe" }
            },
            required: [ "email", "password", "password_confirmation", "first_name", "last_name" ]
          },
          LoginCredentials: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: "john.doe@example.com" },
              password: { type: :string, format: :password, example: "SecurePass123!" }
            },
            required: [ "email", "password" ]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string, example: "Invalid email or password" }
            }
          },
          ValidationErrors: {
            type: :object,
            properties: {
              errors: {
                type: :object,
                additionalProperties: {
                  type: :array,
                  items: { type: :string }
                },
                example: {
                  email: [ "can't be blank", "is invalid" ],
                  password: [ "is too short (minimum is 8 characters)" ]
                }
              }
            }
          },
          SuccessMessage: {
            type: :object,
            properties: {
              message: { type: :string, example: "Successfully logged out" }
            }
          },
          Workout: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string, nullable: true },
              workout_date: { type: :string, format: :date },
              scheduled_time: { type: :string, nullable: true, example: "09:00" },
              workout_template_id: { type: :integer, nullable: true },
              started_at: { type: :string, format: :"date-time", nullable: true },
              completed_at: { type: :string, format: :"date-time", nullable: true },
              duration_minutes: { type: :integer, nullable: true },
              workout_type: { type: :string, nullable: true },
              calories_burned: { type: :integer, nullable: true },
              notes: { type: :string, nullable: true },
              intensity_level: { type: :string, nullable: true },
              completed: { type: :boolean },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            }
          },
          WorkoutWithExercises: {
            type: :object,
            allOf: [
              { "$ref" => "#/components/schemas/Workout" },
              {
                type: :object,
                properties: {
                  workout_exercises: {
                    type: :array,
                    items: { "$ref" => "#/components/schemas/WorkoutExercise" }
                  }
                }
              }
            ]
          },
          WorkoutExercise: {
            type: :object,
            properties: {
              id: { type: :integer },
              order_position: { type: :integer },
              notes: { type: :string, nullable: true },
              rest_between_sets: { type: :integer, nullable: true },
              completed: { type: :boolean },
              exercise: { "$ref" => "#/components/schemas/ExerciseSummary" },
              exercise_sets: {
                type: :array,
                items: { "$ref" => "#/components/schemas/ExerciseSetSummary" }
              }
            }
          },
          ExerciseSummary: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              muscle_group: { type: :string, nullable: true },
              equipment: { type: :string },
              exercise_type: { type: :string }
            }
          },
          ExerciseSetSummary: {
            type: :object,
            properties: {
              id: { type: :integer },
              set_number: { type: :integer },
              reps: { type: :integer },
              weight: { type: :number, nullable: true },
              weight_unit: { type: :string, nullable: true },
              rpe: { type: :integer, nullable: true },
              to_failure: { type: :boolean },
              notes: { type: :string, nullable: true },
              completed: { type: :boolean }
            }
          },
          ExerciseSet: {
            type: :object,
            properties: {
              id: { type: :integer },
              workout_exercise_id: { type: :integer },
              set_number: { type: :integer },
              reps: { type: :integer },
              weight: { type: :number, nullable: true },
              weight_unit: { type: :string, nullable: true },
              rest_after_seconds: { type: :integer, nullable: true },
              rpe: { type: :integer, nullable: true },
              to_failure: { type: :boolean },
              notes: { type: :string, nullable: true },
              completed: { type: :boolean },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            }
          },
          ExerciseSetUpdate: {
            type: :object,
            properties: {
              reps: { type: :integer },
              weight: { type: :number },
              weight_unit: { type: :string },
              rest_after_seconds: { type: :integer },
              rpe: { type: :integer },
              to_failure: { type: :boolean },
              notes: { type: :string },
              completed: { type: :boolean }
            }
          },
          WorkoutTemplate: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string, nullable: true },
              goal_type: { type: :string, nullable: true },
              difficulty_level: { type: :string, nullable: true },
              days_per_week: { type: :integer, nullable: true },
              estimated_duration_minutes: { type: :integer, nullable: true },
              total_exercises: { type: :integer, nullable: true },
              source: { type: :string, nullable: true },
              has_active_workout: { type: :boolean },
              active_workout_id: { type: :integer, nullable: true },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            }
          },
          WorkoutTemplateWithExercises: {
            type: :object,
            allOf: [
              { "$ref" => "#/components/schemas/WorkoutTemplate" },
              {
                type: :object,
                properties: {
                  exercises: {
                    type: :array,
                    items: { "$ref" => "#/components/schemas/WorkoutTemplateExercise" }
                  }
                }
              }
            ]
          },
          WorkoutTemplateExercise: {
            type: :object,
            properties: {
              id: { type: :integer },
              exercise_id: { type: :integer },
              order_position: { type: :integer },
              recommended_sets: { type: :integer },
              recommended_reps: { type: :string },
              rest_seconds: { type: :integer, nullable: true },
              notes: { type: :string, nullable: true },
              exercise: { "$ref" => "#/components/schemas/ExerciseDetail" }
            }
          },
          ExerciseDetail: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string, nullable: true },
              exercise_type: { type: :string },
              equipment: { type: :string },
              muscle_group: { type: :string, nullable: true },
              difficulty_level: { type: :string, nullable: true },
              instructions: { type: :string, nullable: true }
            }
          },
          UserPreference: {
            type: :object,
            properties: {
              id: { type: :integer },
              user_id: { type: :integer },
              primary_goal: { type: :string, enum: %w[physique strength], nullable: true },
              training_days_per_week: { type: :integer, nullable: true },
              preferred_workout_duration: { type: :integer, nullable: true },
              experience_level: { type: :string, enum: %w[Beginner Intermediate Advanced], nullable: true },
              onboarding_completed: { type: :boolean },
              onboarding_completed_at: { type: :string, format: :"date-time", nullable: true },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            }
          },
          UserPreferenceCreateUpdate: {
            type: :object,
            properties: {
              primary_goal: { type: :string, enum: %w[physique strength] },
              training_days_per_week: { type: :integer },
              preferred_workout_duration: { type: :integer },
              experience_level: { type: :string, enum: %w[Beginner Intermediate Advanced] }
            }
          },
          WeeklyFeedback: {
            type: :object,
            properties: {
              feedback: { type: :string, description: "AI-generated feedback text" },
              week_start: { type: :string, format: :date },
              generated_at: { type: :string, format: :"date-time" },
              stats: { type: :object, description: "Snapshot of user stats for the week", nullable: true }
            }
          },
          StartFromTemplateParams: {
            type: :object,
            properties: {
              scheduled_time: { type: :string, example: "09:00", description: "Optional scheduled time (HH:MM)" }
            }
          }
        }
      },
      tags: [
        {
          name: "Health",
          description: "Health check and API status"
        },
        {
          name: "API Authentication",
          description: "Web session-based authentication (CSRF, login, logout, current user)"
        },
        {
          name: "Users",
          description: "User registration (signup)"
        },
        {
          name: "Mobile Authentication",
          description: "JWT-based authentication for mobile clients"
        },
        {
          name: "Workouts",
          description: "Workout sessions (list, show, start, complete, start from template)"
        },
        {
          name: "Workout Templates",
          description: "Predefined workout templates (list, show)"
        },
        {
          name: "Exercise Sets",
          description: "Update exercise set data (reps, weight, completed, etc.)"
        },
        {
          name: "User Preferences",
          description: "User preferences and onboarding"
        },
        {
          name: "Weekly Feedback",
          description: "AI-generated weekly feedback"
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'
  # The swagger_docs configuration option has the filename, and format in
  # the key, this may want to be changed to avoid putting yaml in json files
  config.swagger_format = :yaml
end
