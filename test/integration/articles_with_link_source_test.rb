require 'test_helper'

class ArticlesWithLinkSourceTest < ActionDispatch::IntegrationTest
  def stub_crawl(link = nil)
    stub =  (link.present? ? OpenGraph.expects(:new).with(link) : OpenGraph.stubs(:new))
    stub.returns(OpenStruct.new(title: 'page title', description: 'page body', url: (link || 'http://stub')))
    Sidekiq::Testing.inline! do
      yield
    end
  end

  test '만들어요' do
    stub_crawl do
      sign_in(users(:one))

      post articles_path, article: { issue_id: issues(:issue1).id, body: 'body', source_attributes: { url: 'link' }, source_type: 'LinkSource' }

      assert assigns(:article).persisted?
      assigns(:article).reload

      assert_equal 'page title', assigns(:article).title
      assert_equal 'page body', assigns(:article).source_body
      assert_equal 'body', assigns(:article).body
      assert_equal users(:one), assigns(:article).user
      assert_equal LinkSource.find_by(url: 'http://stub'), assigns(:article).source
      assert_equal issues(:issue1).title, assigns(:article).issue.title

      assert assigns(:article).comments.empty?
    end
  end

  test '이미 있는 링크로 만들어요' do
    stub_crawl do
      sign_in(users(:one))

      article3_link = articles(:article3).source.url
      post articles_path, article: { issue_id: issues(:issue1).id, body: 'body', source_attributes: { url: article3_link }, source_type: 'LinkSource' }

      assert assigns(:article).persisted?
      assigns(:article).reload

      assert_equal 'page title', assigns(:article).title
      assert_equal 'page body', assigns(:article).source_body
      assert_equal 'body', assigns(:article).body
      assert_equal users(:one), assigns(:article).user
      assert_equal LinkSource.find_by(url: 'http://stub'), assigns(:article).source
      assert_equal issues(:issue1).title, assigns(:article).issue.title

      assert assigns(:article).comments.empty?
    end
  end

  test '고쳐요' do
    stub_crawl 'link x' do
      sign_in(users(:one))

      put article_path(articles(:article1)), article: { body: 'body', issue_id: issues(:issue2).id, source_attributes: { url: 'link x'}, source_type: 'LinkSource' }

      refute assigns(:article).errors.any?
      assigns(:article).reload
      assert_equal 'page title', assigns(:article).title
      assert_equal 'page body', assigns(:article).source_body
      assert_equal 'body', assigns(:article).body
      assert_equal users(:one), assigns(:article).user
      assert_equal issues(:issue2).title, assigns(:article).issue.title
      assert_equal 'link x', assigns(:article).source.url
    end
  end

  test '이미 있는 링크로 고쳐요' do
    article3_link = articles(:article3).source.url
    stub_crawl(article3_link) do
      sign_in(users(:one))

      put article_path(articles(:article1)), article: { source_attributes: { url: article3_link }, source_type: 'LinkSource' }

      refute assigns(:article).errors.any?
      assert_equal articles(:article3).source, assigns(:article).source
      assert Article.exists?(id: articles(:article1).id)
    end
  end

  test '최근 새로 걸린 링크의 주소로 고쳐요' do
    article1_link = articles(:article1).source.url
    stub_crawl(article1_link) do
      sign_in(users(:one))

      put article_path(articles(:article3)), article: { source_attributes: { url: article1_link }, source_type: 'LinkSource' }

      refute assigns(:article).errors.any?
      assert_equal articles(:article3), assigns(:article)
      assert_equal articles(:article1).source, articles(:article3).reload.source
      assert Article.exists?(id: articles(:article1).id)
    end
  end

  test '세상에 없는 빠띠를 넣으면 저장이 안되요' do
    sign_in(users(:one))

    previous_count = Article.count
    post articles_path, article: { body: 'body', source_attributes: { url: 'link' }, source_type: 'LinkSource', issue_id: -1}
    assert_equal previous_count, Article.count
  end

  test '본문이 없으면 안만들어요' do
    stub_crawl do
      sign_in(users(:one))

      post articles_path, article: { source_attributes: { url: 'link'}, source_type: 'LinkSource', issue_id: issues(:issue1).id }

      refute assigns(:article).persisted?
    end
  end
end
