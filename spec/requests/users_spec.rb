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

      it "displays edit form with current user information" do
        get edit_user_path(user)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(user.name)
        expect(response.body).to include(user.email)
      end
    end

    context "when not logged in" do
      it "redirects to login page with flash message" do
        get edit_user_path(user)
        expect(response).to redirect_to(new_session_path)

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

        it "update user redirects with success message" do
          patch user_path(user), params: valid_params

          # DBが更新されたか
          user.reload
          expect(user.name).to eq('Updated Name')
          expect(user.email).to eq('updated@example.com')

          # リダイレクトされたか
          expect(response).to redirect_to(user)

          # 成功メッセージが表示されたか
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

        it "does not update user and re-renders edit form with error messages" do
          expect {
            patch user_path(user), params: invalid_params
          }.not_to change { user.reload.name }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("設定")
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
      it "redirects to login and does not update the user" do
        expect {
          patch user_path(user), params: { user: { name: 'Hacked' } }
        }.not_to change { user.reload.name }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when logged in as wrong user" do
      before do
        post session_path, params: { session: { email: other_user.email, password: 'password' } }
      end

      it "redirects to root and does not update the user" do
        expect {
          patch user_path(user), params: { user: { name: 'Hacked' } }
        }.not_to change { user.reload.name }

        expect(response).to redirect_to(root_url)
      end
    end
  end
end
