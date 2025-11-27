require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "full title helper" do
    assert_equal "FP予約管理システム", full_title
    assert_equal "Help | FP予約管理システム", full_title("Help")
    assert_equal "About | FP予約管理システム", full_title("About")
  end
end

