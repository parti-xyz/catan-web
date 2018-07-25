require 'test_helper'

class PostsWithWikiTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    sign_in(users(:one))

    post posts_path, params: { post: { issue_id: issues(:issue2).id, body: 'body', wiki_attributes: { title: 'wiki title', body: 'wiki body' } } }

    assert assigns(:post).persisted?
    assigns(:post).reload

    assert_equal users(:one), assigns(:post).user
    assert_equal 'wiki title', assigns(:post).wiki.title
    assert_equal '<p>wiki body</p>', assigns(:post).wiki.body
  end

  test '고쳐요' do
    sign_in(users(:one))

    patch wiki_post_path(posts(:post_wiki1)),
      params: {
        post: {
          wiki_attributes: { title: 'wiki updated title', body: 'wiki updated body' } }
      }

    refute assigns(:post).errors.any?
    assigns(:post).reload
    assert_equal 'wiki updated title', assigns(:post).wiki.title
    assert_equal '<p>wiki updated body</p>', assigns(:post).wiki.body
    assert_equal '<p>wiki updated body</p>', assigns(:post).wiki.wiki_histories.last.body
  end
end
