require 'test_helper'

class MemberRequestsTest < ActionDispatch::IntegrationTest
  test '가입이 받아들여져요' do
    refute issues(:private_issue).member?(users(:one))
    assert issues(:private_issue).member_requested?(users(:one))

    sign_in(users(:admin))
    post accept_issue_member_requests_path(issue_id: issues(:private_issue).id), { user_id: users(:one).id  }

    users(:one).reload

    assert issues(:private_issue).member?(users(:one))
    refute issues(:private_issue).member_requested?(users(:one))
    assert_equal users(:one).messages.last.messagable.id, assigns(:member_request).id
  end

  test '가입이 거절되어요' do
    refute issues(:private_issue).member?(users(:one))
    assert issues(:private_issue).member_requested?(users(:one))

    sign_in(users(:admin))
    delete reject_issue_member_requests_path(issue_id: issues(:private_issue).id), { user_id: users(:one).id  }

    users(:one).reload

    refute issues(:private_issue).member?(users(:one))
    refute issues(:private_issue).member_requested?(users(:one))
    assert_equal users(:one).messages.last.messagable.id, assigns(:member_request).id
  end

  test '휴면 중이면 멤버 요청이 거부되어요' do
    refute issues(:frozen_private_parti).member?(users(:one))
    refute issues(:frozen_private_parti).member_requested?(users(:one))

    sign_in(users(:one))
    post issue_member_requests_path(issue_id: issues(:frozen_private_parti).id)

    users(:one).reload

    refute issues(:frozen_private_parti).member?(users(:one))
    refute issues(:frozen_private_parti).member_requested?(users(:one))
  end
end
