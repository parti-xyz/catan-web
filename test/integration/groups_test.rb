require 'test_helper'

class GruopsTest < ActionDispatch::IntegrationTest
  test '인디빠띠를 그룹빠띠로 바꿔요' do
    issue = issues(:issue1)

    issue.to_group(Group::GWANGJU)
    issue.save

    refute issue.errors.any?

    issue.reload

    assert_equal Group::GWANGJU.slug, issue.group_slug
    issue.watched_users.each do |watched_user|
      assert issue.member?(watched_user)
    end
  end
end
