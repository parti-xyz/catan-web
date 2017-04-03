require 'test_helper'

class PostsWithFileSourceTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    sign_in(users(:one))

    post posts_path, post: { issue_id: issues(:issue2).id, body: 'body', file_sources_attributes: {'0': { attachment: fixture_file('files/sample.pdf')} } }

    assert assigns(:post).persisted?
    assigns(:post).reload

    assert_equal users(:one), assigns(:post).user
    assert_equal 'sample.pdf', assigns(:post).file_sources.first.name
    assert_equal issues(:issue2).title, assigns(:post).issue.title
    assert_equal '<p>body</p>', assigns(:post).body

    assert assigns(:post).comments.empty?
  end

  test '10mb초과하는 파일은 업로드할 수 없어요' do
    sign_in(users(:one))

    post posts_path, post: { issue_id: issues(:issue2).id, body: 'body', file_sources_attributes: { '0': { attachment: fixture_file('files/sample_over_10mb.pdf') } } }

    refute assigns(:post).persisted?
  end

  test '고쳐요' do
    sign_in(users(:one))

    put post_path(posts(:post_talk5)),
      post: {
        body: 'body',
        issue_id: issues(:issue1).id,
        file_sources_attributes: { '0': { id: posts(:post_talk5).file_sources.first.id, _destroy: '1' }, '1': { attachment: fixture_file('files/sample.pdf') } } }

    refute assigns(:post).errors.any?
    assigns(:post).reload
    assert_equal '<p>body</p>', assigns(:post).body
    assert_equal users(:one), assigns(:post).user
    assert_equal issues(:issue1).title, assigns(:post).issue.title
    assert_equal 'sample.pdf', assigns(:post).file_sources.first.name
  end

  test '기존 파일을 그대로 두고 고쳐요' do
    sign_in(users(:one))

    original_name = posts(:post_talk5).reload.file_sources.first.name

    put post_path(posts(:post_talk5)), post: { body: 'new body', file_sources_attributes: { '0': { id: posts(:post_talk5).file_sources.first.id } } }
    refute assigns(:post).errors.any?
    assigns(:post).reload
    assert_equal '<p>new body</p>', assigns(:post).body
    assert_equal original_name, assigns(:post).file_sources.first.name
  end
end
