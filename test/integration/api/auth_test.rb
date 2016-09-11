require 'test_helper'

class API::AuthTest < ActionDispatch::IntegrationTest
  include Rack::Test::Methods
  include Rack::Utils
  include GrapeRouteHelpers::NamedRouteMatcher

  setup do
    @access_token = facebook_user1['access_token']
    @uid = facebook_user1['id']
    assert @access_token.present?
    assert @uid.present?
  end

  test "가입하지 않은 사용자의 페이스북 액세스토큰을 보내면 먼저 가입하라고 응답이 옵니다" do
    refute User.exists? uid: @uid, provider: 'facebook'

    post api_v1_auth_facebook_path, { access_token: @access_token }
    assert_equal status_code(:precondition_failed), last_response.status
  end

  test "잘못된 페이스북 액세스토큰을 보내면 오류 응답코드를 보냅니다" do
    post api_v1_auth_facebook_path, { access_token: "invalid_token" }
    assert_equal status_code(:not_acceptable), last_response.status
  end

  test "이미 가입되어 있는 사용자의 페이스북 액세스토큰을 보내면 새로운 인증토큰을 돌려 줍니다" do
    user = users(:facebook_user1)
    user.update_columns(uid: @uid, authentication_token: 'old')

    post api_v1_auth_facebook_path, { access_token: @access_token }

    assert_equal status_code(:created), last_response.status
    user.reload
    refute_equal 'old', user.authentication_token
    body = JSON.parse(last_response.body)
    assert_equal user.authentication_token, body.dig("data", "auth_token")
  end
end
