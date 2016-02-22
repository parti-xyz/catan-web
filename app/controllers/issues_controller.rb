class IssuesController < ApplicationController
  respond_to :json, :html
  before_filter :authenticate_user!, except: [:show, :index, :slug]
  load_and_authorize_resource

  def index
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
    if params[:slug] == 'all'
      @issue = Issue::OF_ALL
      @posts = Post.all.recent
      @issue.title = '모든 이슈의 최신글'
      @issue.body = '유쾌한 민주주의 플랫폼, 빠띠의 이슈 최신글입니다.'
    else
      @issue = Issue.find_by! slug: params[:slug]
      @posts = @issue.posts.recent
    end
    @posts_for_filter = @posts
    if params[:t].present?
      @posts = @posts.by_postable_type(params[:t])
    end
    @postables = @posts.map &:postable
    render template: 'issues/show'
  end

  def create
    @issue.set_slug
    if !%w(all).include?(@issue.slug) and @issue.save
      redirect_to @issue
    else
      render 'new'
    end
  end

  def update
    @issue.assign_attributes(issue_params)
    @issue.set_slug
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

  private

  def issue_params
    params.require(:issue).permit(:title, :body, :logo, :cover)
  end
end
