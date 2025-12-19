# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :logged_in_user, only: %i[edit update]
  before_action :correct_user, only: %i[edit update]

  def show
    if logged_in? && current_user.id == params[:id].to_i
      @user = current_user
      return
    end

    # それ以外はFPのみ検索
    @user = User.where(role: :fp).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to root_url, alert: "このページは閲覧できません"
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to @user, notice: "ユーザー情報が更新されました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end
end
