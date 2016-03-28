class ArticlesController < ApplicationController
  include OriginPostable
  before_filter :authenticate_user!, except: [:show]
  load_and_authorize_resource

  def create
    redirect_to root_path and return if fetch_issue.blank?
    redirect_to issue_home_path(@issue) and return if fetch_source.blank?
    @comment = build_comment
    if @article.save and ( @comment.blank? or @comment.save)
      crawl
    end
    redirect_to issue_home_path(@issue)
  end

  def update
    redirect_to root_path and return if fetch_issue.blank?
    redirect_to issue_home_path(@issue) and return if fetch_source.blank?
    if @article.update_attributes(article_params)
      crawl
    end
    redirect_to issue_home_path(@issue)
  end

  def destroy
    @article.destroy
    redirect_to issue_home_path(@article.issue)
  end

  def show
    prepare_meta_tags title: @article.title,
                      description: @article.body
  end

  helper_method :current_issue
  def current_issue
    @issue ||= @article.try(:issue)
  end

  def postable_controller?
    true
  end

  private

  def article_params
    params.require(:article).permit(:link)
  end

  def fetch_issue
    @issue ||= Issue.find_by title: params[:issue_title]
    @article.issue = @issue.presence || @article.issue
  end

  def fetch_source
    return if @article.link.blank?

    @article = fetch_issue.articles.find_by(link: @article.link) || @article

    source = LinkSource.find_or_create_by! url: @article.link
    @article.link_source = source
    @article.user ||= current_user
  end

  def build_comment
    body = params[:comment_body]
    return if body.blank?
    @article.acting_as.comments.build(body: body, user: current_user)
  end

  def crawl
    if @article.link_source.crawling_status.not_yet?
      CrawlingJob.perform_async(@article.link_source.id)
    end
  end
end
