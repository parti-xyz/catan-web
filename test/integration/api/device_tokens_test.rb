require 'test_helper'

class API::DeviceTokensTest < ActionDispatch::IntegrationTest
  include Rack::Test::Methods
  include Rack::Utils
  include GrapeRouteHelpers::NamedRouteMatcher

  test "토큰을 저장하고 지웁니다" do
    user = users(:facebook_user1)

    header 'Authorization', "Bearer #{oauth_tokens(:token1).token}"
    post api_v1_device_tokens_path, registration_id: 'test_id', application_id: 'xyz.parti.catan.test'

    assert_equal status_code(204), last_response.status

    user.reload
    assert user.device_tokens.exists?(registration_id: 'test_id', application_id: 'xyz.parti.catan.test')

    delete api_v1_device_tokens_path, registration_id: 'test_id'

    user.reload
    refute user.device_tokens.exists?(registration_id: 'test_id', application_id: 'xyz.parti.catan.test')
  end
end
