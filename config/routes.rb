Rails.application.routes.draw do
  root "static_pages#home"
  get "/help", to: "static_pages#help"
  get "/about", to: "static_pages#about"

  # ユーザー登録（一般ユーザー）
  resource :signup, only: %i[new create]

  # FP登録
  namespace :fp do
    resource :signup, only: %i[new create]
  end

  resources :users, only: %i[show]

  # セッション
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  get "up" => "rails/health#show", as: :rails_health_check
end
