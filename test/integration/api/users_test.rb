require 'test_helper'

class API::UsersTest < ActionDispatch::IntegrationTest
  include Rack::Test::Methods
  include Rack::Utils
  include GrapeRouteHelpers::NamedRouteMatcher

  test "내 정보를 가져 옵니다" do
    user = users(:facebook_user1)

    header 'Authorization', "Bearer #{oauth_tokens(:token1).token}"
    get api_v1_users_me_path

    assert_equal status_code(:ok), last_response.status

    body = JSON.parse(last_response.body)
    assert_equal user.id, body.dig("user", "id")
    assert_equal user.email, body.dig("user", "email")
  end
end
