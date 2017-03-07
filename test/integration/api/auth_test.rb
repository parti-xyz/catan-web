require 'test_helper'

class API::AuthTest < ActionDispatch::IntegrationTest
  # include Rack::Test::Methods
  # include Rack::Utils
  # include GrapeRouteHelpers::NamedRouteMatcher

  setup do
    @access_token ||= facebook_user1['access_token']
    @uid ||= facebook_user1['id']
    assert @access_token.present?
    assert @uid.present?
  end

  test "가입하지 않은 사용자가 페이스북 액세스토큰만 보내고 닉네임을 주지 않으면 먼저 가입하라고 응답이 옵니다" do
    refute User.exists? uid: @uid, provider: 'facebook'

    application1 = oauth_applications(:application1)
    xhr :post, oauth_token_path, {grant_type: :assertion,
      client_id: application1.uid, client_secret: application1.secret,
      provider: :facebook, assertion: @access_token}

    assert_response :unauthorized

    body = JSON.parse(response.body)
    assert_equal 'need_nickname', body['error']
  end

  test "신규 사용자의 닉네임과 페이스북 액세스토큰을 주면 새로운 사용자를 저장하고 액세스토큰을 줍니다" do
    refute User.exists? uid: @uid, provider: 'facebook'

    application1 = oauth_applications(:application1)
    xhr :post, oauth_token_path, {grant_type: :assertion,
      client_id: application1.uid, client_secret: application1.secret,
      provider: :facebook, assertion: @access_token, user: { nickname: 'fb_new' }}

    assert_response :ok

    body = JSON.parse(response.body)
    user = User.find_by nickname: 'fb_new'
    access_token = Doorkeeper::AccessToken.find_by token: body.dig("access_token")
    assert_equal user.id, access_token.resource_owner_id
  end

  test "신규 사용자의 닉네임이 중복이면 오류가 발생합니다" do
    refute User.exists? uid: @uid, provider: 'facebook'

    application1 = oauth_applications(:application1)
    xhr :post, oauth_token_path, {grant_type: :assertion,
      client_id: application1.uid, client_secret: application1.secret,
      provider: :facebook, assertion: @access_token, user: { nickname: users(:one).nickname }}

    assert_response :unauthorized

    body = JSON.parse(response.body)
    assert_equal 'duplicate_nickname', body['error']
  end

  test "잘못된 페이스북 액세스토큰을 보내면 오류 응답코드를 보냅니다" do

    application1 = oauth_applications(:application1)
    xhr :post, oauth_token_path, {grant_type: :assertion,
      client_id: application1.uid, client_secret: application1.secret,
      provider: :facebook, assertion: 'invalid', user: { nickname: 'fb_new' }}

    assert_response :unauthorized

    body = JSON.parse(response.body)
    assert_equal 'fail_external_auth', body['error']
  end

  test "이미 가입되어 있는 사용자의 페이스북 액세스토큰을 보내면 새로운 인증토큰을 돌려 줍니다" do
    user = users(:facebook_user1)
    user.update_columns(uid: @uid)
    origin_nickname = user.nickname

    application1 = oauth_applications(:application1)
    xhr :post, oauth_token_path, {grant_type: :assertion,
      client_id: application1.uid, client_secret: application1.secret,
      provider: :facebook, assertion: @access_token, user: { nickname: 'fb_new' }}

    assert_response :ok

    body = JSON.parse(response.body)
    user.reload
    assert_equal origin_nickname, user.nickname
    access_token = Doorkeeper::AccessToken.find_by token: body.dig("access_token")
    assert_equal user.id, access_token.resource_owner_id
  end

  test "오래된 토큰을 재발급 받습니다" do
    user = users(:facebook_user1)
    user.update_columns(uid: @uid)

    application1 = oauth_applications(:application1)
    xhr :post, '/oauth/token', {grant_type: :assertion,
      client_id: application1.uid, client_secret: application1.secret,
      provider: :facebook, assertion: @access_token, user: { nickname: 'fb_new' }}

    assert_response :ok

    body = JSON.parse(response.body)
    access_token = body.dig("access_token")
    refresh_token = body.dig("refresh_token")

    xhr :get, '/oauth/token/info', {}, {Authorization: "Bearer #{access_token}"}
    assert_response :ok

    Timecop.freeze(1.month.from_now) do
      xhr :get, '/oauth/token/info', {}, {Authorization: "Bearer #{access_token}"}
      assert_response :unauthorized

      xhr :post, '/oauth/token', {grant_type: :refresh_token,
      client_id: application1.uid, client_secret: application1.secret,
      refresh_token: refresh_token}

      assert_response :ok

      body = JSON.parse(response.body)
      access_token = body.dig("access_token")
      refresh_token = body.dig("refresh_token")

      user.reload
      access_token = Doorkeeper::AccessToken.find_by token: access_token
      assert_equal user.id, access_token.resource_owner_id
    end
  end
end
