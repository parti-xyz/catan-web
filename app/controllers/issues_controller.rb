class IssuesController < ApplicationController
  respond_to :js, :json, :html
  before_filter :authenticate_user!,
    only: [:create, :update, :destroy]
  before_filter :fetch_issue_by_slug, only: [:slug, :slug_articles, :slug_comments, :slug_opinions, :slug_talks]
  load_and_authorize_resource

  def index
    prepare_meta_tags title: "빠띠", description: "모든 빠띠들입니다."
    @issues = Issue.all
    if request.format.json?
      @issues = @issues.limit(10)
    else
      @issue_of_all = Issue::OF_ALL
    end

    if params[:query].present?
      @issues = @issues.where("title like ?", "%#{params[:query]}%" )
    end
    respond_with @issues
  end

  def show
    @issue = Issue.find params[:id]
    redirect_to slug_issue_path(slug: @issue.slug)
  end

  def slug
    slug_comments
    respond_to do |format|
      format.js { render 'slug_comments' }
      format.html { render 'slug_comments' }
    end
  end

  def slug_articles
    @articles = @issue.articles.recent.page params[:page]
    unless view_context.current_page?(root_url)
      prepare_meta_tags title: @issue.title,
                        description: @issue.body,
                        image: @issue.cover_url
    end
  end

  def slug_comments
    @comments = @issue.comments.recent.page params[:page]
    unless view_context.current_page?(root_url)
      prepare_meta_tags title: @issue.title,
                        description: @issue.body,
                        image: @issue.cover_url
    end
  end

  def slug_opinions
    @opinions = @issue.opinions.recent.page params[:page]
    unless view_context.current_page?(root_url)
      prepare_meta_tags title: @issue.title,
                        description: @issue.body,
                        image: @issue.cover_url
    end
  end

  def slug_talks
    @talks = @issue.talks.recent.page params[:page]
    unless view_context.current_page?(root_url)
      prepare_meta_tags title: @issue.title,
                        description: @issue.body,
                        image: @issue.cover_url
    end
  end

  def create
    if !%w(all).include?(@issue.slug) and @issue.save
      redirect_to @issue
    else
      render 'new'
    end
  end

  def update
    @issue.assign_attributes(issue_params)
    if @issue.save
      redirect_to @issue
    else
      render 'edit'
    end
  end

  def destroy
    @issue.destroy
    redirect_to root_path
  end

  def users

  end

  def exist
    respond_to do |format|
      format.json { render json: Issue.exists?(title: params[:title]) }
    end
  end

  helper_method :current_issue
  def current_issue
    @issue
  end

  private

  def fetch_issue_by_slug
    @issue = Issue.find_by slug: params[:slug]
    @issue = Issue::OF_ALL if params[:slug] == 'all'
    if @issue.blank?
      @issue_by_title = Issue.find_by(title: params[:slug].titleize)
      if @issue_by_title.present?
        redirect_to @issue_by_title and return
      else
        render_404 and return
      end
    end
  end

  def issue_params
    params.require(:issue).permit(:title, :body, :logo, :cover, :slug)
  end
end
