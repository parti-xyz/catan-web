class Front::PagesController < Front::BaseController
  def root
    redirect_to front_all_path
  end

  def all
    if user_signed_in?
      current_user.update_attributes(last_visitable: current_group)
    end

    @issues = current_group.issues.accessible_only(current_user).sort_by_name.includes(:folders, :category)
    @posts = Post.where(issue: @issues)
      .never_blinded(current_user)
      .includes(:user, :poll, :survey, :current_user_comments, :current_user_upvotes, :last_stroked_user, :issue, :folder, wiki: [ :last_wiki_history ])
      .order(last_stroked_at: :desc)
      .page(params[:page]).per(10)
    front_search_q = params.dig(:front_search, :q)
    if front_search_q.present?
      search_q = PostSearchableIndex.sanitize_search_key front_search_q
      @posts = @posts.search(search_q)
    end
    @posts.load if @current_issue.present?

    if session[:front_last_visited_post_id].present?
      @current_post = Post.find_by(id: session[:front_last_visited_post_id])
    end
    @scroll_persistence_id_ext = "root-#{current_group.id}"
    @scroll_persistence_tag = params[:page].presence || 1
  end

  def search
    @posts = Post.of_group(current_group)
      .never_blinded(current_user)
      .includes(:user, :poll, :survey, :current_user_comments, :current_user_upvotes, :last_stroked_user, :issue, :folder, wiki: [ :last_wiki_history ])
      .order(last_stroked_at: :desc)
      .page(params[:page]).per(10)
    @posts = @posts.of_searchable_issues(current_user)

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

  # DEPRECATED
  def global_sidebar
    @groups = current_user&.member_groups || Group.none
    render layout: false
  end

  def group_sidebar
    @current_issue = Issue.includes(:folders).find_by(id: params[:issue_id])
    @current_folder = @current_issue.folders.find(params[:folder_id]) if @current_issue.present? && params[:folder_id].present?
    @issues = current_group.issues.accessible_only(current_user).sort_by_name.includes(:folders, :category)
    @categorised_issues = @issues.to_a.group_by{ |issue| issue.category }.sort_by{ |category, issues| Category.default_compare_values(category) }

    render layout: false
  end

  def supplementary
    render layout: false
  end
end
