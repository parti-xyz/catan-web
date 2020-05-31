class FrontController < ApplicationController
  layout 'front'
  before_action :setup_turbolinks_root
  before_action :check_group, exclude: %i(navbar channel_listings)

  def root
    if user_signed_in?
      current_user.update_attributes(last_visitable: current_group)
    end
  end

  def search
    @posts = Post.of_group(current_group)
      .never_blinded(current_user)
      .includes(:user, :poll, :survey, :current_user_comments, :current_user_upvotes, :last_stroked_user, :issue, :folder, wiki: [ :last_wiki_history ])
      .order(last_stroked_at: :desc)
      .page(params[:page]).per(10)
    @posts = @posts.of_searchable_issues(current_user) if user_signed_in?

    front_search_q = params.dig(:front_search, :q)
    if front_search_q.present?
      search_q = PostSearchableIndex.sanitize_search_key front_search_q
      @posts = @posts.search(search_q)
    end
    @posts.load if @current_issue.present?

    if session[:front_last_visited_post_id].present?
      @current_post = Post.find_by(id: session[:front_last_visited_post_id])
    end

    @scroll_persistence_id_ext = "search-#{front_search_q}"
    @scroll_persistence_tag = params[:page].presence || 1
  end

  def channel
    @current_issue = Issue.with_deleted.includes(:folders).find(params[:issue_id])
    @thread_folders = Folder.threaded(@current_issue.folders)
    @current_folder = @current_issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?

    if !@current_issue.deleted? and !@current_issue&.private_blocked?(current_user)
      @posts = @current_issue.posts
        .never_blinded(current_user)
        .includes(:user, :poll, :survey, :current_user_comments, :current_user_upvotes, :last_stroked_user, :issue, :folder, wiki: [ :last_wiki_history ])
        .order(last_stroked_at: :desc)
        .page(params[:page]).per(10)
      if @current_folder.present?
        @posts = @posts.where(folder: @current_folder)
      end
      front_search_q = params.dig(:front_search, :q)
      if front_search_q.present?
        search_q = PostSearchableIndex.sanitize_search_key front_search_q
        @posts = @posts.search(search_q)
      end
      @posts.load if @current_issue.present?
    end

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
    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]

    @referrer_backable = request.referer.present? &&
      (request.domain.end_with?(Addressable::URI.parse(request.referer).domain) ||
      Addressable::URI.parse(request.referer).domain.end_with?(request.domain)) &&
      (Addressable::URI.parse(request.referer).path != front_post_path(@current_post, folder_id: @current_folder) &&
      (session[:front_last_visited_post_id].blank? ||
      Addressable::URI.parse(request.referer).path != front_post_path(post_id: session[:front_last_visited_post_id], folder_id: @current_folder)))

    if user_signed_in?
      @current_post.read!(@current_user)
      @current_issue.read_if_no_unread_posts!(@current_user)
    end

    session[:front_last_visited_post_id] = @current_post.id
    @scroll_persistence_id_ext = "post-#{@current_post.id}"
  end

  def new_post
    @current_issue = Issue.with_deleted.find(params[:issue_id])
    @current_folder = @current_issue.folders.find_by(id: params[:folder_id])

    @referrer_backable = request.referer.present? &&
      URI(request.referer).path == front_channel_path(issue_id: @current_issue.id)
  end

  def edit_post
    @current_post = Post.with_deleted
      .includes(:issue, :user, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, comments: [ :user, :file_sources ], wiki: [ :last_wiki_history], poll: [ :current_user_voting ] )
      .find(params[:post_id])
    @current_issue = Issue.with_deleted.find(@current_post.issue_id)
    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]
  end

  def channel_supplementary
    @current_issue = Issue.with_deleted.includes(:folders).find(params[:issue_id])

    if session[:front_last_visited_post_id].present?
      @current_post = Post.find_by(id: session[:front_last_visited_post_id])
    end

    @pinned_posts = @current_issue.posts.pinned
      .includes(:poll, :survey, :wiki)
      .order('pinned_at desc').load

    render layout: false
  end

  # DEPRECATED
  def global_sidebar
    @groups = current_user&.member_groups || Group.none
    render layout: false
  end

  def channel_listings
    @current_issue = Issue.find_by(id: params[:issue_id])
    @current_folder = @current_issue.folders.find(params[:folder_id]) if @current_issue.present? && params[:folder_id].present?
    @issues = current_group.issues.includes(:folders).where(id: current_user&.member_issues&.alive).sort_by_name
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
