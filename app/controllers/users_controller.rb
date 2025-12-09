class UsersController < ApplicationController
  # 一般ユーザー登録フォーム
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role = :general  # 一般ユーザーとして登録（role = 0）
    if @user.save
      redirect_to @user, notice: "ユーザー登録が完了しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def new_fp
    @user = User.new
    render :new_fp
  end

  def create_fp
    @user = User.new(user_params)
    @user.role = :fp
    if @user.save
      redirect_to @user, notice: "FP登録が完了しました"
    else
      render :new_fp, status: :unprocessable_entity
    end
  end

  # ユーザー詳細
  def show
    @user = User.find(params[:id])
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end
