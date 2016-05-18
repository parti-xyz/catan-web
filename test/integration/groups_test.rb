require 'test_helper'

class GroupsTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    sign_in(users(:admin))

    post groups_path(group: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:group).persisted?
    assert_equal 'title', assigns(:group).title
  end

  test '같은 이름으로는 못 만들어요' do
    sign_in(users(:admin))

    post groups_path(group: { title: 'title', slug: 'title', body: 'body' })
    assert assigns(:group).persisted?
    post groups_path(group: { title: 'title', slug: 'title', body: 'body' })
    refute assigns(:group).persisted?
  end

  test '대소문자를 안가려요' do
    sign_in(users(:admin))

    post groups_path(group: { title: 'Title', slug: 'Title', body: 'body' })
    assert assigns(:group).persisted?
    post groups_path(group: { title: 'title', slug: 'title', body: 'body' })
    refute assigns(:group).persisted?
  end

  test '고쳐요' do
    sign_in(users(:admin))

    put group_path(groups(:group1), group: { title: 'title x', body: 'body x' })

    assigns(:group).reload
    assert_equal 'title x', assigns(:group).title
  end

  test 'all이라는 그룹은 못만들어요' do
    sign_in(users(:admin))

    post groups_path(group: { title: 'all', slug: 'all', body: 'body' })

    refute assigns(:group).persisted?
  end

  test '그룹용 빠띠 만들기' do
    sign_in(users(:admin))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body', group_id: groups(:group1).id })

    assert assigns(:issue).persisted?
    assert_equal 'title', assigns(:issue).title
    assert_equal assigns(:issue), groups(:group1).reload.issues.first
  end
end
