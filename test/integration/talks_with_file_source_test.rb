require 'test_helper'

class TalksWithFileSourceTest < ActionDispatch::IntegrationTest

  test '만들어요' do
    sign_in(users(:one))

    post talks_path, talk: { issue_id: issues(:issue2).id, title: 'title', body: 'body', section_id: sections(:section2).id, reference_attributes: { attachment: fixture_file('files/sample.pdf') }, reference_type: 'FileSource' }

    assert assigns(:talk).persisted?
    assigns(:talk).reload

    assert_equal users(:one), assigns(:talk).user
    assert_equal 'sample.pdf', assigns(:talk).reference.name
    assert_equal issues(:issue2).title, assigns(:talk).issue.title
    assert_equal 'body', assigns(:talk).body

    assert assigns(:talk).comments.empty?
  end

  test '10mb초과하는 파일은 업로드할 수 없어요' do
    sign_in(users(:one))

    post talks_path, talk: { issue_id: issues(:issue2).id, body: 'body', reference_attributes: { attachment: fixture_file('files/sample_over_10mb.pdf') }, reference_type: 'FileSource' }

    refute assigns(:talk).persisted?
  end

  test '고쳐요' do
    sign_in(users(:one))

    put talk_path(talks(:talk5)), talk: { body: 'body', issue_id: issues(:issue1).id, reference_attributes: { attachment: fixture_file('files/sample.pdf')}, reference_type: 'FileSource' }

    refute assigns(:talk).errors.any?
    assigns(:talk).reload
    assert_equal 'body', assigns(:talk).body
    assert_equal users(:one), assigns(:talk).user
    assert_equal issues(:issue1).title, assigns(:talk).issue.title
    assert_equal 'sample.pdf', assigns(:talk).reference.name
  end

  test '기존 파일을 그대로 두고 고쳐요' do
    sign_in(users(:one))

    original_name = talks(:talk5).reload.reference.name

    put talk_path(talks(:talk5)), talk: { body: 'new body', reference_attributes: {id: talks(:talk5).reference.id} }
    refute assigns(:talk).errors.any?
    assigns(:talk).reload
    assert_equal 'new body', assigns(:talk).body
    assert_equal original_name, assigns(:talk).reference.name
  end
end
