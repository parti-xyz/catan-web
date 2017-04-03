require 'test_helper'

class PostsWithLinkSourceTest < ActionDispatch::IntegrationTest
  def stub_crawl(link = nil)
    stub =  (link.present? ? OpenGraph.expects(:new).with(link) : OpenGraph.stubs(:new))
    stub.returns(OpenStruct.new(title: 'page title', description: 'page body', url: (link || 'http://stub.xx')))
    Sidekiq::Testing.inline! do
      yield
    end
  end

  test '만들어요' do
    stub_crawl do
      sign_in(users(:one))

      post posts_path, post: { issue_id: issues(:issue2).id, body: 'body http://link.xx', is_html_body: 'false' }
      assert assigns(:post).persisted?
      assigns(:post).reload
      assert_equal 'page title', assigns(:post).link_source.title
      assert_equal 'page body', assigns(:post).link_source.body
      assert assigns(:post).body.include? 'body'
      assert_equal users(:one), assigns(:post).user
      assert_equal LinkSource.find_by(url: 'http://stub.xx'), assigns(:post).link_source

      assert assigns(:post).comments.empty?
    end
  end

  test '같은 링크로 여러 개의 논의를 만들 수 있어요' do
    stub_crawl do
      sign_in(users(:one))

      post_talk3_link = posts(:post_talk3).link_source.url
      post posts_path, post: { issue_id: issues(:issue2).id, body: "body #{post_talk3_link}", is_html_body: 'false' }
      assert assigns(:post).persisted?
      assigns(:post).reload

      assert_equal 'page title', assigns(:post).link_source.title
      assert_equal 'page body', assigns(:post).link_source.body
      assert assigns(:post).body.include? 'body'
      assert_equal users(:one), assigns(:post).user
      assert_equal LinkSource.find_by(url: 'http://stub.xx'), assigns(:post).link_source
      assert_equal issues(:issue2).title, assigns(:post).issue.title

      assert assigns(:post).comments.empty?
    end
  end

  test '고쳐요' do
    stub_crawl 'http://link.xx' do
      sign_in(users(:one))

      put post_path(posts(:post_talk1)), post: { body: 'body http://link.xx', issue_id: issues(:issue1).id, is_html_body: 'false' }

      refute assigns(:post).errors.any?
      assigns(:post).reload
      assert_equal 'page title', assigns(:post).link_source.title
      assert_equal 'page body', assigns(:post).link_source.body
      assert assigns(:post).body.include? 'body'
      assert_equal users(:one), assigns(:post).user
      assert_equal issues(:issue1).title, assigns(:post).issue.title
      assert_equal 'http://link.xx', assigns(:post).link_source.url
    end
  end

  test '다른 논의에서 레퍼런스하던 링크로 고칠 수 있어요' do
    post_talk3_link = posts(:post_talk3).link_source.url
    stub_crawl(post_talk3_link) do
      sign_in(users(:one))

      put post_path(posts(:post_talk1)), post: { body: "body #{post_talk3_link}", is_html_body: 'false' }
      refute assigns(:post).errors.any?
      assert_equal posts(:post_talk3).link_source, assigns(:post).link_source
      assert Post.exists?(id: posts(:post_talk1).id)
    end
  end

  test '최근 새로 걸린 링크의 주소로 고쳐요' do
    post_talk1_link = posts(:post_talk1).link_source.url
    stub_crawl(post_talk1_link) do
      sign_in(users(:one))

      put post_path(posts(:post_talk3)), post: { body: "body #{post_talk1_link}", is_html_body: 'false' }
      refute assigns(:post).errors.any?
      assert_equal posts(:post_talk3), assigns(:post)
      assert_equal posts(:post_talk1).link_source, posts(:post_talk3).reload.link_source
      assert Post.exists?(id: posts(:post_talk1).id)
    end
  end

  test '파일을 넣으면 링크 안 만들어요' do
    sign_in(users(:one))

    post posts_path, post: { issue_id: issues(:issue2).id, body: 'body http://daum.net', file_sources_attributes: { '0': { attachment: fixture_file('files/sample.pdf') } } }

    assert assigns(:post).persisted?
    assigns(:post).reload

    assert_equal users(:one), assigns(:post).user
    assert assigns(:post).link_source.nil?
    assert_equal 'sample.pdf', assigns(:post).file_sources.first.name
    assert_equal issues(:issue2).title, assigns(:post).issue.title
    assert assigns(:post).comments.empty?
  end
end
