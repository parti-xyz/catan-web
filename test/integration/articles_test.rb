require 'test_helper'

class ArticlesTest < ActionDispatch::IntegrationTest
  def stub_crawl
    OpenGraph.stubs(:new).returns(OpenStruct.new(title: 'page title', description: 'page body', url: 'http://stub'))
    Sidekiq::Testing.inline! do
      yield
    end
  end

  test '만들어요' do
    stub_crawl do
      sign_in(users(:one))

      post articles_path(article: { link: 'link', issue_id: issues(:issue1).id }, comment_body: 'body')

      assert assigns(:article).persisted?
      assigns(:article).reload

      assert_equal 'page title', assigns(:article).title
      assert_equal 'page body', assigns(:article).body
      assert_equal users(:one), assigns(:article).user
      assert_equal LinkSource.find_by(url: 'http://stub'), assigns(:article).link_source
      assert_equal issues(:issue1).title, assigns(:article).issue.title

      comment = assigns(:article).comments.first
      assert comment.persisted?
      assert_equal 'body', comment.body
      assert_equal users(:one), assigns(:article).user
    end
  end

  test '이미 있는 링크로 만들어요' do
    stub_crawl do
      sign_in(users(:one))

      article3_link = articles(:article3).link
      post articles_path(article: { link: article3_link, issue_id: issues(:issue1).id }, comment_body: 'body')

      assert assigns(:article).persisted?
      assigns(:article).reload

      assert_equal 'page title', assigns(:article).title
      assert_equal 'page body', assigns(:article).body
      assert_equal users(:one), assigns(:article).user
      assert_equal LinkSource.find_by(url: 'http://stub'), assigns(:article).link_source
      assert_equal issues(:issue1).title, assigns(:article).issue.title

      comment = assigns(:article).comments.first
      assert comment.persisted?
      assert_equal 'body', comment.body
      assert_equal users(:one), assigns(:article).user
    end
  end

  test '고쳐요' do
    stub_crawl do
      sign_in(users(:admin))

      put article_path(articles(:article1), article: { link: 'link x', issue_id: issues(:issue2).id })

      refute assigns(:article).errors.any?
      assigns(:article).reload
      assert_equal 'page title', assigns(:article).title
      assert_equal 'page body', assigns(:article).body
      assert_equal users(:one), assigns(:article).user
      assert_equal issues(:issue2).title, assigns(:article).issue.title
    end
  end

  test '이미 있는 링크로 고쳐요' do
    stub_crawl do
      sign_in(users(:admin))

      article3_link = articles(:article3).link
      put article_path(articles(:article1), article: { link: article3_link })

      refute assigns(:article).errors.any?
      assert_equal articles(:article3), assigns(:article)
      refute Article.exists?(id: articles(:article1).id)
    end
  end

  test '최근 새로 걸린 링크의 주소로 고쳐요' do
    stub_crawl do
      sign_in(users(:admin))

      article1_link = articles(:article1).link
      put article_path(articles(:article3), article: { link: article1_link })

      refute assigns(:article).errors.any?
      assert_equal articles(:article3), assigns(:article)
      assert_equal articles(:article1).link_source, articles(:article3).reload.link_source
      refute Article.exists?(id: articles(:article1).id)
    end
  end

  test '세상에 없었던 새로운 이슈를 넣으면 저장이 안되요' do
    sign_in(users(:one))

    previous_count = Article.count
    post articles_path(article: { link: 'link', issue_id: -1}, comment_body: 'body')
    assert_equal previous_count, Article.count
  end

  test '글을 숨겨요' do
    sign_in(users(:admin))
    put article_path(articles(:article3), article: { hidden: true })
    assert articles(:article3).reload.hidden?
  end
end
