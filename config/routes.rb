# frozen_string_literal: true
Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  root "welcome#index"

  resources :batches, only: [:index, :create, :show, :destroy] do
    member do
      post :synchronize
    end
    collection do
      post :synchronize_all
    end
  end

  resources :marc_batches, only: [:new, :create, :destroy]

  devise_scope :user do
    get "sign_in", to: "devise/sessions#new", as: :new_user_session
    get "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end
end
