class PagesController < ApplicationController
  def home

    slugs = %w(feminism basic-income digital-social-innovation workandlife_integration household_chemicals 20th-assembly environment climate-change sewolho)
    @recommend_issues_map = Issue.where(slug: slugs).map { |issue| {issue: issue, image_url: issue.logo.url} }

    bad_issues = Issue.where(slug: 'heelo')
    valid_posts = Post.where.not(issue: bad_issues)
    @recommend_article_posts = valid_posts.only_articles.hottest.limit(9)
    @recommend_talk_posts = valid_posts.only_talks.hottest.limit(3)
    @recommend_opinion_posts = valid_posts.only_opinions.hottest.limit(10)
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
