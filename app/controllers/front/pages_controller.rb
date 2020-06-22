class Front::PagesController < Front::BaseController
  def root
    redirect_to front_all_path
  end

  def menu
    group_sidebar_content
  end

  def search_form
    @current_issue = Issue.find_by(id: params[:issue_id])
  end

  def all
    if user_signed_in?
      current_user.update_attributes(last_visitable: current_group)
    end

    @issues = current_group.issues.accessible_only(current_user).sort_default.includes(:folders, :category)
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

    @group_sidebar_menu_slug = 'all'
  end

  def search
    if params[:issue_id].present?
      turbolinks_redirect_to front_channel_path(front_search: { q: params.dig(:front_search, :q) }, id: params[:issue_id])
      return
    end

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
    group_sidebar_content
    render layout: false
  end

  def coc
    @group_sidebar_menu_slug = 'coc'
  end

  private

  def group_sidebar_content
    @current_issue = Issue.includes(:folders, :current_user_issue_reader).find_by(id: params[:issue_id])
    @current_folder = @current_issue.folders.find(params[:folder_id]) if @current_issue.present? && params[:folder_id].present?
    @issues = current_group.issues.includes(:folders, :current_user_issue_reader).accessible_only(current_user).sort_default.includes(:folders, :category)
    @categorised_issues = @issues.to_a.group_by{ |issue| issue.category }.sort_by{ |category, issues| Category.default_compare_values(category) }
  end
end
