# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#full_title" do
    it "returns base title when page title is empty" do
      expect(helper.full_title).to eq("FP予約管理システム")
    end

    it "returns base title when page title is blank" do
      expect(helper.full_title("")).to eq("FP予約管理システム")
    end

    it "returns full title with page title" do
      expect(helper.full_title("Help")).to eq("Help | FP予約管理システム")
      expect(helper.full_title("About")).to eq("About | FP予約管理システム")
    end
  end
end
