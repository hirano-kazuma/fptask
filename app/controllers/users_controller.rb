# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :logged_in_user, only: %i[edit update]
  before_action :correct_user, only: %i[edit update]

  # ユーザー詳細
  def show
    @user = User.find(params[:id])
  end
end
