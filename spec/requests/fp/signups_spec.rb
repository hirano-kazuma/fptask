# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Fp::Signups", type: :request do
  describe "GET /fp/signup/new" do
    it "returns http success" do
      get new_fp_signup_path
      expect(response).to have_http_status(:ok)
    end

    it "has correct title" do
      get new_fp_signup_path
      expect(response.body).to include("FP登録")
    end
  end

  describe "POST /fp/signup" do
    context "with valid parameters" do
      let(:valid_params) do
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
          post fp_signup_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "creates user with fp role" do
        post fp_signup_path, params: valid_params
        expect(User.last.role_fp?).to be true
      end

      it "redirects to the user page" do
        post fp_signup_path, params: valid_params
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

      it "does not create a new FP user" do
        expect {
          post fp_signup_path, params: invalid_params
        }.not_to change(User, :count)
      end

      it "returns unprocessable entity status" do
        post fp_signup_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
