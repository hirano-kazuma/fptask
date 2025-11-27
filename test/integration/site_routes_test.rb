require "test_helper"

class SiteRoutesTest < ActionDispatch::IntegrationTest
  test "root path routes to home page" do
    assert_routing "/", controller: "static_pages", action: "home"
  end

  test "help path exists" do
    assert_routing "/help", controller: "static_pages", action: "help"
  end

  test "about path exists" do
    assert_routing "/about", controller: "static_pages", action: "about"
  end

  test "named routes work correctly" do
    get root_path
    assert_response :success

    get help_path
    assert_response :success

    get about_path
    assert_response :success
  end
end

