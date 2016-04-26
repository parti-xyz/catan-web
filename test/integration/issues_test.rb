require 'test_helper'

class IssuesTest < ActionDispatch::IntegrationTest
  test '로그인 안해도 첫페이지가 잘보여요' do
    get root_path
    assert_response :success
  end

  test '만들어요' do
    sign_in(users(:admin))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:issue).persisted?
    assert_equal 'title', assigns(:issue).title
  end

  test '같은 이름으로는 못 만들어요' do
    sign_in(users(:admin))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })
    assert assigns(:issue).persisted?
    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })
    refute assigns(:issue).persisted?
  end

  test '대소문자를 안가려요' do
    sign_in(users(:admin))

    post issues_path(issue: { title: 'Title', slug: 'Title', body: 'body' })
    assert assigns(:issue).persisted?
    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })
    refute assigns(:issue).persisted?
  end

  test '고쳐요' do
    sign_in(users(:admin))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x' })

    assigns(:issue).reload
    assert_equal 'title x', assigns(:issue).title
  end

  test 'all이라는 이슈는 못만들어요' do
    sign_in(users(:admin))

    post issues_path(issue: { title: 'all', slug: 'all', body: 'body' })

    refute assigns(:issue).persisted?
  end
end
