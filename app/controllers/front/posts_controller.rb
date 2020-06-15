class Front::PostsController < Front::BaseController
  def show
    @current_post = Post.includes(:issue, :user, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, :stroked_post_users, comments: [ :user, :file_sources, :current_user_upvotes ], wiki: [ :last_wiki_history], poll: [ :current_user_voting ] )
      .find(params[:id])

    @current_issue = Issue.includes(:folders, :current_user_issue_reader, :posts_pinned, organizer_members: [:user]).find(@current_post.issue_id)
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]

    if user_signed_in?
      @current_post.read!(@current_user)
      @current_issue.read!(@current_user)
    end

    session[:front_last_visited_post_id] = @current_post.id
    @scroll_persistence_id_ext = "post-#{@current_post.id}"

    if @current_post.stroked_post_users.empty?
      StrokedPostUserJob.perform_async(@current_post.id)
    end

    @supplementary_locals = prepare_channel_supplementary(@current_issue)
  end

  def new
    @current_issue = Issue.includes(:posts_pinned, organizer_members: [:user]).find(params[:issue_id])
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_issue.folders.find_by(id: params[:folder_id])

    @supplementary_locals = prepare_channel_supplementary(@current_issue)
  end

  def edit
    @current_post = Post
      .includes(:issue, :user, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, comments: [ :user, :file_sources, :current_user_upvotes ], wiki: [ :last_wiki_history], poll: [ :current_user_voting ] )
      .find(params[:id])

    @current_issue = Issue.includes(:posts_pinned, organizer_members: [:user]).find(@current_post.issue_id)
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]

    @supplementary_locals = prepare_channel_supplementary(@current_issue)
  end

  def destroyed
    @current_post = Post.only_deleted.find(params[:id])

    @current_issue = Issue.find(@current_post.issue_id)
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]
  end
end
