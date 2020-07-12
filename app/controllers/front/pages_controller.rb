class Front::PagesController < Front::BaseController
  def root
    redirect_to front_coc_path
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

    @posts = current_group_accessible_only_posts
      .includes(:user, :poll, :survey, :current_user_comments, :current_user_upvotes, :last_stroked_user, :folder, wiki: [ :last_wiki_history ], issue: [ :current_user_issue_reader ])
      .order(last_stroked_at: :desc)
      .page(params[:page]).per(10)

    param_q = params.dig(:front_search, :q)
    if param_q.present?
      @search_q = PostSearchableIndex.sanitize_search_key param_q
      @posts = @posts.search(@search_q)
      @posts.load

      @all_posts_total_count = @posts.total_count
    else
      @all_posts_total_count = @posts.total_count

      if params.dig(:filter, :condition) == 'needtoread' && user_signed_in?
        @posts = @posts.need_to_read_only(current_user)
      end
      @posts.load
    end
    @need_to_read_count = current_group_accessible_only_posts.need_to_read_only(current_user).count

    if session[:front_last_visited_post_id].present?
      @current_post = Post.find_by(id: session[:front_last_visited_post_id])
    end
    @scroll_persistence_id_ext = "root-#{current_group.id}"
    @scroll_persistence_tag = params[:page].presence || 1

    @group_sidebar_menu_slug = 'all'

    @permited_params = params.permit(:sort, :q, filter: [ :condition, :label_id ]).to_h

    @list_nav_params = list_nav_params(action: 'all', issue: nil, folder: nil, q: @search_q.presence, page: params[:page].presence, sort: params[:sort].presence, filter: params[:filter].presence)
  end

  def search
    if params[:issue_id].present?
      turbolinks_redirect_to front_channel_path(front_search: { q: params.dig(:front_search, :q) }, id: params[:issue_id])
    else
      turbolinks_redirect_to front_all_path(front_search: { q: params.dig(:front_search, :q) })
    end
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

  def read_all_posts
    render_403 and return unless user_signed_in?
    render_403 and return unless current_group.member?(current_user)

    outcome = GroupReadAllPosts.run(user_id: current_user.id, group_id: current_group.id, limit: 100)

    if outcome.valid?
      flash[:notice] = I18n.t('activerecord.successful.messages.completed')
    elsif outcome.errors.details.key?(:limit)
      flash[:notice] = '게시물 읽음 표시를 진행 중입니다. 잠시 후에 완료됩니다.'

      GroupReadAllPostsJob.perform_async(current_user.id, params[:id])
    else
      flash[:alert] = I18n.t('errors.messages.unknown')
    end

    turbolinks_redirect_to front_all_path
  end

  private

  def group_sidebar_content
    @current_issue = Issue.includes(:folders, :labels, :current_user_issue_reader).find_by(id: params[:issue_id])
    @current_folder = @current_issue.folders.find(params[:folder_id]) if @current_issue.present? && params[:folder_id].present?
    @issues = current_group.issues.includes(:folders, :labels, :current_user_issue_reader).accessible_only(current_user).sort_default.includes(:folders, :category)
    @categorised_issues = @issues.to_a.group_by{ |issue| issue.category }.sort_by{ |category, issues| Category.default_compare_values(category) }
  end

  def current_group_accessible_only_posts
    Post.where(issue: current_group_accessible_only_issues)
      .never_blinded(current_user)
  end

  def current_group_accessible_only_issues
    current_group.issues.accessible_only(current_user)
  end
end
