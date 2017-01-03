require 'test_helper'

class PostsWithFileSourceTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    sign_in(users(:one))

    post posts_path, post: { issue_id: issues(:issue2).id, body: 'body', reference_attributes: { attachment: fixture_file('files/sample.pdf') }, reference_type: 'FileSource' }

    assert assigns(:post).persisted?
    assigns(:post).reload

    assert_equal users(:one), assigns(:post).user
    assert_equal 'sample.pdf', assigns(:post).reference.name
    assert_equal issues(:issue2).title, assigns(:post).issue.title
    assert_equal 'body', assigns(:post).body

    assert assigns(:post).comments.empty?
  end

  test '10mb초과하는 파일은 업로드할 수 없어요' do
    sign_in(users(:one))

    post posts_path, post: { issue_id: issues(:issue2).id, body: 'body', reference_attributes: { attachment: fixture_file('files/sample_over_10mb.pdf') }, reference_type: 'FileSource' }

    refute assigns(:post).persisted?
  end

  test '고쳐요' do
    sign_in(users(:one))

    put post_path(posts(:post_talk5)), post: { body: 'body', issue_id: issues(:issue1).id, reference_attributes: { attachment: fixture_file('files/sample.pdf')}, reference_type: 'FileSource' }

    refute assigns(:post).errors.any?
    assigns(:post).reload
    assert_equal 'body', assigns(:post).body
    assert_equal users(:one), assigns(:post).user
    assert_equal issues(:issue1).title, assigns(:post).issue.title
    assert_equal 'sample.pdf', assigns(:post).reference.name
  end

  test '기존 파일을 그대로 두고 고쳐요' do
    sign_in(users(:one))

    original_name = posts(:post_talk5).reload.reference.name

    put post_path(posts(:post_talk5)), post: { body: 'new body', reference_attributes: {id: posts(:post_talk5).reference.id} }
    refute assigns(:post).errors.any?
    assigns(:post).reload
    assert_equal 'new body', assigns(:post).body
    assert_equal original_name, assigns(:post).reference.name
  end
end
