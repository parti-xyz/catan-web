require 'test_helper'

class CommentsTest < ActionDispatch::IntegrationTest
  test '글에 만들어요' do
    sign_in(users(:one))

    post post_comments_path(post_id: posts(:post_talk1).id, comment: { body: 'body' }), format: :js

    assert assigns(:comment).persisted?
    assert_equal 'body', assigns(:comment).body
    assert_equal users(:one), assigns(:comment).user
  end

  test '내용을 수정해요' do
    sign_in(users(:one))

    put comment_path(comments(:comment1), comment: { body: 'body x' }), format: :js

    refute assigns(:comment).errors.any?
    assert_equal 'body x', assigns(:comment).body
  end

  test '댓글을 달면 메시지가 보내져요' do
    comment = comments(:comment1)
    assert comment.post.comments.users.include?(users(:one))

    sign_in(users(:two))
    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: comment.post.id, comment: { body: 'body' }), format: :js
    end

    refute assigns(:comment).errors.any?
    assert_equal assigns(:comment), users(:one).messages.first.messagable
  end

  test '찬성하는 주장에 만들어요' do
    assert posts(:post_talk4).poll.agreed_by? users(:two)

    sign_in(users(:two))
    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: posts(:post_talk4).id, comment: { body: 'body' }), format: :js
    end

    assert assigns(:comment).persisted?
    assert_equal 'agree', assigns(:comment).choice
  end

  test '찬반투표한 경우 댓글을 달면 메시지가 보내져요' do
    assert posts(:post_talk4).poll.agreed_by? users(:two)

    sign_in(users(:one))
    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: posts(:post_talk4).id, comment: { body: 'body' }), format: :js
    end
    refute assigns(:comment).errors.any?
    assert_equal assigns(:comment), users(:two).messages.first.messagable
  end

  test '찬반투표한 경우라도 블랙리스트 사용자가 댓글을 달면 메시지가 안 보내져요' do
    assert posts(:post_talk4).poll.agreed_by? users(:two)

    sign_in(users(:bad))
    post post_comments_path(post_id: posts(:post_talk4).id, comment: { body: 'body' }), format: :js

    refute assigns(:comment).errors.any?
    refute users(:two).messages.any?
  end

  test '투표 안한 주장에 만들어요' do
    refute posts(:post_talk4).poll.voting_by? users(:three)

    sign_in(users(:three))

    post post_comments_path(post_id: posts(:post_talk4).id, comment: { body: 'body' }), format: :js

    assert assigns(:comment).persisted?
    assert_nil assigns(:comment).choice
  end

  test '고쳐요' do
    sign_in(users(:one))

    put comment_path(comments(:comment1), comment: { body: 'body x' }), format: :js

    assigns(:comment).reload
    assert_equal 'body x', assigns(:comment).body
  end
end
