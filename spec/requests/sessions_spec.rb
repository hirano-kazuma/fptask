# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let!(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password', role: :general) }

  describe "GET /login" do
    it "returns http success" do
      get login_path
      expect(response).to have_http_status(:success)
    end

    it "has correct title" do
      get login_path
      expect(response.body).to include("ログイン")
    end
  end

  describe "POST /login" do
    context "with valid credentials" do
      it "logs in the user" do
        post login_path, params: { session: { email: user.email, password: 'password' } }
        expect(response).to redirect_to(user)
      end

      it "redirects to user profile" do
        post login_path, params: { session: { email: user.email, password: 'password' } }
        follow_redirect!
        expect(response.body).to include(user.name)
      end
    end

    context "with invalid credentials" do
      it "does not log in with wrong password" do
        post login_path, params: { session: { email: user.email, password: 'wrongpassword' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not log in with wrong email" do
        post login_path, params: { session: { email: 'wrong@example.com', password: 'password' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shows error message" do
        post login_path, params: { session: { email: user.email, password: 'wrongpassword' } }
        expect(response.body).to include("メールアドレスまたはパスワードが間違っています")
      end
    end

    context "with case-insensitive email" do
      it "logs in with uppercase email" do
        post login_path, params: { session: { email: 'TEST@EXAMPLE.COM', password: 'password' } }
        expect(response).to redirect_to(user)
      end
    end

    context "with empty parameters" do
      it "does not log in with empty email" do
        post login_path, params: { session: { email: '', password: 'password' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not log in with empty password" do
        post login_path, params: { session: { email: user.email, password: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /logout" do
    before do
      post login_path, params: { session: { email: user.email, password: 'password' } }
    end

    # 未ログイン状態でのログアウトテスト
    context "when logged in" do
      it "redirects to root without error" do
        delete logout_path
        expect(response).to redirect_to(root_url)
      end
    end

    it "logs out the user" do
      delete logout_path
      expect(response).to redirect_to(root_url)
    end

    it "redirects to root" do
      delete logout_path
      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end

  describe "header navigation" do
    context "when not logged in" do
      it "shows login link" do
        get root_path
        expect(response.body).to include("Log in")
        expect(response.body).not_to include("Account")
      end
    end

    context "when logged in" do
      before do
        post login_path, params: { session: { email: user.email, password: 'password' } }
      end

      it "shows account dropdown" do
        get root_path
        expect(response.body).to include("Account")
        expect(response.body).to include("Profile")
        expect(response.body).to include("Log out")
        expect(response.body).not_to include(">Log in<")
      end
    end
  end
end
