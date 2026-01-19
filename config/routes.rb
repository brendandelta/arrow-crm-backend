Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      get "dashboard", to: "dashboard#show"
      resources :deals, only: [:index, :show]
      resources :organizations, only: [:index, :show]
      resources :people, only: [:index, :show]
    end
  end

  # Rails health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check
end
