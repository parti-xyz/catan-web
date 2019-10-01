require 'test_helper'

class PostsTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    assert issues(:issue2).member? users(:one)
    sign_in(users(:one))

    post posts_path, params: { post: { body: 'body', issue_id: issues(:issue2).id } }

    assert assigns(:post).persisted?
    assigns(:post).reload
    assert_equal '<p>body</p>', assigns(:post).body
    assert_equal users(:one), assigns(:post).user
    assert_equal issues(:issue2), assigns(:post).issue

    assert assigns(:post).comments.empty?

    assert_equal users(:one), assigns(:post).last_stroked_user
  end

  test '게시물 본문 맨 끝문장에 태그가 없을 때도 잘 만들어요' do
    sign_in(users(:one))

    post posts_path, params: { post: { body: '<p>body</p>ok', issue_id: issues(:issue2).id } }

    assert assigns(:post).persisted?
    assert_equal '<p>body</p>ok', assigns(:post).body
  end

  test '그룹에 속하지 않은 빠띠는 멤버가 아니면 못 만들어요' do
    refute issues(:issue2).member? users(:two)

    sign_in(users(:two))

    assert_raises CanCan::AccessDenied do
      post posts_path, params: { post: { body: 'body', issue_id: issues(:issue2).id } }
    end
  end

  test '그룹의 빠띠에는 멤버라야 만들어요' do
    assert issues(:issue1).member? users(:one)

    sign_in(users(:one))

    post posts_path, params: { post: { body: 'body', issue_id: issues(:issue1).id } }
    assert assigns(:post).persisted?
  end

  test '그룹의 빠띠에는 멤버가 아니면 못 만들어요' do
    refute issues(:issue1).member? users(:two)

    sign_in(users(:two))

    assert_raises CanCan::AccessDenied do
      post posts_path(post: { body: 'body', issue_id: issues(:issue1).id })
    end
  end

  test '공지전용 빠띠는 오거나이저는 잘 만들어요' do
    assert issues(:notice).organized_by? users(:organizer)

    sign_in(users(:organizer))

    post posts_path(post: { body: 'body', issue_id: issues(:notice).id })
    assert assigns(:post).persisted?
  end

  test '공지전용 빠띠는 오거나이저가 아닌 회원은 못 만들어요' do
    refute issues(:notice).organized_by? users(:one)

    sign_in(users(:one))

    assert_raises CanCan::AccessDenied do
      post posts_path(post: { body: 'body', issue_id: issues(:notice).id })
    end
  end

  test '고쳐요' do
    sign_in(users(:one))
    put post_path(posts(:post_talk1)), params: { post: { body: 'body x', issue_id: issues(:issue2).id } }

    refute assigns(:post).errors.any?
    assigns(:post).reload
    assert assigns(:post).body.include?  '<p>body x</p>'
    assert_equal users(:one), assigns(:post).user
    assert_equal issues(:issue2), assigns(:post).issue
  end

  test '내용 없이 만들수 있어요' do
    sign_in(users(:one))

    post posts_path, params: { post: { issue_id: issues(:issue2).id } }

    assert assigns(:post).persisted?
  end
end
