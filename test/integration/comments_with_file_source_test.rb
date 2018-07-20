require 'test_helper'

class CommentsWithFileSourceTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    sign_in(users(:one))

    post post_comments_path(post_id: posts(:post_talk1).id, format: :js), params: { comment: { body: 'body', file_sources_attributes: {'0': { attachment: fixture_file('files/sample.pdf')} } } }

    assert assigns(:comment).persisted?
    assert_equal 'body', assigns(:comment).body
    assert_equal users(:one), assigns(:comment).user

    assigns(:comment).reload

    assert_equal 'sample.pdf', assigns(:comment).file_sources.first.name
  end

  test '10mb초과하는 파일은 업로드할 수 없어요' do
    sign_in(users(:one))

    post post_comments_path(post_id: posts(:post_talk1).id, format: :js), params: { comment: { body: 'body', file_sources_attributes: {'0': { attachment: fixture_file('files/sample_over_10mb.pdf')} } } }

    refute assigns(:comment).persisted?
  end
end
