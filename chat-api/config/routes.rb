Rails.application.routes.draw do
  root to: "applications#index"
  
  resources :applications, param: :token, only: %i[index show create update destroy] do
    resources :chats,param: :number, only: %i[index show create destroy] do
      resources :messages,param: :number, only: %i[index show create destroy] do
        collection do
          get :search
        end
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
