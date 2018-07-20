require 'test_helper'

class UpvoteTest < ActionDispatch::IntegrationTest
  test '댓글을 업보트해요' do
    assert_equal 1, Upvote.by_issue(issues(:issue1)).count
    refute comments(:comment1).upvoted_by?(users(:one))
    sign_in(users(:one))
    post comment_upvotes_path(comment_id: comments(:comment1).id, format: :js)

    assert assigns(:upvote).persisted?
    assert_equal users(:one), assigns(:upvote).user
    assert comments(:comment1).upvoted_by? users(:one)
    assert_equal 2, Upvote.by_issue(issues(:issue1)).count
  end

  test '업보트를 취소해요' do
    assert comments(:comment1).upvoted_by?(users(:two))
    sign_in(users(:two))

    delete cancel_comment_upvotes_path(comment_id: comments(:comment1).id, format: :js)

    refute comments(:comment1).reload.upvoted_by?(users(:two))
  end

  test '댓글을 업보트하면 메시지가 보내져요' do
    refute comments(:comment1).upvoted_by?(users(:one))
    sign_in(users(:one))

    post comment_upvotes_path(comment_id: comments(:comment1).id, format: :js)

    message = comments(:comment1).user.reload.messages.first
    assert_equal assigns(:upvote), message.messagable
  end
end
