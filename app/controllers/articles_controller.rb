class ArticlesController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :partial]
  load_and_authorize_resource

  def index
    articles_page
  end

  def create
    redirect_to root_path and return if fetch_issue.blank?

    @article.source = @article.source.unify_by_url
    @article.user ||= current_user
    need_to_crawl = false
    ActiveRecord::Base.transaction do
      @article = Article.unify_by_url!(@article)
      if !@article.save
        errors_to_flash(@article)
        raise ActiveRecord::Rollback
      end

      @comment = build_comment
      if @comment.blank? or !@comment.save
        errors_to_flash(@comment) if @comment.present?
        raise ActiveRecord::Rollback
      end

      need_to_crawl = true
    end
    crawl if need_to_crawl
    redirect_to params[:back_url].presence || issue_home_path_or_url(@issue)
  end

  def update
    redirect_to root_path and return if fetch_issue.blank?

    @article.assign_attributes(update_params_only_link_source_url)
    @article.source = @article.source.unify_by_url
    redirect_to issue_home_path(@issue) and return if @article.source.blank?

    need_to_crawl = false
    ActiveRecord::Base.transaction do
      @article = Article.unify_by_url!(@article)
      @article.assign_attributes(update_params_exclude_link_source_url)
      if @article.save
        need_to_crawl = true
        redirect_to @article
      else
        errors_to_flash(@article)
        render 'edit'
      end
    end
    force_crawl if need_to_crawl
  end

  def show
    if request.headers['X-PJAX']
      render(:partial, layout: false) and return
    else
      @issue = @article.issue
      articles_page(@issue)
      @list_title = meta_issue_full_title(@issue)
      @list_url = issue_articles_path(@issue)
      @paginate_params = {controller: 'issues', action: 'slug_articles', slug: @issue.slug, id: nil}
    end
    prepare_meta_tags title: @article.title,
                      description: @article.body,
                      image: (@article.image if @article.has_image?),
                      og_title: [@article.title, @article.site_name.try(:upcase)].reject { |c| c.blank? }.map(&:strip).join(' | ')
  end

  def postable_controller?
    true
  end

  private

  def create_params
    params.require(:article).permit(:source_type, source_attributes: [:url])
  end

  def update_params_only_link_source_url
    params.require(:article).permit(:source_type, source_attributes: [:url])
  end

  def update_params_exclude_link_source_url
    params.require(:article).permit(:hidden)
  end

  def fetch_issue
    return @issue if @issue.present?
    @article.issue = @issue = (Issue.find_by(id: params[:article][:issue_id]) || @article.issue)
  end

  def build_comment
    body = params[:comment_body]
    return if body.blank?
    @article.acting_as.comments.build(body: body, user: current_user)
  end

  def force_crawl
    CrawlingJob.perform_async(@article.source.id)
  end

  def crawl
    if @article.source.crawling_status.not_yet?
      CrawlingJob.perform_async(@article.source.id)
    end
  end
end
