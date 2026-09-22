# frozen_string_literal: true

module Abid
  class Routes < Hanami::Routes
    # Ported 1:1 from the Rails config/routes.rb. Paths, verbs and names are
    # preserved exactly: the CAS service registration, the hard-coded links in
    # the layout, and the specs' path helpers all depend on them.

    # Replaces `mount HealthMonitor::Engine, at: "/"`. That engine served both
    # /health and /health.json through Rails' format suffixes; Hanami's router
    # has no such concept, so both are declared. Both Nomad job specs poll
    # /health.json every 10s, so this path is a deployment contract.
    get "/health", to: "health.show", as: :health
    get "/health.json", to: "health.show"

    # `root "welcome#index"`
    root to: "welcome.index"

    # devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
    #
    # The request phase (/users/auth/cas) is handled by the OmniAuth Rack
    # middleware before routing, exactly as it was under Devise. Only the
    # callback needs an action.
    get "/users/auth/cas/callback", to: "sessions.create", as: :user_cas_omniauth_callback
    post "/users/auth/cas/callback", to: "sessions.create"

    # devise_scope :user do ... end
    #
    # NOTE: GET /sign_in was already broken in the Rails app — it rendered
    # Devise's packaged sessions/new template, which calls the undefined
    # `session_path` because User had no :database_authenticatable. Nothing
    # links to it. The route is kept for parity; it is not expected to work.
    get "/sign_in", to: "sessions.new", as: :new_user_session
    get "/sign_out", to: "sessions.destroy", as: :destroy_user_session

    # resources :batches, only: [:index, :create, :show, :destroy] do
    #   member { post :synchronize }
    #   collection { post :synchronize_all }
    # end
    #
    # The collection route must precede /batches/:id so that
    # "synchronize_all" is not captured as an :id.
    get "/batches", to: "batches.index", as: :batches
    post "/batches", to: "batches.create"
    post "/batches/synchronize_all", to: "batches.synchronize_all", as: :synchronize_all_batches
    post "/batches/:id/synchronize", to: "batches.synchronize", as: :synchronize_batch
    get "/batches/:id", to: "batches.show", as: :batch
    delete "/batches/:id", to: "batches.destroy"

    # resources :marc_batches, only: [:new, :create, :show, :destroy] do
    #   member { post :synchronize }
    # end
    get "/marc_batches/new", to: "marc_batches.new", as: :new_marc_batch
    post "/marc_batches", to: "marc_batches.create", as: :marc_batches
    post "/marc_batches/:id/synchronize", to: "marc_batches.synchronize", as: :synchronize_marc_batch
    get "/marc_batches/:id", to: "marc_batches.show", as: :marc_batch
    delete "/marc_batches/:id", to: "marc_batches.destroy"
  end
end
