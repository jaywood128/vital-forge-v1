require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  # Swagger UI at /api-docs
  if defined?(Rswag::Ui::Engine)
    mount Rswag::Ui::Engine => "/api-docs"
  end
  # OpenAPI spec files at /openapi/v1/swagger.yaml (UI fetches from this)
  if defined?(Rswag::Api::Engine)
    mount Rswag::Api::Engine => "/openapi"
  end

  # Mount Sidekiq Web UI
  mount Sidekiq::Web => "/sidekiq"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # API-only application - all routes under /api/v1
  namespace :api do
    namespace :v1 do
      # Health check endpoint for ALB
      get "health", to: proc { [ 200, {}, [ "ok" ] ] }

      # CSRF token for Next.js
      get "csrf", to: "csrf#show"

      # User registration (both web and mobile)
      post "signup", to: "users#create"

      # Web routes (Next.js) - Session-based authentication
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy"
      get "current_user", to: "current_users#show"

      # Mobile routes - JWT token authentication
      namespace :mobile do
        post "signup", to: "users#create"
        post "login", to: "sessions#create"
        delete "logout", to: "sessions#destroy"
        get "current_user", to: "current_users#show"
      end

      # Shared resources (support both session and JWT authentication)
      resources :workouts, only: [ :index, :show ] do
        member do
          patch :start      # Begin active workout
          patch :complete   # Finish workout
        end
      end

      resources :workout_templates, only: [ :index, :show ] do
        member do
          post :start, to: "workouts#start_from_template"  # Start workout from template (creates new workout)
        end
      end

      resources :exercise_sets, only: [ :update ]
      resource :user_preference, only: [ :show, :create, :update ]

      # Weekly AI feedback
      resource :weekly_feedbacks, only: [] do
        get :current, on: :collection
      end

      # resources :exercises
    end
  end
end
