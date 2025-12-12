# frozen_string_literal: true

class UsersController < ApplicationController
  # ユーザー詳細
  def show
    @user = User.find(params[:id])
  end
end
