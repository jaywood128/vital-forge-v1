Rails.application.routes.draw do
  if defined?(Rswag::Ui::Engine)
    mount Rswag::Ui::Engine => '/api-docs'
  end
  if defined?(Rswag::Api::Engine)
    mount Rswag::Api::Engine => '/api-docs'
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root route (public landing page)
  root "pages#home"

  # Authentication routes
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # User registration routes
  get    "signup", to: "users#new"
  post   "users",  to: "users#create"

  # Protected routes (require authentication)
  get "dashboard", to: "dashboard#index"

  # Devise minimal routes (skip HTML flows for now)
  devise_for :users, skip: [:registrations, :passwords, :confirmations]

  namespace :api do
    namespace :v1 do
      get    "csrf",         to: "csrf#show"
      devise_scope :user do
        post   "login",      to: "sessions#create"
        delete "logout",      to: "sessions#destroy"
        get    "current_user", to: "current_users#show"
      end
      # Workouts CRUD etc. can live here as you implement
    end
  end
end
