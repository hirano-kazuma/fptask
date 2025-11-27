require "test_helper"

class SiteLayoutTest < ActionDispatch::IntegrationTest

  test "layout links" do
    get root_path
    assert_template "static_pages/home"
    assert_select "a[href=?]", root_path, count: 2
    assert_select "a[href=?]", help_path, count: 2
    assert_select "a[href=?]", about_path, count: 2
  end

  test "header should have logo and navigation" do
    get root_path
    assert_select "header.navbar"
    assert_select "a#logo img[src*='fptask_mark']"
    assert_select "nav" do
      assert_select "a[href=?]", root_path, text: "Home"
      assert_select "a[href=?]", help_path, text: "Help"
      assert_select "a[href=?]", about_path, text: "About"
      assert_select "a", text: "Log in"
    end
  end

  test "footer should have links" do
    get root_path
    assert_select "footer" do
      assert_select "a[href=?]", about_path
      assert_select "a[href=?]", help_path
    end
  end

  test "home page should have correct layout" do
    get root_path
    assert_template "static_pages/home"
    assert_select "title", full_title("Home")
    assert_select "h1", "FP予約管理システム"
    assert_select "div.center.jumbotron"
  end
end
