# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users", type: :request do
  let!(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password', role: :general) }
  let!(:other_user) { User.create!(name: 'Other User', email: 'other@example.com', password: 'password', role: :general) }

  describe "GET /users/:id" do
    it "returns http success" do
      get user_path(user)
      expect(response).to have_http_status(:ok)
    end

    it "displays user name" do
      get user_path(user)
      expect(response.body).to include(user.name)
    end
  end

  describe "GET /users/:id/edit" do
    context "when logged in as correct user" do
      before do
        post session_path, params: { session: { email: user.email, password: 'password' } }
      end

      it "returns http success" do
        get edit_user_path(user)
        expect(response).to have_http_status(:ok)
      end

      it "displays page title" do
        get edit_user_path(user)
        expect(response.body).to include("設定")
      end

      it "displays current user name in form" do
        get edit_user_path(user)
        expect(response.body).to include(user.name)
      end

      it "displays current user email in form" do
        get edit_user_path(user)
        expect(response.body).to include(user.email)
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get edit_user_path(user)
        expect(response).to redirect_to(new_session_path)
      end

      it "displays flash message after redirect" do
        get edit_user_path(user)
        follow_redirect!
        expect(response.body).to include("ログインが必要です")
      end
    end

    context "when logged in as wrong user" do
      before do
        post session_path, params: { session: { email: other_user.email, password: 'password' } }
      end

      it "redirects to root" do
        get edit_user_path(user)
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "PATCH /users/:id" do
    context "when logged in as correct user" do
      before do
        post session_path, params: { session: { email: user.email, password: 'password' } }
      end

      context "with valid parameters" do
        let(:valid_params) do
          { user: { name: 'Updated Name', email: 'updated@example.com' } }
        end

        it "updates the user name" do
          patch user_path(user), params: valid_params
          user.reload
          expect(user.name).to eq('Updated Name')
        end

        it "updates the user email" do
          patch user_path(user), params: valid_params
          user.reload
          expect(user.email).to eq('updated@example.com')
        end

        it "redirects to user profile" do
          patch user_path(user), params: valid_params
          expect(response).to redirect_to(user)
        end

        it "displays success message after redirect" do
          patch user_path(user), params: valid_params
          follow_redirect!
          expect(response.body).to include("ユーザー情報が更新されました")
        end
      end

      context "with password update" do
        let(:password_params) do
          { user: { password: 'newpassword', password_confirmation: 'newpassword' } }
        end

        it "updates the password" do
          patch user_path(user), params: password_params
          user.reload
          expect(user.authenticate('newpassword')).to be_truthy
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          { user: { name: '', email: 'invalid' } }
        end

        it "does not update the user" do
          original_name = user.name
          patch user_path(user), params: invalid_params
          user.reload
          expect(user.name).to eq(original_name)
        end

        it "returns unprocessable entity status" do
          patch user_path(user), params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "re-renders edit form" do
          patch user_path(user), params: invalid_params
          expect(response.body).to include("設定")
        end

        it "displays error messages" do
          patch user_path(user), params: invalid_params
          expect(response.body).to include("error_explanation")
          expect(response.body).to include("エラー")
        end
      end

      context "with mismatched password confirmation" do
        let(:mismatch_params) do
          { user: { password: 'newpassword', password_confirmation: 'different' } }
        end

        it "does not update the user" do
          patch user_path(user), params: mismatch_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        patch user_path(user), params: { user: { name: 'Hacked' } }
        expect(response).to redirect_to(new_session_path)
      end

      it "does not update the user" do
        original_name = user.name
        patch user_path(user), params: { user: { name: 'Hacked' } }
        user.reload
        expect(user.name).to eq(original_name)
      end
    end

    context "when logged in as wrong user" do
      before do
        post session_path, params: { session: { email: other_user.email, password: 'password' } }
      end

      it "redirects to root" do
        patch user_path(user), params: { user: { name: 'Hacked' } }
        expect(response).to redirect_to(root_url)
      end

      it "does not update the user" do
        original_name = user.name
        patch user_path(user), params: { user: { name: 'Hacked' } }
        user.reload
        expect(user.name).to eq(original_name)
      end
    end
  end
end
