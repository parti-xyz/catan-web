require 'test_helper'

class GroupMemberRequestsTest < ActionDispatch::IntegrationTest
  test '가입이 받아들여져요' do
    refute groups(:private_group).member?(users(:member_request_to_private_group))

    sign_in(users(:admin))

    host! "private.example.com"
    post accept_group_member_requests_path(group_id: groups(:private_group).id), { user_id: users(:member_request_to_private_group).id  }

    users(:member_request_to_private_group).reload

    assert groups(:private_group).member?(users(:member_request_to_private_group))
    assert issues(:default_of_private_group).member?(users(:member_request_to_private_group))
    refute groups(:private_group).member_requested?(users(:member_request_to_private_group))
    assert_equal users(:member_request_to_private_group).messages.last.messagable.id, assigns(:member_request).id
  end
end
