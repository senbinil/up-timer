Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Public home page — shows listed services
  root to: "home#show"

  get "dashboard", to: "dashboard#index", as: :dashboard

  resources :nodes do
    member do
      post :move_up
      post :move_down
      patch :assign_tag
      get :edit
      patch :update
      post :pause
      post :resume
      post :toggle_public_listed
    end
  end

  resource :settings, only: [ :show, :update ]

  resources :alerts do
    member do
      post :resolve
    end
  end

  resources :users, only: :index do
    member do
      patch :update_role
    end
  end

  resource :alert_integrations, only: :show do
    get :search_recipients
    post :recipients, to: "alert_integrations#create_recipient", as: :recipients
    post "recipients/:id/toggle", to: "alert_integrations#toggle_recipient", as: :toggle_recipient
    post "triggers/:id/toggle_email", to: "alert_integrations#toggle_trigger_email", as: :toggle_trigger_email
  end
end
