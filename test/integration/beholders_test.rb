require 'test_helper'

class BeholdersTest < ActionDispatch::IntegrationTest
  test '공지를 읽어요' do
    assert posts(:post_talk1).issue.member?(users(:one))
    refute posts(:post_talk1).behold_by?(users(:one))

    sign_in(users(:one))
    get post_path(posts(:post_talk1))
    follow_redirect!
    refute posts(:post_talk1).behold_by?(users(:one))
    put behold_post_path(posts(:post_talk1), format: :js)
    assert posts(:post_talk1).behold_by?(users(:one))

    get post_path(posts(:post_talk1))
    assert posts(:post_talk1).behold_by?(users(:one))
  end

  test '멤버가 아니면 공지를 읽은 표시가 안나요' do
    refute posts(:post_talk1).issue.member?(users(:two))
    refute posts(:post_talk1).behold_by?(users(:two))

    sign_in(users(:two))
    get post_path(posts(:post_talk1))
    follow_redirect!
    refute posts(:post_talk1).behold_by?(users(:two))
  end
end
