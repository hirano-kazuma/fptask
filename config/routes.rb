Rails.application.routes.draw do
  root "static_pages#home"
  get "/help", to: "static_pages#help"
  get "/about", to: "static_pages#about"

  # ユーザー登録
  get "/signup", to: "users#new"
  resources :users, only: %i(new create show)

  # FP登録
  get "/fp_signup", to: "users#new_fp"
  post "/fp_signup", to: "users#create_fp"

  get "up" => "rails/health#show", as: :rails_health_check

end
