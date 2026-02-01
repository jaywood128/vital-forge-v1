# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "API V1 Workout Templates", type: :request do
  path "/api/v1/workout_templates" do
    get "List workout templates" do
      operationId "listWorkoutTemplates"
      tags "Workout Templates"
      produces "application/json"
      description "Returns all active workout templates. Optional: send JWT or session for has_active_workout and active_workout_id per template."

      parameter name: :Authorization, in: :header, type: :string, required: false,
        description: "Optional JWT: Bearer <token> (shows active workout per template for user)"

      response "200", "templates list" do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: { "$ref" => "#/components/schemas/WorkoutTemplate" }
            }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]).to be_an(Array)
        end
      end
    end
  end

  path "/api/v1/workout_templates/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Workout template ID"

    get "Get workout template" do
      operationId "getWorkoutTemplate"
      tags "Workout Templates"
      produces "application/json"
      description "Returns a single template with exercises. If authenticated, includes has_active_workout and active_workout_id."

      parameter name: :Authorization, in: :header, type: :string, required: false,
        description: "Optional JWT: Bearer <token>"

      response "200", "template found" do
        schema type: :object,
          properties: {
            data: { "$ref" => "#/components/schemas/WorkoutTemplateWithExercises" }
          }

        let(:template) do
          WorkoutTemplate.create!(
            name: "Swagger Template Detail",
            goal_type: "strength",
            difficulty_level: "Intermediate",
            days_per_week: 4,
            estimated_duration_minutes: 45,
            total_exercises: 2,
            source: "Swagger",
            is_active: true
          ).tap do |t|
            ex = Exercise.create!(name: "Template Ex", exercise_type: "Strength", equipment: "Barbell")
            t.workout_template_exercises.create!(
              exercise: ex,
              order_position: 1,
              recommended_sets: 4,
              recommended_reps: "6-8",
              rest_seconds: 90
            )
          end
        end
        let(:id) { template.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["id"]).to eq(template.id)
          expect(data["data"]["exercises"]).to be_an(Array)
        end
      end

      response "404", "template not found" do
        schema type: :object, properties: { error: { type: :string } }
        let(:id) { 999_999 }
        run_test!
      end
    end
  end
end
