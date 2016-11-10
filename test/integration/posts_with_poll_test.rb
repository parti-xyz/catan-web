require 'test_helper'

class PostsWithPollTest < ActionDispatch::IntegrationTest

  test '만들어요' do
    sign_in(users(:one))

    post talks_path(talk: { section_id: sections(:section2).id, body: 'body', has_poll: 'true', issue_id: issues(:issue2).id,
      poll_attributes: { title: 'poll_title' } })

    assert assigns(:talk).persisted?

    assert_equal 'poll_title', assigns(:talk).poll.title
  end

  test '고쳐요' do
    sign_in(users(:one))

    put talk_path(talks(:talk6), talk: {  issue_id: issues(:issue2).id, poll_attributes: { title: 'poll_title x' } })

    assigns(:talk).reload
    assert_equal 'poll_title x', assigns(:talk).poll.title
    assert_equal users(:one), assigns(:talk).user
    assert_equal issues(:issue2).title, assigns(:talk).issue.title
  end
end
