require 'test_helper'

class CommentsTest < ActionDispatch::IntegrationTest
  test '댓글을 만들어요' do
    sign_in(users(:one))

    post post_comments_path(post_id: posts(:post_talk1).id, comment: { body: 'body' }, format: :js)

    assert assigns(:comment).persisted?
    assert_equal 'body', assigns(:comment).body
    assert_equal users(:one), assigns(:comment).user
  end

  test '댓글 아래 댓글을 답니다' do
    sign_in(users(:one))

    # /post/30/comments
    # comment[body]
    # comment[parent_id] : 부모 댓글 번호
    post post_comments_path(post_id: posts(:post_talk1).id, comment: { body: 'body x', parent_id: comments(:comment1).id }, format: :js)

    refute assigns(:comment).errors.any?
    assert_equal 'body x', assigns(:comment).body
    assert_equal comments(:comment1).id, assigns(:comment).parent.id

    comments(:comment1).reload
    assert comments(:comment1).children.include? (assigns(:comment))

    posts(:post_talk1).reload
    assert posts(:post_talk1).comments.only_parent.include? (comments(:comment1))
    refute posts(:post_talk1).comments.only_parent.include? (assigns(:comment))
  end

  test '내용을 수정해요' do
    sign_in(users(:one))

    put comment_path(comments(:comment1), comment: { body: 'body x' }, format: :js)

    refute assigns(:comment).errors.any?
    assert_equal 'body x', assigns(:comment).body
  end

  test '댓글을 달면 메시지가 보내져요' do
    comment = comments(:comment1)
    assert User.where(id: comment.post.comments.select(:user_id)).include?(users(:one))

    sign_in(users(:two))
    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: comment.post.id, comment: { body: 'body' }, format: :js)
    end

    refute assigns(:comment).errors.any?
    assert_equal assigns(:comment), users(:one).messages.first.messagable
  end

  test '찬성하는 주장에 만들어요' do
    assert posts(:post_talk4).poll.agree_by? users(:two)

    sign_in(users(:two))
    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: posts(:post_talk4).id, comment: { body: 'body' }, format: :js)
    end

    assert assigns(:comment).persisted?
    assert_equal 'agree', assigns(:comment).choice
  end

  test '찬반투표한 경우 댓글을 달면 메시지가 보내져요' do
    sign_in(users(:two))
    post issue_members_path(issue_id: posts(:post_talk4).issue.id)
    assert posts(:post_talk4).issue.member?(users(:two))
    assert posts(:post_talk4).poll.agree_by? users(:two)

    sign_in(users(:one))
    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: posts(:post_talk4).id, comment: { body: 'body' }, format: :js)
    end
    refute assigns(:comment).errors.any?
    assert_equal assigns(:comment), users(:two).messages.first.messagable
  end

  test '찬반투표한 경우라도 블랙리스트 사용자가 댓글을 달면 메시지가 안 보내져요' do
    assert posts(:post_talk4).poll.agree_by? users(:two)

    sign_in(users(:bad))
    post post_comments_path(post_id: posts(:post_talk4).id, comment: { body: 'body' }, format: :js)

    refute assigns(:comment).errors.any?
    refute users(:two).messages.any?
  end

  test '투표 안한 주장에 만들어요' do
    refute posts(:post_talk4).poll.voting_by? users(:three)

    sign_in(users(:three))

    post post_comments_path(post_id: posts(:post_talk4).id, comment: { body: 'body' }, format: :js)

    assert assigns(:comment).persisted?
    assert_nil assigns(:comment).choice
  end

  test '고쳐요' do
    sign_in(users(:one))

    put comment_path(comments(:comment1), comment: { body: 'body x' }, format: :js)

    assigns(:comment).reload
    assert_equal 'body x', assigns(:comment).body
  end
end
