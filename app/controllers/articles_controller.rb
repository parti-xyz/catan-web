class ArticlesController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :partial, :recrawl]
  load_and_authorize_resource

  def index
    articles_page
  end

  def create
    @issue = @article.issue
    @article.source = @article.source.unify
    redirect_to issue_home_path_or_url(@issue) and return if @article.source.blank?

    @article.user ||= current_user
    if @article.save
      callback_after_creating_article
    else
      errors_to_flash(@article)
    end
    redirect_to params[:back_url].presence || issue_articles_path(@issue)
  end

  def update
    @issue = @article.issue
    @article.assign_attributes(update_params.delete_if {|key, value| value.empty? })
    @article.source = @article.source.unify
    redirect_to issue_home_path_or_url(@issue) and return if @article.source.blank?

    if @article.save
      is_saved = true
      callback_after_updating_article
      redirect_to @article
    else
      errors_to_flash(@article)
      render 'edit'
    end
  end

  def show
    if request.headers['X-PJAX']
      render(:partial, layout: false) and return
    else
      @issue = @article.issue
      verify_group(@issue)
      articles_page(@issue)
      @list_title = meta_issue_full_title(@issue)
      @list_url = issue_articles_path(@issue)
      @paginate_params = {controller: 'issues', action: 'slug_articles', slug: @issue.slug, id: nil}
    end
    prepare_meta_tags title: @article.title,
                      description: @article.source_body,
                      image: (@article.image if @article.has_image?),
                      og_title: [@article.title, @article.site_name.try(:upcase)].reject { |c| c.blank? }.map(&:strip).join(' | ')
  end

  def destroy
    @article.destroy
    redirect_to issue_articles_path(@article.issue)
  end

  def recrawl
    render nothing: true, status: :unauthorized and return unless current_user.admin?
    CrawlingJob.perform_async(@article.source.id) if @article.link_source?
  end

  def postable_controller?
    true
  end

  private

  def create_params
    params.require(:article).permit(:body, :source_type, :issue_id, source_attributes: [:url, :attachment])
  end

  def update_params
    params.require(:article).permit(:body, :hidden, :source_type, source_attributes: [:url, :attachment])
  end

  def callback_after_updating_article
    if @article.link_source?
      CrawlingJob.perform_async(@article.source.id)
    end
  end

  def callback_after_creating_article
    if @article.source.try(:crawling_status).try(:not_yet?)
      CrawlingJob.perform_async(@article.source.id)
    end
  end
end
