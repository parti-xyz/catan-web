require 'test_helper'

class MembersTest < ActionDispatch::IntegrationTest
  test '빠띠 가입해요' do
    refute issues(:issue3).member?(users(:one))

    sign_in(users(:one))

    post issue_members_path(issue_id: issues(:issue3).id)

    assert assigns(:member).persisted?
    assert issues(:issue3).member?(users(:one))
    assert_equal issues(:issue3), assigns(:member).issue
    assert_equal users(:one), assigns(:member).user

    assert issues(:issue3).member?(users(:one))
  end

  test '그룹이 아닌 빠띠에 가입해요' do
    refute issues(:issue2).on_group?

    sign_in(users(:one))

    post issue_members_path(issue_id: issues(:issue2).id)

    assert issues(:issue2).member?(users(:one))
  end

  test '빠띠를 탈퇴해요' do
    assert issues(:issue1).member? users(:one)

    sign_in(users(:one))

    delete cancel_issue_members_path(issue_id: issues(:issue1).id)

    refute issues(:issue1).member? users(:one)
  end

  test '메이커는 탈퇴 못해요' do
    assert issues(:issue1).member? users(:maker)
    assert issues(:issue1).made_by? users(:maker)

    sign_in(users(:maker))

    delete cancel_issue_members_path(issue_id: issues(:issue1).id)

    assert issues(:issue1).member? users(:maker)
  end

  test '멤버인 빠띠 글만 구경해요' do
    sign_in(users(:three))

    assert_equal issues(:issue1).posts.count, Post.watched_by(users(:three)).count

    post issue_members_path(issue_id: issues(:issue1).id)
    assert_equal issues(:issue1).posts.count, Post.watched_by(users(:three)).count

    post issue_members_path(issue_id: issues(:issue2).id)
    assert_equal issues(:issue1).posts.count + issues(:issue2).posts.count, Post.watched_by(users(:one)).count
  end
end
