class IssuesController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :destroy, :remove_logo, :remove_cover]
  before_action :fetch_issue_by_slug, only: [:new_posts_count, :slug_home, :slug_members, :slug_links_or_files, :slug_polls_or_surveys, :slug_wikis]
  load_and_authorize_resource
  before_action :verify_issue_group, only: [:slug_home, :slug_links_or_files, :slug_polls_or_surveys, :slug_wikis, :edit]
  before_action :prepare_issue_meta_tags, only: [:show, :slug_home, :slug_links_or_files, :slug_polls_or_surveys, :slug_wikis, :slug_members]

  def root
    if current_group.blank?
      index
    else
      group_issues(current_group)
      @posts_pinned = current_group.pinned_posts(current_user)

      @polls_and_surveys = Post.having_poll.or(Post.having_survey).not_private_blocked_of_group(current_group, current_user)
      @polls_and_surveys = @polls_and_surveys.order_by_stroked_at.limit(7)
      @recent_posts = Post.not_in_dashboard_of_group(current_group, current_user).order_by_stroked_at.limit(4)
      if %w(union).include? current_group.slug
        render 'group_root_union'
      elsif %w(greenpartyjeju eduhope slowalk).include? current_group.slug
        render 'group_root_compact'
      elsif %w(youthmango).include? current_group.slug
        render 'group_root_parties_first'
      else
        render 'group_root'
      end
    end
  end

  def index
    if current_group.blank?
      if params[:keyword].present?
        params[:sort] ||= 'hottest'
        @issues = search_and_sort_issues(Issue.searchable_issues(current_user), params[:keyword], params[:sort])
      else
        @groups = Group.not_private_blocked(current_user)
        @groups = @groups.to_a.reject { |group| group.issues.count <= 0 }
      end

      render 'index'
    else
      group_issues(current_group, params[:category_slug])
      render 'group_index'
    end
  end

  def indies
    params[:sort] ||= 'hottest'
    @issues = search_and_sort_issues(Group.indie.issues.not_private_blocked(current_user), params[:keyword], params[:sort], 3)
  end

  def search_by_tags
    @issues = Issue.alive.only_public_in_current_group(current_group)
    if params[:selected_tags] == [""]
      @issues = @issues.hottest
      @no_tags_selected = 'yes'
    else
      @issues = @issues.tagged_with(params[:selected_tags], :any => true)
    end
    @issues = @issues.to_a.reject { |i| i.private_blocked?(current_user) }
  end

  def show
    @issue = Issue.find params[:id]
    redirect_to smart_issue_home_url(@issue)
  end

  def slug_home
    render 'slug_home_blocked' and return if private_blocked?(@issue)

    if params[:q].present?
      @search_q = PostSearchableIndex.sanitize_search_key params[:q]
    end

    if request.format.js?
      @previous_last_post = Post.with_deleted.find_by(id: params[:last_id])

      issue_posts = @issue.posts.order(last_stroked_at: :desc)
      issue_posts = issue_posts.search(@search_q) if @search_q.present?

      limit_count = ( @previous_last_post.blank? ? 5 : 25 )
      @posts = issue_posts.limit(limit_count).previous_of_post(@previous_last_post)

      current_last_post = @posts.last
      @is_last_page = (issue_posts.empty? or issue_posts.previous_of_post(current_last_post).empty?)
    end

    if params[:last_id].blank?
      @posts_pinned = @issue.posts.pinned.order('pinned_at desc')
    end
  end

  def slug_polls_or_surveys
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)
    @posts = Post.having_poll.or(Post.having_survey).of_issue(@issue).order_by_stroked_at.page(params[:page]).per(3*5)
  end

  def slug_wikis
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)
    @posts = Post.having_wiki(params[:status] || 'active').of_issue(@issue).order_by_stroked_at.page(params[:page]).per(3*5)
  end

  def slug_members
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)

    base = @issue.members.recent
    base = smart_search_for(base, params[:keyword], profile: (:admin if user_signed_in? and current_user.admin?)) if params[:keyword].present?
    @members = base.page(params[:page]).per(3 * 10)
  end

  def slug_links_or_files
    redirect_to smart_issue_home_path_or_url(@issue) and return if private_blocked?(@issue)
    @posts = Post.having_link_or_file.of_issue(@issue).order_by_stroked_at.page(params[:page]).per(3*5)
  end

  def create
    @issue.members.build(user: current_user, is_organizer: true)
    @issue.group_slug = Group.default_slug(current_group)
    @issue.strok_by(current_user)

    if @issue.save
      if @issue.is_default?
          IssueForceDefaultJob.perform_async(@issue.id, current_user.id)
        end
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
    @origin_issue = Issue.find(@issue.id)
    target_group = Group.find_by(slug: @issue.group_slug)
    if @issue.group_slug_changed? and !@issue.movable_to_group?(target_group)
      @target_group = target_group
      @out_of_member_users = @target_group.out_of_member_users(@issue.member_users)
      render 'warning_out_of_members_notice' and return
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
        if @issue.previous_changes["is_default"].present? and @issue.is_default?
          IssueForceDefaultJob.perform_async(@issue.id, current_user.id)
        end
        MessageService.new(@issue, sender: current_user).call
        redirect_to smart_issue_home_url(@issue)
      else
        errors_to_flash @issue
        render 'edit'
      end
    end
  end

  def destroy
    IssueDestroyJob.perform_async(current_user.id, @issue.id, params[:message])
    flash[:success] = t('views.started_issue_destroying')
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
    if params[:last_time].blank?
      @count = 0
    else
      @issue = Issue.find(params[:issue_id])
      @countable_issues = @issue.posts.next_of_time(params[:last_time])
      @countable_issues = @countable_issues.where.not(last_stroked_user: current_user) if user_signed_in?
      @count = @countable_issues.count
    end

    respond_to do |format|
      format.js { render 'posts/new_posts_count' }
    end
  end

  private

  def group_issues(group, category_slug = nil)
    @issues = Issue.displayable_in_current_group(group)
    @issues = @issues.hottest
    @issues = @issues.categorized_with(category_slug) if category_slug.present?
    @issues = @issues.to_a.reject { |issue| private_blocked?(issue) }
  end

  def search_and_sort_issues(issue, keyword, sort, item_a_row = nil)
    tags = (keyword.try(:split) || []).map(&:strip).reject(&:blank?)
    result = issue
    result = result.where.any_of(Issue.alive.search_for(keyword), Issue.alive.tagged_with(tags, any: true)) if keyword.present?

    case sort
    when 'recent'
      result = result.recent
    when 'name'
      result = result.sort_by_name
    when 'recent_touched'
      result = result.recent_touched
    else
      result = result.hottest
    end

    result = result.categorized_with(params[:category]) if params[:category].present?
    result = result.page(params[:page]).per(4 * 10)
    result.page(params[:page]).per(item_a_row * 10) if item_a_row.present?

    result
  end

  def fetch_issue_by_slug
    @issue = Issue.of_group(current_group).find_by slug: params[:slug]
    if @issue.blank?
      @issue_by_title = Issue.of_group(current_group).find_by(title: params[:slug].titleize)
      if @issue_by_title.present?
        redirect_to @issue_by_title and return
      else
        render_404 and return
      end
    end
  end

  def issue_params
    params.require(:issue).permit(:title, :body, :logo, :cover, :slug,
      :organizer_nicknames, :blinds_nickname, :telegram_link, :tag_list, :category_slug,
      :private, :notice_only, :is_default, :group_slug)
  end

  def prepare_issue_meta_tags
    prepare_meta_tags title: meta_issue_title(@issue),
                      description: (@issue.body.presence || "#{@issue.title} | 민주적 일상 커뮤니티 '빠띠'"),
                      image: @issue.logo_url
  end

  def verify_issue_group
    verify_group(@issue)
  end

  def private_blocked?(issue)
    issue.private_blocked?(current_user) and !current_user.try(:admin?)
  end
end
