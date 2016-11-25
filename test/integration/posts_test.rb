require 'test_helper'

class PostsTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    refute issues(:issue2).on_group?
    assert issues(:issue2).member? users(:one)
    sign_in(users(:one))

    post posts_path, post: { body: 'body', issue_id: issues(:issue2).id, section_id: sections(:section1).id }

    assert assigns(:post).persisted?
    assigns(:post).reload
    assert_equal 'body', assigns(:post).body
    assert_equal users(:one), assigns(:post).user
    assert_equal issues(:issue2).body, assigns(:post).issue.body

    assert assigns(:post).comments.empty?
  end

  test '그룹에 속하지 않은 빠띠는 멤버가 아니면 못 만들어요' do
    refute issues(:issue2).on_group?
    refute issues(:issue2).member? users(:two)

    sign_in(users(:two))

    assert_raises CanCan::AccessDenied do
      post posts_path, post: { body: 'body', issue_id: issues(:issue2).id, section_id: sections(:section1).id }
    end
  end

  test '그룹의 빠띠에는 멤버라야 만들어요' do
    assert issues(:issue1).on_group?
    assert issues(:issue1).member? users(:one)

    sign_in(users(:one))

    post posts_path, post: { body: 'body', issue_id: issues(:issue1).id, section_id: sections(:section1).id }
    assert assigns(:post).persisted?
  end

  test '그룹의 빠띠에는 멤버가 아니면 못 만들어요' do
    assert issues(:issue1).on_group?
    refute issues(:issue1).member? users(:two)

    sign_in(users(:two))

    assert_raises CanCan::AccessDenied do
      post posts_path(post: { body: 'body', issue_id: issues(:issue1).id })
    end
  end

  test '고쳐요' do
    sign_in(users(:one))

    put post_path(posts(:post_talk1)), post: { body: 'body x', issue_id: issues(:issue2).id, section_id: sections(:section1).id }

    refute assigns(:post).errors.any?
    assigns(:post).reload
    assert_equal 'body x', assigns(:post).body
    assert_equal users(:one), assigns(:post).user
    assert_equal issues(:issue2).body, assigns(:post).issue.body
  end

  test '세상에 없었던 새로운 이슈를 넣으면 저장이 안되요' do
    sign_in(users(:one))

    previous_count = Post.count

    assert_raises CanCan::AccessDenied do
      post posts_path, post: { link: 'link', body: 'body', issue_id: -1, section_id: sections(:section1).id }
    end
    assert_equal previous_count, Post.count
  end

  test '내용 없이 만들수 있어요' do
    sign_in(users(:one))

    post posts_path, post: { issue_id: issues(:issue2).id, section_id: sections(:section2).id }

    assert assigns(:post).persisted?
  end
end
