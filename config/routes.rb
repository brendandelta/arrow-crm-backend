Rails.application.routes.draw do
  # API routes
  namespace :api do
    get "health", to: "health#show"
    get "dashboard", to: "dashboard#show"

    resources :deals, only: [:index, :show, :create, :update] do
      collection do
        get :stats             # GET /api/deals/stats
      end
      # Nested routes for deal targets
      resources :targets, controller: "deal_targets", only: [:index, :create]
    end

    # Advantages for deals (hidden in LP mode)
    resources :advantages, only: [:index, :show, :create, :update, :destroy]

    resources :organizations, only: [:index, :show, :create, :update]
    resources :people, only: [:index, :show, :create, :update] do
      member do
        post :upload_avatar    # POST /api/people/:id/upload_avatar
        delete :destroy_avatar # DELETE /api/people/:id/destroy_avatar
      end
      collection do
        patch :bulk_update     # PATCH /api/people/bulk_update
        delete :bulk_delete    # DELETE /api/people/bulk_delete
      end
    end
    resources :blocks, only: [:index, :show, :create, :update, :destroy]
    resources :interests, only: [:index, :show, :create, :update, :destroy]
    resources :relationship_types, only: [:index, :create]
    resources :relationships, only: [:index, :show, :create, :update, :destroy]
    resources :meetings, only: [:index, :show, :create, :update, :destroy]

    # Deal targets (outreach management)
    resources :deal_targets, only: [:index, :show, :create, :update, :destroy] do
      collection do
        post :bulk_create      # POST /api/deal_targets/bulk_create
        patch :bulk_update     # PATCH /api/deal_targets/bulk_update
        delete :bulk_delete    # DELETE /api/deal_targets/bulk_delete
      end
    end

    # Activities (unified event/interaction tracking - includes meetings)
    resources :activities, only: [:index, :show, :create, :update, :destroy] do
      member do
        post :complete_task    # POST /api/activities/:id/complete_task
      end
      collection do
        get :timeline          # GET /api/activities/timeline?deal_id=X
        get :tasks             # GET /api/activities/tasks
        get :calendar          # GET /api/activities/calendar?start=X&end=Y
      end
    end
  end

  # Rails health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check
end
