# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "has correct title" do
      get root_path
      expect(response.body).to include("Home | FP予約管理システム")
    end
  end

  describe "GET /help" do
    it "returns http success" do
      get help_path
      expect(response).to have_http_status(:ok)
    end

    it "has correct title" do
      get help_path
      expect(response.body).to include("Help | FP予約管理システム")
    end
  end

  describe "GET /about" do
    it "returns http success" do
      get about_path
      expect(response).to have_http_status(:ok)
    end

    it "has correct title" do
      get about_path
      expect(response.body).to include("About | FP予約管理システム")
    end

    it "has correct headings" do
      get about_path
      expect(response.body).to include("FP予約管理システムについて")
      expect(response.body).to include("システム概要")
      expect(response.body).to include("予約枠について")
      expect(response.body).to include("利用方法")
      expect(response.body).to include("主な機能")
      expect(response.body).to include("注意事項")
    end

    it "displays reservation time information" do
      get about_path
      expect(response.body).to match(/1予約枠：30分/)
      expect(response.body).to match(/平日.*10:00〜18:00/)
      expect(response.body).to include("土曜日：11:00〜15:00")
      expect(response.body).to include("日曜日：休業日")
    end

    it "displays user usage instructions" do
      get about_path
      expect(response.body).to include("ユーザーの方")
      expect(response.body).to include("アカウント登録")
      expect(response.body).to include("予約枠確認")
    end

    it "displays FP usage instructions" do
      get about_path
      expect(response.body).to include("FPの方")
      expect(response.body).to include("予約枠設定")
      expect(response.body).to include("予約管理")
    end
  end
end
