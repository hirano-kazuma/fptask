# frozen_string_literal: true

class SignupsController < ApplicationController
  # 一般ユーザー登録フォーム
  def new
    @user = User.new
  end

  # 一般ユーザー登録処理
  def create
    @user = User.new(user_params.merge(role: :general))
    if @user.save
      redirect_to @user, notice: "ユーザー登録が完了しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
