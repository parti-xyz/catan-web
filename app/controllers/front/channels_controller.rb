class Front::ChannelsController < Front::BaseController
  def show
    @current_issue = Issue.includes(:folders, :labels, :current_user_issue_reader, :posts_pinned, organizer_members: [ user: [ :current_group_member ] ]).find(params[:id])
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?

    @posts = @current_issue.posts
      .never_blinded(current_user)
      .includes(:user, :poll, :survey, :current_user_comments, :current_user_upvotes, :last_stroked_user, :label, :issue, :folder, wiki: [ :last_wiki_history ])
      .page(params[:page]).per(10)
    if @current_folder.present?
      @posts = @posts.where(folder: @current_folder)
    end

    @issue_reader = @current_issue.issue_reader!(@current_user, params[:sort])
    column_name = { 'stroked' => 'last_stroked_at', 'created' => 'created_at' }[@issue_reader.sort]
    @posts = @posts.order(column_name => :desc)

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
      if params.dig(:filter, :label_id).present?
        label_id = params.dig(:filter, :label_id)
        @label_q = Label.find_by(id: label_id)
        @posts = @posts.where(label: @label_q)
      end
      @posts.load
    end
    @need_to_read_count = @current_issue.posts.need_to_read_only(current_user).count

    if user_signed_in?
      current_user.update_attributes(last_visitable: @current_issue)
      @current_issue.read!(current_user)
    end

    if session[:front_last_visited_post_id].present?
      @current_post = Post.find_by(id: session[:front_last_visited_post_id])
    end
    @scroll_persistence_id_ext = "channel-#{@current_issue.id}"
    @scroll_persistence_tag = params[:page].presence || 1

    @supplementary_locals = prepare_channel_supplementary(@current_issue)

    @permited_params = params.permit(:id, :folder_id, :sort, :q, filter: [ :condition, :label_id ]).to_h

    @list_nav_params = list_nav_params(action: 'channel', issue: @current_issue, folder: @current_folder, q: @search_q.presence, page: params[:page].presence, sort: params[:sort].presence, filter: params[:filter].presence)
  end

  def new
    render_403 and return unless current_group.creatable_issue?(current_user)

    @current_category = current_group.categories.find_by(id: params[:category_id]) if params[:category_id].present?

    render layout: 'front/simple'
  end

  def edit
    @current_issue = Issue.includes(:folders).find(params[:id])
    authorize! :update, @current_issue

    @current_folder = @current_issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?
  end

  def destroy_form
    render_403 and return unless user_signed_in?

    @current_issue = Issue.includes(:folders).find(params[:id])
    authorize! :destroy, @current_issue

    @current_folder = @current_issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?
  end

  def sync
    head(204) and return if !user_signed_in? || !current_group.member?(current_user)


    @issues = current_group.issues.includes(:current_user_issue_reader).accessible_only(current_user).includes(:current_user_issue_reader, :group)
    respond_to do |format|
      format.json
    end
  end

  def read_all_posts
    render_403 and return unless user_signed_in?
    render_403 and reuurn unless current_group.member?(current_user)

    outcome = IssueReadAllPosts.run(user_id: current_user.id, issue_id: params[:id], limit: 100)

    if outcome.valid?
      flash[:notice] = I18n.t('activerecord.successful.messages.completed')
    elsif outcome.errors.details.key?(:limit)
      flash[:notice] = '게시물 읽음 표시를 진행 중입니다. 잠시 후에 완료됩니다.'

    IssueReadAllPostsJob.perform_async(current_user.id, params[:id])
    else
      Rails.logger.error outcome.errors.details.inspect
      flash[:alert] = I18n.t('errors.messages.unknown')
    end

    turbolinks_redirect_to front_channel_path(id: params[:id])
  end

  def labels
    render_403 and return unless user_signed_in?

    @current_issue = Issue.includes(:labels).find(params[:id])
    authorize! :labels, @current_issue
  end
end
