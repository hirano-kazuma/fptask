# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsHelper, type: :helper do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password', role: :general) }

  describe "#login" do
    it "sets the user id in session" do
      helper.login(user)
      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe "#current_user" do
    context "when user is logged in" do
      before { session[:user_id] = user.id }

      it "returns the current user" do
        expect(helper.current_user).to eq(user)
      end
    end

    context "when no user is logged in" do
      it "returns nil" do
        expect(helper.current_user).to be_nil
      end
    end
  end

  describe "#logged_in?" do
    context "when user is logged in" do
      before { session[:user_id] = user.id }

      it "returns true" do
        expect(helper.logged_in?).to be true
      end
    end

    context "when no user is logged in" do
      it "returns false" do
        expect(helper.logged_in?).to be false
      end
    end
  end

  describe "#logout" do
    before do
      session[:user_id] = user.id
      helper.instance_variable_set(:@current_user, user)
    end

    it "clears the session" do
      helper.logout
      expect(session[:user_id]).to be_nil
    end

    it "clears the current user" do
      helper.logout
      expect(helper.instance_variable_get(:@current_user)).to be_nil
    end
  end
end
