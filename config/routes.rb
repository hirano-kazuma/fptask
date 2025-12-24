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

  resources :users, only: %i[show edit update]

  # セッション
  resource :session, only: %i[new create destroy]

  # 予約枠（FP用・一般ユーザー用）
  resources :time_slots

  # 予約（一般ユーザー用・FP用）
  resources :bookings, only: %i[index show new create destroy] do
    member do
      patch :confirm  # 承認
      patch :reject   # 拒否
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
