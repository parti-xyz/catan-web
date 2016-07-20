require 'test_helper'

class UsersTest < ActionDispatch::IntegrationTest
  test '사용자 정보 수정창이 잘 나옵니다.' do
    sign_in(users(:one))

    get edit_user_registration_path

    assert_response :success
  end
end
