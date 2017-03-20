require 'test_helper'

class GroupMembersAdmitTest < ActionDispatch::IntegrationTest
  test '초대해요' do
    sign_in(users(:admin))

    host! "private.example.com"
    post admit_group_members_path, { recipients: "#{users(:one).email} #{users(:two).nickname} not_exists@email.com" , message: 'ok' }

    refute groups(:private_group).invited?(users(:one))
    refute groups(:private_group).invited?(users(:two))
    assert groups(:private_group).member?(users(:one))
    assert groups(:private_group).member?(users(:two))
    assert groups(:private_group).invited?("not_exists@email.com")
  end

  test '두번 초대는 안해요' do
    sign_in(users(:admin))

    host! "private.example.com"
    post admit_group_members_path, { recipients: "not_exists@email.com" , message: 'ok' }

    post admit_group_members_path, { recipients: "not_exists@email.com" , message: 'ok2' }

    assert_equal 1, groups(:private_group).invitations.count
  end

  test '가입된 사용자는 초대안해요' do
    sign_in(users(:admin))

    host! "private.example.com"
    post admit_group_members_path, { recipients: "#{users(:three).email}" , message: 'ok' }

    refute groups(:private_group).invited?(users(:three))
  end

  test '가입요청한 사용자는 초대하면 가입되어요' do
    assert groups(:private_group).member_requested?(users(:member_request_to_private_group))

    sign_in(users(:admin))

    host! "private.example.com"
    post admit_group_members_path, { recipients: "#{users(:member_request_to_private_group).email}" , message: 'ok' }

    assert groups(:private_group).member?(users(:member_request_to_private_group))
  end

  test '동일한 이메일의 사용자가 있으면 초대가 안되어요' do
    sign_in(users(:admin))
    host! "private.example.com"
    post admit_group_members_path, { recipients: "ambiguous@test.com" , message: 'ok' }
    assert groups(:private_group).invitations.empty?
  end

  test '닉네임에 해당되는 사용자가 없으면 초대가 안되어요' do
    sign_in(users(:admin))
    host! "private.example.com"
    post admit_group_members_path, { recipients: "not_found_nickname" , message: 'ok' }
    assert groups(:private_group).invitations.empty?
  end
end
