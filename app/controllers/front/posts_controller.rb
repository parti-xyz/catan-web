class Front::PostsController < Front::BaseController
  def show
    @current_post = Post.includes(:issue, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, :label, user: [ :current_group_member ], comments: [ :file_sources, :current_user_upvotes, user: [ :current_group_member ] ], wiki: [ :last_wiki_history ], poll: [ :current_user_voting ] )
      .find(params[:id])

    @current_issue = Issue.includes(:folders, :current_user_issue_reader, :posts_pinned, organizer_members: [ user: [ :current_group_member ] ]).find(@current_post.issue_id)
    render_403 and return if @current_issue&.private_blocked?(current_user)

    if user_signed_in?
      @post_reader = @current_post.read!(@current_user)
      @current_issue.read!(@current_user)

      updated_at_previous = @post_reader&.updated_at_previous_change&.first
      if updated_at_previous.present?
        @updated_comments = @current_post.comments.to_a.select do |comment|
          comment.user != current_user && comment.created_at > updated_at_previous
        end.sort_by do |comment|
          comment.created_at
        end
      end
    end

    if @updated_comments.nil? || @updated_comments&.empty?
      sorted_comments = @current_post.comments.select do |comment|
        comment.user != current_user
      end.sort_by do |comment|
        comment.created_at
      end

      last_comment = sorted_comments[-1]

      if last_comment.present?
        @recent_comments = sorted_comments.select do |comment|
          comment.created_at > (last_comment.created_at - 1.days)
        end
      end

      @recent_comments = [last_comment] if @recent_comments&.count == sorted_comments&.count
    end

    if @current_post.wiki.present?
      @wiki_histories = @current_post.wiki.wiki_histories.recent.page(1)

      if params[:wiki_history_id].present?
        @current_wiki_history = @current_post.wiki.wiki_histories.find_by(id: params[:wiki_history_id])
      end
    end

    session[:front_last_visited_post_id] = @current_post.id
    @scroll_persistence_id_ext = "post-#{@current_post.id}"

    if @current_post.stroked_post_users.empty?
      StrokedPostUserJob.perform_async(@current_post.id)
    end

    @supplementary_locals = prepare_channel_supplementary(@current_issue)
    @supplementary_locals[:default_force] = 'hide' if @updated_comments&.any? || @recent_comments&.any?

    @list_nav_params = list_nav_params()
  end

  def new
    render_403 and return unless user_signed_in?
    @current_issue = Issue.includes(:folders, :posts_pinned, organizer_members: [ user: [ :current_group_member ] ]).find(params[:issue_id])
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_issue.folders.find_by(id: params[:folder_id])

    @supplementary_locals = prepare_channel_supplementary(@current_issue)

    @list_nav_params = list_nav_params(folder: @current_folder)
  end

  def edit
    render_403 and return unless user_signed_in?

    @current_post = Post
      .includes(:user, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, issue: [ :folders ], comments: [ :user, :file_sources, :current_user_upvotes ], wiki: [ :last_wiki_history], poll: [ :current_user_voting ] )
      .find(params[:id])
    authorize! :update, (@current_post.wiki.presence || @current_post)

    @current_issue = Issue.includes(:folders, :posts_pinned, organizer_members: [ user: [ :current_group_member ] ]).find(@current_post.issue_id)

    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]

    @supplementary_locals = prepare_channel_supplementary(@current_issue)

    @list_nav_params = list_nav_params()
  end

  def edit_title
    render_403 and return unless user_signed_in?

    @current_post = Post.includes(:label, :issue).find(params[:id])
    authorize! :front_update_title, @current_post

    render layout: nil
  end

  def update_title
    render_403 and return unless user_signed_in?

    @current_post = Post.includes(:label, :wiki).find(params[:id])
    authorize! :front_update_title, @current_post

    if current_user != @current_post.user
      @current_post.last_title_edited_user = current_user
    end

    @current_post.strok_by(current_user)
    @current_post.base_title = params[:post][:base_title]
    @current_post.label_id = params[:post][:label_id]
    if @current_post.save
      @current_post.read!(current_user)

      flash.now[:notice] = I18n.t('activerecord.successful.messages.created')
      @current_post.issue.strok_by!(current_user, @current_post)
    else
      flash.now[:alert] = I18n.t('errors.messages.unknown')
    end

    render layout: nil
  end

  def update_label
    render_403 and return unless user_signed_in?

    @current_post = Post.find(params[:id])
    authorize! :front_update_label, @current_post

    @current_post.strok_by(current_user)
    @current_post.label_id = params[:label_id]
    if @current_post.save
      @current_post.read!(current_user)

      flash.now[:notice] = I18n.t('activerecord.successful.messages.created')
      @current_post.issue.strok_by!(current_user, @current_post)
    else
      flash.now[:alert] = I18n.t('errors.messages.unknown')
    end

    head 204
  end

  def cancel_title_form
    @current_post = Post.includes(:label, :wiki).find(params[:id])
    authorize! :front_update_title, @current_post

    render layout: nil
  end

  def destroyed
    @current_post = Post.only_deleted.find(params[:id])

    @current_issue = Issue.includes(:posts_pinned, organizer_members: [ user: [ :current_group_member ] ]).find(@current_post.issue_id)
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]

    @supplementary_locals = prepare_channel_supplementary(@current_issue)

    @list_nav_params = list_nav_params()
  end

  def edit_channel
    @current_post = Post.includes(:issue).find(params[:id])
    authorize! :move_to_issue, @current_post

    @issues = current_group.issues.includes(:category).sort_default

    render layout: nil
  end

  def update_channel
    issue_id = params[:post][:issue_id]
    render_404 and return if issue_id.blank?

    @current_post = Post.includes(:issue).find(params[:id])
    authorize! :move_to_issue, @current_post

    redirect_back(fallback_location: smart_front_post_url(@current_post)) and return if @current_post.issue_id.to_s == issue_id.strip

    @current_post.strok_by(current_user)
    @current_post.assign_attributes(issue_id: issue_id, folder: nil)

    if @current_post.save
      @current_post.upvotes.update_all(issue_id: issue_id)
      Upvote.where(upvotable: @current_post.comments).update_all(issue_id: issue_id)

      flash[:notice] = I18n.t('activerecord.successful.messages.completed')
    else
      flash[:alert] = I18n.t('errors.messages.unknown')
    end

    turbolinks_redirect_to smart_front_post_url(@current_post)
  end
end
