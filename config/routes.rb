Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "status/:token", to: "public_status#show", as: :public_status

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root to: "rodauth#login"

  get "dashboard", to: "dashboard#index", as: :dashboard

  resources :nodes do
    member do
      post :move_up
      post :move_down
      get :edit
      patch :update
    end
  end

  resource :settings, only: [ :show, :update ]

  resources :alerts do
    member do
      post :resolve
    end
  end

  resource :alert_integrations, only: :show do
    post :recipients, to: "alert_integrations#create_recipient", as: :recipients
    post "recipients/:id/toggle", to: "alert_integrations#toggle_recipient", as: :toggle_recipient
    post "triggers/:id/toggle", to: "alert_integrations#toggle_trigger", as: :toggle_trigger
  end
end
