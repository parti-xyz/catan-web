class FrontController < ApplicationController
  layout 'front'
  before_action :setup_turbolinks_root
  before_action :check_group, exclude: %i(navbar channel_listings)

  def root
    if user_signed_in?
      current_user.update_attributes(last_visitable: current_group)
    end
  end

  def channel
    @current_issue = Issue.with_deleted.find(params[:issue_id])
    if !@current_issue.deleted? and !@current_issue&.private_blocked?(current_user)
      @posts = @current_issue.posts
        .never_blinded(current_user)
        .includes(:user, :poll, :survey, :current_user_comments, :current_user_upvotes, :last_stroked_user, wiki: [ :last_wiki_history ])
        .order(last_stroked_at: :desc)
        .page(params[:page]).per(10).load if @current_issue.present?
    end

    @pinned_posts = @current_issue.posts.pinned
      .includes(:poll, :survey, :wiki)
      .order('pinned_at desc').load

    if user_signed_in?
      current_user.update_attributes(last_visitable: @current_issue)
    end

    if session[:front_last_visited_post_id].present?
      @current_post = Post.find_by(id: session[:front_last_visited_post_id])
    end
    @scroll_persistence_id_ext = "channel-#{@current_issue.id}"
    @scroll_persistence_tag = params[:page].presence || 1
  end

  def post
    @current_post = Post.with_deleted
      .includes(:issue, :user, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, comments: [ :user, :file_sources ], wiki: [ :last_wiki_history], poll: [ :current_user_voting ] )
      .find(params[:post_id])
    @current_issue = Issue.with_deleted.find(@current_post.issue_id)

    @referrer_backable = request.referer.present? &&
      URI(request.referer).path == front_channel_path(issue_id: @current_issue.id)

    if user_signed_in?
      @current_post.read!(@current_user)
      @current_issue.read_if_no_unread_posts!(@current_user)
    end

    session[:front_last_visited_post_id] = @current_post.id
    @scroll_persistence_id_ext = "post-#{@current_post.id}"
  end

  def new_post
    @current_issue = Issue.with_deleted.find(params[:issue_id])

    @referrer_backable = request.referer.present? &&
      URI(request.referer).path == front_channel_path(issue_id: @current_issue.id)
  end

  def global_sidebar
    @groups = current_user&.member_groups || Group.none
    render layout: false
  end

  def channel_listings
    @current_issue = Issue.find_by(id: params[:issue_id])
    @issues = current_group.issues.where(id: current_user&.member_issues&.alive).sort_by_name
    render layout: false
  end

  private

  def check_group
    redirect_to(subdomain: Group.open_square.subdomain) and return if current_group.blank?
  end

  def setup_turbolinks_root
    @turbolinks_root = '/front'
  end
end
