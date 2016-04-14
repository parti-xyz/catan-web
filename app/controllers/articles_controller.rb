class ArticlesController < ApplicationController
  include OriginPostable
  before_filter :authenticate_user!, except: [:show, :partial]
  load_and_authorize_resource

  def create
    redirect_to root_path and return if fetch_issue.blank?
    redirect_to issue_home_path(@issue) and return if @article.link.blank?

    @article.user ||= current_user
    need_to_crawl = false
    ActiveRecord::Base.transaction do
      @article = Article.merge_by_link!(@article)
      if @article.save
        @comment = build_comment
        @comment.save if @comment.present?
        need_to_crawl = true
      end
    end
    crawl if need_to_crawl
    redirect_to params[:back_url].presence || issue_home_path(@issue)
  end

  def update
    redirect_to root_path and return if fetch_issue.blank?
    @article.assign_attributes(update_link_param)
    redirect_to issue_home_path(@issue) and return if @article.link.blank?

    need_to_crawl = false
    ActiveRecord::Base.transaction do
      @article = Article.merge_by_link!(@article)
      @article.assign_attributes(update_params_exclude_link)
      if @article.save
        need_to_crawl = true
        redirect_to @article
      else
        render 'edit'
      end
    end
    force_crawl if need_to_crawl
  end

  def show
    if request.headers['X-PJAX']
      render(:partial, layout: false) and return
    end
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

  def create_params
    params.require(:article).permit(:link)
  end

  def update_params_exclude_link
    params.require(:article).permit(:hidden)
  end

  def update_link_param
    params.require(:article).permit(:link)
  end

  def fetch_issue
    return @issue if @issue.present?
    @article.issue = @issue = (Issue.find_by(title: params[:issue_title]) || @article.issue)
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
