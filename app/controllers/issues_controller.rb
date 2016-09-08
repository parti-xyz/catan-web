class IssuesController < ApplicationController
  before_filter :authenticate_user!, only: [:create, :update, :destroy, :remove_logo, :remove_cover]
  before_filter :fetch_issue_by_slug, only: [:new_posts_count, :slug_home, :slug_users, :slug_articles, :slug_comments, :slug_opinions, :slug_talks, :slug_notes, :slug_wikis]
  load_and_authorize_resource
  before_filter :verify_issue_group, only: [:slug_home, :slug_articles, :slug_opinions, :slug_talks, :slug_notes, :slug_wikis, :edit]
  before_filter :prepare_issue_meta_tags, only: [:show, :slug_home, :slug_articles, :slug_opinions, :slug_talks, :slug_notes, :slug_wikis, :slug_users]

  def index
    @issues = Issue.limit(10)
    if params[:query].present?
      @issues = @issues.where("title like ?", "%#{params[:query]}%")
    end

    respond_to do |format|
      format.json { render json: @issues }
    end
  end

  def search
    @issues = Issue.search_for(params[:keyword])
    if current_group.present?
      @issues = @issues.where(group_slug: current_group.try(:slug))
    end

    case params[:sort]
    when 'hottest'
      @issues = @issues.hottest
    when 'recent'
      @issues = @issues.recent
    when 'name'
      @issues = @issues.sort{ |a, b| a.compare_title(b) }
    else
      @issues = @issues.recent_touched
    end

    @issues = @issues.categorized_with(params[:category]) if params[:category].present?
  end

  def show
    @issue = Issue.find params[:id]
    redirect_to issue_home_url(@issue)
  end

  def slug_home
    @last_post = @issue.posts.newest(field: :last_touched_at)

    previous_last_post = Post.find_by(id: params[:last_id])

    issus_posts = @issue.posts.order(last_touched_at: :desc)
    @posts = issus_posts.limit(25).previous_of_post(previous_last_post)

    current_last_post = @posts.last
    @is_last_page = (issus_posts.empty? or issus_posts.previous_of_post(current_last_post).empty?)
  end

  def slug_articles
    articles_page(@issue)
  end

  def slug_opinions
    opinions_page(@issue)
  end

  def slug_talks
    talks_page(@issue)
  end

  def slug_notes
    notes_page(@issue)
  end

  def create
    @issue.makers.build(user: current_user)
    @issue.members.build(user: current_user)
    @issue.group_slug = current_group.try(:slug)
    @issue.sections.build(name: Section::DEFAULT_NAME)

    @watch = current_user.watches.build(issue: @issue)

    ActiveRecord::Base.transaction do
      if !%w(all).include?(@issue.slug) and @issue.save and @watch.save
        redirect_to @issue
      else
        render 'new'
      end
    end
  end

  def update
    @issue.assign_attributes(issue_params)

    ActiveRecord::Base.transaction do
      if @issue.makers_nickname.present?
        @issue.makers.destroy_all
        @issue.makers_nickname.split(",").map(&:strip).uniq.each do |nickname|
          user = User.find_by(nickname: nickname)
          if user.present?
            @issue.makers.build(user: user)
          end
        end
      end
      if @issue.save
        @issue.makers.each do |maker|
          @watch = maker.user.watches.build(issue: @issue)
          @watch.save
        end
        redirect_to @issue
      else
        errors_to_flash @issue
        render 'edit'
      end
    end
  end

  def destroy
    @issue.destroy
    redirect_to root_path
  end

  def remove_logo
    @issue.remove_logo!
    @issue.save
    redirect_to [:edit, @issue]
  end

  def remove_cover
    @issue.remove_cover!
    @issue.save
    redirect_to [:edit, @issue]
  end

  def exist
    respond_to do |format|
      format.json { render json: Issue.exists?(title: params[:title]) }
    end
  end

  def new_posts_count
    last_post = Post.find_by id: params[:first_id]
    if last_post.blank?
      @count = 0
    else
      @count = @issue.posts.next_of_post(last_post).count
    end
  end

  private

  def fetch_issue_by_slug
    @issue = Issue.find_by slug: params[:slug], group_slug: current_group.try(:slug)
    if @issue.blank?
      @issue_by_title = Issue.find_by(title: params[:slug].titleize, group_slug: current_group.try(:slug))
      if @issue_by_title.present?
        redirect_to @issue_by_title and return
      else
        render_404 and return
      end
    end
  end

  def issue_params
    params.require(:issue).permit(:title, :body, :logo, :cover, :slug, :basic, :makers_nickname, :telegram_link, :tag_list, :category_slug)
  end

  def prepare_issue_meta_tags
    prepare_meta_tags title: meta_issue_title(@issue),
                      description: (@issue.body.presence || "#{@issue.title} 빠띠에서 즐거운 수다파티"),
                      image: @issue.logo_url
  end

  def verify_issue_group
    verify_group(@issue)
  end
end
