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
end
