require 'test_helper'

class ReadersTest < ActionDispatch::IntegrationTest
  test '공지를 읽어요' do
    refute posts(:post_talk1).read_by?(users(:one))

    sign_in(users(:one))
    get post_path(posts(:post_talk1))
    assert posts(:post_talk1).read_by?(users(:one))

    get post_path(posts(:post_talk1))
    assert posts(:post_talk1).read_by?(users(:one))
  end
end
