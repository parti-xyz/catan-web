require 'test_helper'

class CommentsTest < ActionDispatch::IntegrationTest
  test '멘션을 해요' do
    sign_in(users(:one))

    post post_comments_path(post_id: articles(:article1).acting_as.id, comment: { body: '@nick2 mention' })

    assert assigns(:comment).persisted?
    assert_equal users(:two), assigns(:comment).mentions.first.user
  end

  test '멘션을 하면 메시지가 보내져요' do
    sign_in(users(:one))

    post post_comments_path(post_id: articles(:article1).acting_as.id, comment: { body: '@nick2 mention' })

    message = users(:two).reload.messages.first
    assert_equal assigns(:comment), message.messagable
  end

  test 'parti 멘션을 하면 슬랙이 와요' do
    sign_in(users(:one))

    ENV['SLACK_WEBHOOK_URL'] = 'test'
    Slack::Notifier.any_instance.expects(:ping).once
    post post_comments_path(post_id: articles(:article1).acting_as.id, comment: { body: '@parti @nick2 mention' })
  end
end
