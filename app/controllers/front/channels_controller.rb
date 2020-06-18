class Front::ChannelsController < Front::BaseController
  def show
    @current_issue = Issue.includes(:folders, :current_user_issue_reader, :posts_pinned, organizer_members: [:user]).find(params[:id])
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?

    @posts = @current_issue.posts
      .never_blinded(current_user)
      .includes(:user, :poll, :survey, :current_user_comments, :current_user_upvotes, :last_stroked_user, :issue, :folder, wiki: [ :last_wiki_history ])
      .page(params[:page]).per(10)
    if @current_folder.present?
      @posts = @posts.where(folder: @current_folder)
    end

    @issue_reader = @current_issue.issue_reader!(@current_user, params[:sort])
    column_name = { 'stroked' => 'last_stroked_at', 'created' => 'created_at' }[@issue_reader.sort]
    @posts = @posts.order(column_name => :desc)

    front_search_q = params.dig(:front_search, :q)
    if front_search_q.present?
      search_q = PostSearchableIndex.sanitize_search_key front_search_q
      @posts = @posts.search(search_q)

      @posts.load
      @posts_total_count = @posts.total_count
    else
      @posts_total_count = @posts.total_count
      if params[:filter] == 'needtoread' && user_signed_in?
        @posts = @posts.unread_only(current_user)
      end

      @posts.load
    end


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
    render_403 and return unless user_signed_in?

    @current_issue = Issue.includes(:folders).find(params[:id])
    authorize! :destroy, @current_issue

    @current_folder = @current_issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?
  end

  def sync
    render_403 and return unless user_signed_in?

    @issues = current_group.issues.accessible_only(current_user)
    respond_to do |format|
      format.json
    end
  end

  def read_all
    render_403 and return unless user_signed_in?
    return_403 unless current_group.member?(current_user)

    @current_issue = Issue.includes(:folders).find(params[:id])
    @current_issue.posts.unread_only(current_user).each do |post|
      post.read!(current_user)
    end
    @current_issue.read!(current_user)


    turbolinks_redirect_to smart_front_channel_url(@current_issue)
  end
end
