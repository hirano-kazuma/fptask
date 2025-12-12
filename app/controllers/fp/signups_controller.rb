# frozen_string_literal: true

# 今後FP専用項目が増えることもあるので一般userと分けている
module Fp
  class SignupsController < ApplicationController
    # FP登録フォーム
    def new
      @user = User.new
    end

    # FP登録処理
    def create
      @user = User.new(user_params.merge(role: :fp))
      if @user.save
        redirect_to @user, notice: "FP登録が完了しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
  end
end
