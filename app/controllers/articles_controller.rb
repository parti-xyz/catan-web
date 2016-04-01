class ArticlesController < ApplicationController
  include OriginPostable
  before_filter :authenticate_user!, except: [:show, :partial]
  load_and_authorize_resource

  def create
    redirect_to root_path and return if fetch_issue.blank?
    redirect_to issue_home_path(@issue) and return if fetch_source.blank?

    ActiveRecord::Base.transaction do
      if @article.save
        @comment = build_comment
        @comment.save if @comment.present?
        crawl
      end
    end
    redirect_to issue_home_path(@issue)
  end

  def update
    redirect_to root_path and return if fetch_issue.blank?
    @article.assign_attributes(update_params)
    redirect_to issue_home_path(@issue) and return if fetch_source.blank?
    ActiveRecord::Base.transaction do
      if @article.save
        @article = Article.merge_by_link!(@article)
        force_crawl
      end
    end
    redirect_to issue_home_path(@article.issue)
  end

  def show
    render(:partial, layout: false) and return if request.headers['X-PJAX']
    prepare_meta_tags title: @article.title,
                      description: @article.body
  end

  def destroy
    @article.destroy
    redirect_to issue_home_path(@talk.issue)
  end

  helper_method :current_issue
  def current_issue
    @issue ||= @article.try(:issue)
  end

  def postable_controller?
    true
  end

  private

  def create_params
    params.require(:article).permit(:link)
  end

  def update_params
    params.require(:article).permit(:link, :hidden)
  end

  def fetch_issue
    return @issue if @issue.present?
    @article.issue = @issue = (Issue.find_by(title: params[:issue_title]) || @article.issue)
  end

  def fetch_source
    return if @article.link.blank?
    source = LinkSource.find_or_create_by! url: @article.link
    @article.link_source = source
    @article.user ||= current_user
  end

  def build_comment
    body = params[:comment_body]
    return if body.blank?
    @article.acting_as.comments.build(body: body, user: current_user)
  end

  def force_crawl
    CrawlingJob.perform_async(@article.link_source.id)
  end

  def crawl
    if @article.link_source.crawling_status.not_yet?
      CrawlingJob.perform_async(@article.link_source.id)
    end
  end
end
