class IssuesController < ApplicationController
  respond_to :js, :json, :html
  before_filter :authenticate_user!, only: [:create, :update, :destroy]
  before_filter :fetch_issue_by_slug, only: [:new_comments_count, :slug_users, :slug_articles, :slug_comments, :slug_opinions, :slug_talks]
  load_and_authorize_resource :group
  load_and_authorize_resource

  def index
    prepare_meta_tags title: "빠띠", description: "모든 빠띠들입니다."
    @issues = Issue.all
    if params[:query].present?
      @issues = @issues.where("title like ?", "%#{params[:query]}%" )
    end
    respond_with @issues
  end

  def show
    @issue = Issue.find params[:id]
    redirect_to issue_home_path(@issue)
  end

  def slug_articles
    articles_page
    prepare_issue_meta_tags
  end

  def slug_opinions
    opinions_page
    prepare_issue_meta_tags
  end

  def slug_talks
    talks_page
    prepare_issue_meta_tags
  end

  def new
    authorize_group!
  end

  def edit
    authorize_group!
  end

  def create
    authorize_group!
    @issue.makers.build(user: current_user)
    if !%w(all).include?(@issue.slug) and @issue.save
      redirect_to @issue
    else
      render 'new'
    end
  end

  def update
    authorize_group!
    @issue.assign_attributes(issue_params)
    if @issue.makers_nickname.present?
      @issue.makers.destroy_all
      @issue.makers_nickname.split(",").map(&:strip).each do |nickname|
        user = User.find_by(nickname: nickname)
        @issue.makers.build(user: user) if user.present?
      end
    end
    if @issue.save
      redirect_to @issue
    else
      errors_to_flash @issue
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

  def authorize_group!
    if @group.present?
      authorize! :manage, @group
    end
  end

  def fetch_issue_by_slug
    @issue = Issue.find_by slug: params[:slug]
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
    params.require(:issue).permit(:group_id, :title, :body, :logo, :cover, :slug, :basic, :makers_nickname)
  end

  def prepare_issue_meta_tags
    unless view_context.current_page?(root_url)
      prepare_meta_tags title: meta_issue_title(@issue),
                        description: (@issue.body.presence || "#{@issue.title} 빠띠에서 즐거운 수다파티"),
                        image: @issue.cover_url
    end
  end
end
