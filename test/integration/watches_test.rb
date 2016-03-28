require 'test_helper'

class WatchesTest < ActionDispatch::IntegrationTest

  test '만들어요' do
    sign_in(users(:one))

    post issue_watches_path(issue_id: issues(:issue3).id)

    assert assigns(:watch).persisted?
    assert_equal issues(:issue3), assigns(:watch).issue
    assert_equal users(:one), assigns(:watch).user
  end

  test '취소해요' do
    assert issues(:issue1).watched_by? users(:two)

    sign_in(users(:two))

    delete cancel_issue_watches_path(issue_id: issues(:issue1).id)

    refute issues(:issue1).watched_by? users(:two)
  end

  test '구독한 글만 구경해요' do
    sign_in(users(:one))

    assert_equal issues(:issue1).posts.count, Post.watched_by(users(:one)).count

    post issue_watches_path(issue_id: issues(:issue1).id)
    assert_equal issues(:issue1).posts.count, Post.watched_by(users(:one)).count

    post issue_watches_path(issue_id: issues(:issue2).id)
    assert_equal issues(:issue1).posts.count + issues(:issue2).posts.count, Post.watched_by(users(:one)).count
  end
end
