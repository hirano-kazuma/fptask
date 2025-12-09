# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /signup" do
    it "returns http success" do
      get signup_path
      expect(response).to have_http_status(:ok)
    end

    it "has correct title" do
      get signup_path
      expect(response.body).to include("ユーザー登録")
    end
  end

  describe "GET /fp_signup" do
    it "returns http success" do
      get fp_signup_path
      expect(response).to have_http_status(:ok)
    end

    it "has correct title" do
      get fp_signup_path
      expect(response.body).to include("FP登録")
    end
  end

  describe "POST /users" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          user: {
            name: 'Test User',
            email: 'test@example.com',
            password: 'password',
            password_confirmation: 'password'
          }
        }
      end

      it "creates a new user" do
        expect {
          post users_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "redirects to the user page" do
        post users_path, params: valid_params
        expect(response).to redirect_to(User.last)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          user: {
            name: '',
            email: 'invalid',
            password: 'short',
            password_confirmation: 'mismatch'
          }
        }
      end

      it "does not create a new user" do
        expect {
          post users_path, params: invalid_params
        }.not_to change(User, :count)
      end

      it "returns unprocessable entity status" do
        post users_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /fp_signup (FP registration)" do
    context "with valid parameters" do
      let(:valid_fp_params) do
        {
          user: {
            name: 'FP User',
            email: 'fp@example.com',
            password: 'password',
            password_confirmation: 'password'
          }
        }
      end

      it "creates a new FP user" do
        expect {
          post fp_signup_path, params: valid_fp_params
        }.to change(User, :count).by(1)
      end

      it "creates user with fp role" do
        post fp_signup_path, params: valid_fp_params
        expect(User.last.role_fp?).to be true
      end
    end
  end
end
