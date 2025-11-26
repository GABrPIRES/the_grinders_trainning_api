require "test_helper"

class Api::V1::StudentDashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get api_v1_student_dashboard_show_url
    assert_response :success
  end
end
