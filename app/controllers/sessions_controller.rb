# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params.dig(:session, :email).downcase)
    if user && user.authenticate(params[:session][:password])
      reset_session
      login user
      redirect_to user
    else
      flash.now[:danger] = "メールアドレスまたはパスワードが間違っています"
      render "new", status: :unprocessable_entity
    end
  end

  def destroy
    logout if logged_in?
    redirect_to root_url, status: :see_other
  end
end
