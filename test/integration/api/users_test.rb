require 'test_helper'

class API::UsersTest < ActionDispatch::IntegrationTest
  include Rack::Test::Methods
  include Rack::Utils
  include GrapeRouteHelpers::NamedRouteMatcher

  setup do
    @access_token = facebook_user1['access_token']
    @uid = facebook_user1['id']
    assert @access_token.present?
    assert @uid.present?
  end

  test "신규 사용자의 닉네임과 페이스북 액세스토큰을 주면 새로운 사용자를 저장하고 액세스토큰을 줍니다" do
    refute User.exists? uid: @uid, provider: 'facebook'

    post api_v1_users_facebook_path, { user: { nickname: 'fb_new' },  access_token: @access_token }

    assert_equal status_code(:created), last_response.status
    body = JSON.parse(last_response.body)
    user = User.find_by nickname: 'fb_new'
    assert_equal user.id, body.dig("user", "id")
  end

  test "신규 사용자의 닉네임과 페이스북 액세스토큰이 넘어 왔는데, 닉네임이 중복이면 오류 응답코드를 보냅니다" do
    refute User.exists? uid: @uid, provider: 'facebook'

    post api_v1_users_facebook_path, { user: { nickname: users(:one).nickname },  access_token: @access_token }

    assert_equal status_code(:unprocessable_entity), last_response.status
  end

  test "이미 있는 사용자의 닉네임과 페이스북 액세스토큰을 주면 새로운 액세스토큰만 줍니다" do
    user = users(:facebook_user1)
    user.update_columns(uid: @uid, authentication_token: 'old')

    post api_v1_users_facebook_path, { user: { nickname: 'fb_new' },  access_token: @access_token }

    assert_equal status_code(:ok), last_response.status
    user.reload
    refute_equal 'old', user.authentication_token
    body = JSON.parse(last_response.body)
    assert_equal user.id, body.dig("user", "id")
    assert_equal user.authentication_token, body.dig("user", "auth_token")
  end

  test "잘못된 페이스북 액세스토큰을 보내면 오류 응답코드를 보냅니다" do
    post api_v1_users_facebook_path, { user: { nickname: 'fb_new' },  access_token: 'invalid_token' }
    assert_equal status_code(:not_acceptable), last_response.status
  end
end
