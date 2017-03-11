require 'test_helper'

class GruopsTest < ActionDispatch::IntegrationTest
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
