require 'test_helper'

class TalksTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    sign_in(users(:one))

    post talks_path, talk: { title: 'title', body: 'body', issue_id: issues(:issue2).id, section_id: sections(:section1).id }

    assert assigns(:talk).persisted?
    assigns(:talk).reload
    assert_equal 'title', assigns(:talk).title
    assert_equal 'body', assigns(:talk).body
    assert_equal users(:one), assigns(:talk).user
    assert_equal issues(:issue2).title, assigns(:talk).issue.title

    assert assigns(:talk).comments.empty?
  end

  test '올빠띠의 개별빠띠에는 멤버가 아니라도 만들어요' do
    refute issues(:issue2).on_group?
    refute issues(:issue2).member? users(:two)

    sign_in(users(:two))

    post talks_path, talk: { title: 'title', body: 'body', issue_id: issues(:issue2).id, section_id: sections(:section1).id }
    assert assigns(:talk).persisted?
  end

  test '그룹빠띠의 빠띠에는 멤버라야 만들어요' do
    assert issues(:issue1).on_group?
    assert issues(:issue1).member? users(:one)

    sign_in(users(:one))

    post talks_path, talk: { title: 'title', body: 'body', issue_id: issues(:issue1).id, section_id: sections(:section1).id }
    assert assigns(:talk).persisted?
  end

  test '그룹빠띠의 빠띠에는 멤버가 아니면 못 만들어요' do
    assert issues(:issue1).on_group?
    refute issues(:issue1).member? users(:two)

    sign_in(users(:two))

    assert_raises CanCan::AccessDenied do
      post talks_path(talk: { title: 'title', body: 'body', issue_id: issues(:issue1).id })
    end
  end

  test '고쳐요' do
    sign_in(users(:one))

    put talk_path(talks(:talk1)), talk: { title: 'title x', body: 'body x', issue_id: issues(:issue2).id, section_id: sections(:section1).id }

    refute assigns(:talk).errors.any?
    assigns(:talk).reload
    assert_equal 'title x', assigns(:talk).title
    assert_equal 'body x', assigns(:talk).body
    assert_equal users(:one), assigns(:talk).user
    assert_equal issues(:issue2).title, assigns(:talk).issue.title
  end

  test '세상에 없었던 새로운 이슈를 넣으면 저장이 안되요' do
    sign_in(users(:one))

    previous_count = Talk.count

    assert_raises CanCan::AccessDenied do
      post talks_path, talk: { link: 'link', body: 'body', issue_id: -1, section_id: sections(:section1).id }
    end
    assert_equal previous_count, Talk.count
  end

  test '내용 없이 만들수 있어요' do
    sign_in(users(:one))

    post talks_path, talk: { title: 'title', issue_id: issues(:issue2).id, section_id: sections(:section2).id }

    assert assigns(:talk).persisted?
  end
end
