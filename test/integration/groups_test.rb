require 'test_helper'

class GroupsTest < ActionDispatch::IntegrationTest
  test '그룹을 열어요' do
    sign_in(users(:one))

    post group_configuration_path(group: { title: '테스트', slug: 'test', site_description: 'desc', site_title: 'title',
      head_title: '123', private: true, organizer_nicknames: "#{users(:one).nickname}, #{users(:two).nickname}" } )
    assert_equal assigns(:group).title, '테스트'
  end

  test '인디빠띠를 그룹빠띠로 바꿔요' do
    issue = issues(:issue1)

    issue.change_group(Group.find_by(slug: 'gwangju'))
    issue.save

    refute issue.errors.any?

    issue.reload

    assert_equal 'gwangju', issue.group_slug
    issue.member_users.each do |member_user|
      assert issue.member?(member_user)
    end
  end

  test '가입되지 않은 비공개그룹을 접속하면 홈으로 이동되어요' do
    host! "private.example.com"
    get group_members_path
    follow_redirect!
    assert_response :success
  end
end
