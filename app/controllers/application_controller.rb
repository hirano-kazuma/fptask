# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include SessionsHelper

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # ログイン済みユーザーかどうかを確認
  def logged_in_user
    unless logged_in?
      flash[:danger] = "ログインしてください"
      redirect_to new_session_path
    end
  end

  # FPユーザーかどうかを確認
  def fp_user
    unless current_user&.role_fp?
      flash[:danger] = "FPユーザーではありません"
      redirect_to root_url
    end
  end
end
