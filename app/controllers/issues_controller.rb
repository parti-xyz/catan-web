class IssuesController < ApplicationController
  respond_to :js, :json, :html
  before_filter :authenticate_user!, only: [:create, :update, :destroy]
  before_filter :fetch_issue_by_slug, only: [:new_comments_count, :slug_users, :slug_articles, :slug_comments, :slug_opinions, :slug_talks]
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
    redirect_to view_context.issue_home_path(@issue)
  end

  def slug_articles
    @articles = @issue.articles.recent.page params[:page]
    prepare_issue_meta_tags
  end

  def new_comments_count
    @count = @issue.comments.recent.next_of(params[:first_id]).count
  end

  def slug_comments
    @comments = @issue.comments.recent.limit(25).previous_of params[:last_id]
    @is_last_page = (@comments.empty? or @issue.comments.recent.previous_of(@comments.last.id).empty?)
    prepare_issue_meta_tags
  end

  def slug_opinions
    @opinions = @issue.opinions.recent.page params[:page]
    prepare_issue_meta_tags
  end

  def slug_talks
    @talks = @issue.talks.recent.page params[:page]
    prepare_issue_meta_tags
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
      errors_to_flash @article
      render 'edit'
    end
  end

  def destroy
    @issue.destroy
    redirect_to root_path
  end

  def slug_users
  end

  def exist
    respond_to do |format|
      format.json { render json: Issue.exists?(title: params[:title]) }
    end
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
    params.require(:issue).permit(:title, :body, :logo, :cover, :slug, :basic)
  end

  def prepare_issue_meta_tags
    unless view_context.current_page?(root_url)
      prepare_meta_tags title: meta_issue_title(@issue),
                        description: @issue.body,
                        image: @issue.cover_url
    end
  end
end
