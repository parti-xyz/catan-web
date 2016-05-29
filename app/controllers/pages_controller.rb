class PagesController < ApplicationController
  def home
    @recommend_issues_map = Issue.all.map { |issue| {issue: issue, image_url: issue.logo.url} }
    @recommend_article_posts = Post.only_articles.hottest.limit(9)
    @recommend_talk_posts = Post.only_talks.hottest.limit(3)
    @recommend_opinion_posts = Post.only_opinions.hottest.limit(10)
  end

  def about
  end

  def robots
    respond_to :text
    expires_in 6.hours, public: true
  end

  def stat
    StatisticsJob.perform_async
    redirect_to root_path
  end

  def components
  end
end
