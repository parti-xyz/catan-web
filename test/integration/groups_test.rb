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

  test '빠띠를 추가해고 빼요' do
    sign_in(users(:admin))

    post add_parti_group_path(groups(:group1), issue_slug: issues(:issue1).slug)

    assert groups(:group1).reload.issues.exists?(issues(:issue1).id)

    delete remove_parti_group_path(groups(:group1), issue_id: issues(:issue1))

    refute groups(:group1).reload.issues.exists?(issues(:issue1).id)
  end
end
