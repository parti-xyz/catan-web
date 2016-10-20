require 'test_helper'

class BlindUserTest < ActionDispatch::IntegrationTest
  test '사이트 와이드 블라인드 된 유저는 모든 빠띠에서 블라인드 됩니다.' do
    sign_in(users(:admin))

    post admin_blinds_path, { blind: { nickname: users(:one).nickname } }

    assert Blind.site_wide?(users(:one))
  end

end
