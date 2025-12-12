# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /users/:id" do
    let!(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password', role: :general) }

    it "returns http success" do
      get user_path(user)
      expect(response).to have_http_status(:ok)
    end

    it "displays user name" do
      get user_path(user)
      expect(response.body).to include(user.name)
    end
  end
end
