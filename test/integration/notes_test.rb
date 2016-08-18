require 'test_helper'

class NotesTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    sign_in(users(:one))

    post notes_path(note: { body: 'body', issue_id: issues(:issue2).id })

    assert assigns(:note).persisted?
    assigns(:note).reload
    assert_equal 'body', assigns(:note).body
    assert_equal users(:one), assigns(:note).user

    assert assigns(:note).comments.empty?
  end

  test '올빠띠의 개별빠띠에는 멤버가 아니라도 만들어요' do
    refute issues(:issue2).in_group?
    refute issues(:issue2).member? users(:two)

    sign_in(users(:two))

    post notes_path(note: { body: 'body', issue_id: issues(:issue2).id })
    assert assigns(:note).persisted?
  end

  test '그룹빠띠의 빠띠에는 멤버라야 만들어요' do
    assert issues(:issue1).in_group?
    assert issues(:issue1).member? users(:one)

    sign_in(users(:one))

    post notes_path(note: { body: 'body', issue_id: issues(:issue1).id })
    assert assigns(:note).persisted?
  end

  test '그룹빠띠의 빠띠에는 멤버가 아니면 못 만들어요' do
    assert issues(:issue1).in_group?
    refute issues(:issue1).member? users(:two)

    sign_in(users(:two))

    assert_raises CanCan::AccessDenied do
      post notes_path(note: { body: 'body', issue_id: issues(:issue1).id })
    end
  end

  test '고쳐요' do
    sign_in(users(:one))

    put note_path(notes(:note1), note: { body: 'body x', issue_id: issues(:issue2).id })

    refute assigns(:note).errors.any?
    assigns(:note).reload
    assert_equal 'body x', assigns(:note).body
    assert_equal users(:one), assigns(:note).user
  end

  test '세상에 없었던 새로운 이슈를 넣으면 저장이 안되요' do
    sign_in(users(:one))

    previous_count = Note.count

    assert_raises CanCan::AccessDenied do
      post notes_path(note: { link: 'link', body: 'body', issue_id: -1 })
    end
    assert_equal previous_count, Note.count
  end

  test '내용 없이는 못 만들어요' do
    sign_in(users(:one))

    post notes_path(note: { issue_id: issues(:issue2).id })

    refute assigns(:note).persisted?
  end
end
