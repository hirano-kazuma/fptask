# frozen_string_literal: true

module SessionsHelper
  # 渡されたユーザーでログインする
  def login(user)
    session[:user_id] = user.id
  end

  # 現在ログイン中のユーザーを返す（いる場合）
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # ユーザーがログインしていればtrue、その他ならfalseを返す
  def logged_in?
    !current_user.nil?
  end

  # 現在のユーザーをログアウトする
  def logout
    session.delete(:user_id)
    @current_user = nil
  end

  # 渡されたユーザーが現在のユーザーであればtrueを返す
  def current_user?(user)
    user && user == current_user
  end
end
