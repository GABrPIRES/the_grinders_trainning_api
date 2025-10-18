require "test_helper"

class Api::V1::ImportsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get api_v1_imports_create_url
    assert_response :success
  end
end
