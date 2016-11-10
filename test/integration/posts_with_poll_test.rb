require 'test_helper'

class PostsWithPollTest < ActionDispatch::IntegrationTest

  test '만들어요' do
    sign_in(users(:one))

    post posts_path(post: { section_id: sections(:section2).id, body: 'body', has_poll: 'true', issue_id: issues(:issue2).id,
      poll_attributes: { title: 'poll_title' } })

    assert assigns(:post).persisted?

    assert_equal 'poll_title', assigns(:post).poll.title
  end

  test '고쳐요' do
    sign_in(users(:one))

    put post_path(posts(:post_talk6), post: {  issue_id: issues(:issue2).id, poll_attributes: { title: 'poll_title x' } })

    assigns(:post).reload
    assert_equal 'poll_title x', assigns(:post).poll.title
    assert_equal users(:one), assigns(:post).user
    assert_equal issues(:issue2).title, assigns(:post).issue.title
  end
end
