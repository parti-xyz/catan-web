class IssuesController < ApplicationController
  before_filter :authenticate_user!, only: [:create, :update, :destroy, :remove_logo, :remove_cover]
  before_filter :fetch_issue_by_slug, only: [:new_posts_count, :slug_home, :slug_users, :slug_references, :slug_polls_or_surveys, :slug_wikis]
  load_and_authorize_resource
  before_filter :verify_issue_group, only: [:slug_home, :slug_references, :slug_polls_or_surveys, :slug_wikis, :edit]
  before_filter :prepare_issue_meta_tags, only: [:show, :slug_home, :slug_references, :slug_polls_or_surveys, :slug_wikis, :slug_users]

  def simple_search
    @issues = Issue.alive.limit(10)
    if params[:query].present?
      @issues = @issues.where("title like ?", "%#{params[:query]}%")
    end

    respond_to do |format|
      format.json { render json: @issues }
    end
  end

  def home
    index
  end

  def index
    as_tags = (params[:keyword].try(:split) || []).map(&:strip).reject(&:blank?)

    @issues = Issue.displayable_in_current_group(current_group)
    @issues = @issues.where.any_of(Issue.alive.search_for(params[:keyword]), Issue.alive.tagged_with(as_tags, any: true)) if params[:keyword].present?

    params[:sort] ||= (current_group.blank? ? 'hottest' : 'recent_touched')
    case (params[:sort])
    when 'recent'
      @issues = @issues.recent
    when 'name'
      @issues = @issues.sort_by_name
    when 'recent_touched'
      @issues = @issues.recent_touched
    else
      @issues = @issues.hottest
    end

    @issues = @issues.categorized_with(params[:category]) if params[:category].present?
    @issues = @issues.page(params[:page]).per(3 * 10)

    if current_group.blank?
      render 'index'
    else
      render 'group_index'
    end
  end

  def search_by_tags
    if params[:selected_tags] == [""]
      @issues = Issue.alive.hottest
      @no_tags_selected = 'yes'
    else
      @issues = Issue.alive.tagged_with(params[:selected_tags], :any => true)
    end
    @issues = @issues.to_a.reject { |i| i.private_blocked?(current_user) }
  end

  def show
    @issue = Issue.find params[:id]
    redirect_to smart_issue_home_url(@issue)
  end

  def slug_home
    render 'slug_home_blocked' and return if private_blocked?(@issue)

    @last_post = @issue.posts.newest(field: :last_stroked_at)

    previous_last_post = Post.with_deleted.find_by(id: params[:last_id])
    issus_posts = @issue.posts.order(last_stroked_at: :desc)
    @posts = issus_posts.limit(25).previous_of_post(previous_last_post)

    current_last_post = @posts.last
    @is_last_page = (issus_posts.empty? or issus_posts.previous_of_post(current_last_post).empty?)

    if params[:last_id].blank?
      @posts_pinned = @issue.posts.pinned.order('pinned_at desc')
    end
  end

  def slug_polls_or_surveys
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)

    having_poll_and_survey_posts_page(@issue)
  end

  def slug_users
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)

    base = @issue.members.recent
    @is_last_page = base.empty?
    @previous_last = @issue.members.with_deleted.find_by(id: params[:last_id])
    return if @previous_last.blank? and params[:last_id].present?

    @members = base.previous_of_recent(@previous_last).limit(12)

    @current_last = @members.last
    @users = @members.map &:user
    @is_last_page = (@is_last_page or base.previous_of_recent(@current_last).empty?)
  end

  def slug_references
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)

    having_reference_posts_page(@issue)
  end

  def create
    @issue.members.build(user: current_user, is_organizer: true)
    @issue.group_slug = Group.default_slug(current_group)
    @issue.strok_by(current_user)

    if @issue.save
      redirect_to smart_issue_home_url(@issue)
    else
      render 'new'
    end
  end

  def update
    @issue.assign_attributes(issue_params)
    if @issue.group_slug_changed? and !current_user.admin?
      flash[:notice] = t('unauthorized.default')
      render 'edit' and return
    end

    ActiveRecord::Base.transaction do
      if params[:issue].has_key?(:organizer_nicknames)
        organizer_nicknames = (@issue.organizer_nicknames.try(:split, ",") || []).map(&:strip).uniq.compact
        organizer_nicknames.each do |nickname|
          user = User.find_by(nickname: nickname)
          member = @issue.members.find_by(user: user)
          next if user.blank? or member.blank?
          member.update_attributes(is_organizer: true)
        end
        @issue.organizer_members.each do |member|
          member.update_attributes(is_organizer: false) unless organizer_nicknames.include? member.user.nickname
        end
      end
      if params[:issue].has_key?(:blinds_nickname)
        @issue.blinds.destroy_all
        (@issue.blinds_nickname.split(",") || []).map(&:strip).compact.uniq.each do |nickname|
          user = User.find_by(nickname: nickname)
          if user.present?
            @issue.blinds.build(user: user)
          end
        end
      end
      if @issue.save
        MessageService.new(@issue, sender: current_user).call
        redirect_to smart_issue_home_url(@issue)
      else
        errors_to_flash @issue
        render 'edit'
      end
    end
  end

  def destroy
    if @issue.deletable_by? current_user
      ActiveRecord::Base.transaction do
        @issue.destroy
        Message.where(messagable: @issue.members_with_deleted).destroy_all
      end
      redirect_to root_path
    else
      flash[:error] = t('errors.messages.not_deletable_parti')
      redirect_to smart_issue_home_url(@issue)
    end
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
    if params[:last_time].blank?
      @count = 0
    else
      @issue = Issue.find(params[:issue_id])
      @countable_issues = @issue.posts.next_of_time(params[:last_time])
      @countable_issues = @countable_issues.where.not(last_stroked_user: current_user) if user_signed_in?
      @count = @countable_issues.count
    end

    render 'posts/new_posts_count'
  end

  private

  def fetch_issue_by_slug
    @issue = Issue.only_group(current_group).find_by slug: params[:slug]
    if @issue.blank?
      @issue_by_title = Issue.only_group(current_group).find_by(title: params[:slug].titleize)
      if @issue_by_title.present?
        redirect_to @issue_by_title and return
      else
        render_404 and return
      end
    end
  end

  def issue_params
    params.require(:issue).permit(:title, :body, :logo, :cover, :slug, :basic,
      :organizer_nicknames, :blinds_nickname, :telegram_link, :tag_list, :category_slug,
      :private, :notice_only, :is_default, :group_slug)
  end

  def prepare_issue_meta_tags
    prepare_meta_tags title: meta_issue_title(@issue),
                      description: (@issue.body.presence || "#{@issue.title} | 민주적 협력 커뮤니티 플랫폼 '빠띠'"),
                      image: @issue.logo_url
  end

  def verify_issue_group
    verify_group(@issue)
  end

  def private_blocked?(issue)
    issue.private_blocked?(current_user) and !current_user.try(:admin?)
  end
end
