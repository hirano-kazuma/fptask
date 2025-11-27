require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_path
    assert_response :success
    assert_select "title", "Home | FP予約管理システム"
  end

  test "should get help" do
    get help_path
    assert_response :success
    assert_select "title", "Help | FP予約管理システム"
  end

  test "should get about" do
    get about_path
    assert_response :success
    assert_select "title", "About | FP予約管理システム"
  end

  test "about page should have correct content" do
    get about_path
    assert_response :success
    assert_select "h1", "FP予約管理システムについて"
    assert_select "h2", "システム概要"
    assert_select "h2", "予約枠について"
    assert_select "h2", "利用方法"
    assert_select "h2", "主な機能"
    assert_select "h2", "注意事項"
  end

  test "about page should display reservation time information" do
    get about_path
    assert_response :success
    assert_match /1予約枠：30分/, response.body
    assert_match /平日.*10:00〜18:00/, response.body
    assert_match /土曜日：11:00〜15:00/, response.body
    assert_match /日曜日：休業日/, response.body
  end

  test "about page should display user usage instructions" do
    get about_path
    assert_response :success
    assert_match /ユーザーの方/, response.body
    assert_match /アカウント登録/, response.body
    assert_match /予約枠確認/, response.body
  end

  test "about page should display fp usage instructions" do
    get about_path
    assert_response :success
    assert_match /FPの方/, response.body
    assert_match /予約枠設定/, response.body
    assert_match /予約管理/, response.body
  end
end
