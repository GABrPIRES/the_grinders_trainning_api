require "test_helper"

class Api::V1::CoachDashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get api_v1_coach_dashboard_show_url
    assert_response :success
  end
end
