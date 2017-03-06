require 'test_helper'

class MentionableTest < ActionDispatch::IntegrationTest
  test '멘션을 해요' do
    sign_in(users(:one))

    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: posts(:post_talk1).id, comment: { body: '@nick2 mention' })
    end

    assert assigns(:comment).persisted?
    assert_equal users(:two), assigns(:comment).reload.mentions.first.user
  end

  test '멘션을 하면 메시지가 보내져요' do
    sign_in(users(:one))

    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: posts(:post_talk1).id, comment: { body: '@nick2 mention' })
    end

    message = users(:two).reload.messages.first
    assert_equal assigns(:comment), message.messagable
  end
end
