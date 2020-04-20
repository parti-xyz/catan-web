class Front::PagesController < ApplicationController
  layout 'front/pages'
  before_action :setup_turbolinks_root
  before_action :check_group, exclude: %i(navbar channel_listings)

  def root
  end

  def channel
    @current_issue = Issue.with_deleted.find(params[:issue_id])
    if !@current_issue.deleted? and !@current_issue&.private_blocked?(current_user)
      @posts = @current_issue.posts
        .never_blinded(current_user)
        .includes(:user, :poll, :survey, :current_user_comments, :current_user_upvotes, wiki: [ :last_wiki_history ])
        .order(last_stroked_at: :desc)
        .page(params[:page]).per(10) if @current_issue.present?
    end

    if session[:front_last_visited_post_id].present?
      @current_post = Post.find_by(id: session[:front_last_visited_post_id])
    end

    @scroll_persistence_id = "channel-#{@current_issue.id}-#{params[:page].presence || 1}"
  end

  def post
    @current_post = Post.with_deleted
      .includes(:user, :poll, :survey, :wiki, :current_user_comments, :current_user_upvotes)
      .find(params[:post_id])
    @current_issue = Issue.with_deleted.find(@current_post.issue_id)

    @referrer_backable = request.referer.present? &&
      URI(request.referer).path == front_channel_path(issue_id: @current_issue.id)

    session[:front_last_visited_post_id] = @current_post.id
  end

  def navbar
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
