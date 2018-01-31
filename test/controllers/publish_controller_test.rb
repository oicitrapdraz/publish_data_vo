require 'test_helper'

class PublishControllerTest < ActionDispatch::IntegrationTest
  test "should get metadata" do
    get publish_metadata_url
    assert_response :success
  end

  test "should get parse_match" do
    get publish_parse_match_url
    assert_response :success
  end

  test "should get first_check" do
    get publish_first_check_url
    assert_response :success
  end

  test "should get rd" do
    get publish_rd_url
    assert_response :success
  end

  test "should get final_check" do
    get publish_final_check_url
    assert_response :success
  end

end
