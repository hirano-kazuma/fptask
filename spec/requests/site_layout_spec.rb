# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "SiteLayout", type: :request do
  describe "layout links" do
    it "has correct links on the page" do
      get root_path

      expect(response).to have_http_status(:ok)
      # ホームへのリンクが存在する
      expect(response.body).to include(root_path)
      # ヘルプへのリンクが存在する
      expect(response.body).to include(help_path)
      # Aboutへのリンクが存在する
      expect(response.body).to include(about_path)
    end
  end

  describe "header" do
    it "has logo and navigation links" do
      get root_path

      expect(response).to have_http_status(:ok)
      # ナビゲーションリンクが存在する
      expect(response.body).to include("Home")
      expect(response.body).to include("Help")
      expect(response.body).to include("About")
      expect(response.body).to include("Log in")
    end
  end

  describe "footer" do
    it "has links to about and help" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(about_path)
      expect(response.body).to include(help_path)
    end
  end

  describe "home page layout" do
    it "has correct content" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Home | FP予約管理システム")
      expect(response.body).to include("FP予約管理システム")
      expect(response.body).to include("jumbotron")
    end
  end
end
