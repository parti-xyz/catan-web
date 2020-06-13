class Front::ChannelsController < Front::BaseController
  def show
    @current_issue = Issue.includes(:folders, :current_user_issue_reader).find(params[:id])
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?

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

  def post_folder_field
    @current_issue = Issue.includes(:folders).find(params[:id])
    render_403 and return if @current_issue&.private_blocked?(current_user)

    if params[:folder_id].present?
      if params[:folder_id].starts_with?('new#')
        parent_id = params[:folder_id].gsub(/new#/, '')
        if parent_id.present?
          @parent_folder = @current_issue.folders.to_a.find{ |f| f.id == parent_id.to_i }
        end
        @new_form = true
      end
    end

    @current_folder = @current_issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i }

    render layout: false
  end

  def destroy_form
    @current_issue = Issue.includes(:folders).find(params[:id])
    authorize! :destroy, @current_issue

    @current_folder = @current_issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?
  end

  def sync
    render_404 and return unless user_signed_in?

    @issues = current_group.issues.accessible_only(current_user)
    respond_to do |format|
      format.json
    end
  end
end
