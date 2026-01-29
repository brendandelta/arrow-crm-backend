Rails.application.routes.draw do
  # API routes
  namespace :api do
    get "health", to: "health#show"
    get "dashboard", to: "dashboard#show"

    resources :deals, only: [:index, :show, :create, :update] do
      collection do
        get :stats             # GET /api/deals/stats
        get :mind_map          # GET /api/deals/mind_map
      end
      # Nested routes for deal targets
      resources :targets, controller: "deal_targets", only: [:index, :create]
    end

    # Advantages for deals (hidden in LP mode) - legacy, prefer edges
    resources :advantages, only: [:index, :show, :create, :update, :destroy]

    # Edges - unique insights/angles for closing deals (hidden in LP mode)
    resources :edges, only: [:index, :show, :create, :update, :destroy]

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
        get :tasks             # GET /api/activities/tasks (legacy - use /api/tasks instead)
        get :calendar          # GET /api/activities/calendar?start=X&end=Y
      end
    end

    # Tasks (dedicated task management)
    resources :tasks, only: [:index, :show, :create, :update, :destroy] do
      member do
        post :complete         # POST /api/tasks/:id/complete
        post :uncomplete       # POST /api/tasks/:id/uncomplete
      end
      collection do
        get :my_tasks          # GET /api/tasks/my_tasks?user_id=X
        get :grouped           # GET /api/tasks/grouped?deal_id=X
        get :grouped_by_deal   # GET /api/tasks/grouped_by_deal
        get :grouped_by_project # GET /api/tasks/grouped_by_project
        get :stats             # GET /api/tasks/stats
      end
    end

    # Projects (non-deal initiatives)
    resources :projects, only: [:index, :show, :create, :update, :destroy]

    # Users (for assignee dropdowns)
    resources :users, only: [:index, :show]

    # Internal Entities (Arrow-controlled entities: MgmtCo, GP, SPVs, Trusts)
    resources :internal_entities, only: [:index, :show, :create, :update, :destroy] do
      member do
        post :reveal_ein           # POST /api/internal_entities/:id/reveal_ein
      end
      resources :bank_accounts, only: [:create], controller: 'bank_accounts'
      resources :signers, only: [:create], controller: 'entity_signers'
    end

    # Bank Accounts (standalone routes for update/delete/reveal)
    resources :bank_accounts, only: [:show, :update, :destroy] do
      member do
        post :reveal_numbers       # POST /api/bank_accounts/:id/reveal_numbers
      end
    end

    # Entity Signers (standalone routes for update/delete)
    resources :entity_signers, only: [:show, :update, :destroy]

    # Documents (enhanced document management)
    resources :documents, only: [:index, :show, :create, :update, :destroy] do
      member do
        post :new_version          # POST /api/documents/:id/new_version
      end
    end

    # Document Links (unified linking)
    resources :document_links, only: [:index, :show, :create, :update, :destroy] do
      collection do
        post :bulk_create          # POST /api/document_links/bulk_create
      end
    end

    # Credential Vault System
    resources :vaults, only: [:index, :show, :create, :update, :destroy] do
      member do
        get :rotation              # GET /api/vaults/:id/rotation
      end
      resources :memberships, controller: 'vault_memberships', only: [:index, :create]
      resources :credentials, only: [:index, :create]
    end

    # Vault Memberships (standalone routes for update/delete)
    resources :vault_memberships, only: [:update, :destroy]

    # Credentials (standalone routes)
    resources :credentials, only: [:show, :update, :destroy] do
      member do
        post :reveal               # POST /api/credentials/:id/reveal
        post :copy                 # POST /api/credentials/:id/copy
      end
      resources :fields, controller: 'credential_fields', only: [:create]
      resources :links, controller: 'credential_links', only: [:create]
    end

    # Credential Fields (standalone routes)
    resources :credential_fields, only: [:update, :destroy]

    # Credential Links (standalone routes)
    resources :credential_links, only: [:destroy]

    # Security Audit Logs (read-only for admin/ops)
    resources :security_audit_logs, only: [:index]
  end

  # Rails health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check
end
