class ArticlesController < ApplicationController
  before_filter :authenticate_user!, except: [:show, :partial]
  load_and_authorize_resource

  def create
    redirect_to root_path and return if fetch_issue.blank?
    redirect_to issue_home_path(@issue) and return if @article.link.blank?

    @article.user ||= current_user
    need_to_crawl = false
    ActiveRecord::Base.transaction do
      @article = Article.merge_by_link!(@article)
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
      articles_page
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
    @article.issue = @issue = (Issue.find_by(id: params[:article][:issue_id]) || @article.issue)
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
