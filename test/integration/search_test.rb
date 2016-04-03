require 'test_helper'

class ArticlesTest < ActionDispatch::IntegrationTest
  def stub_crawl
    OpenGraph.stubs(:new).returns(OpenStruct.new(title: 'page title', description: 'page body', url: 'http://stub'))
    Sidekiq::Testing.inline! do
      yield
    end
  end

  test '만들어지는 링크 검색' do
    refute Search.search_for('page').any?

    stub_crawl do
      sign_in(users(:one))
      post articles_path(article: { link: 'link' }, comment_body: 'body', issue_title: issues(:issue1).title)

      get search_path(q: 'page')

      assert assigns(:results).map(&:searchable).include?(LinkSource.find_by(url: 'http://stub'))
    end
  end

  test '고쳐지고 삭제되는 링크 검색' do
    refute Search.search_for('page').any?

    stub_crawl do
      sign_in(users(:admin))
      put article_path(articles(:article1), article: { link: 'link x' }, issue_title: issues(:issue2).title)

      get search_path(q: 'page')

      assert assigns(:results).map(&:searchable).include?(LinkSource.find_by(url: 'http://stub'))
      articles(:article1).reload.destroy

      get search_path(q: 'page')
      assert assigns(:results).map(&:searchable).empty?
    end
  end

  test '만들어지는 발언 검색' do
    refute Search.search_for('page').any?

    sign_in(users(:one))
    post opinions_path(opinion: { title: 'page' }, issue_title: issues(:issue1).title, comment_body: 'body')
    opinion = assigns[:opinion]

    get search_path(q: 'page')

    assert assigns(:results).map(&:searchable).include?(opinion)
  end

  test '고쳐지고 삭제되는 발언 검색' do
    refute Search.search_for('page').any?

    sign_in(users(:one))
    put opinion_path(opinions(:opinion1), opinion: { title: 'page' }, issue_title: issues(:issue2).title)
    opinion = assigns[:opinion]

    get search_path(q: 'page')

    assert assigns(:results).map(&:searchable).include?(opinion)

    delete opinion_path(opinions(:opinion1))

    get search_path(q: 'page')
    refute assigns(:results).map(&:searchable).include?(opinion)
  end
end
