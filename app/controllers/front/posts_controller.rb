class Front::PostsController < Front::BaseController
  def show
    @current_post = Post.with_deleted
      .includes(:issue, :user, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, comments: [ :user, :file_sources ], wiki: [ :last_wiki_history], poll: [ :current_user_voting ] )
      .find(params[:id])
    @current_issue = Issue.with_deleted.find(@current_post.issue_id)
    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]

    if user_signed_in?
      @current_post.read!(@current_user)
      @current_issue.read_if_no_unread_posts!(@current_user)
    end

    session[:front_last_visited_post_id] = @current_post.id
    @scroll_persistence_id_ext = "post-#{@current_post.id}"
  end

  def new
    @current_issue = Issue.with_deleted.find(params[:issue_id])
    @current_folder = @current_issue.folders.find_by(id: params[:folder_id])
  end

  def edit
    @current_post = Post.with_deleted
      .includes(:issue, :user, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, comments: [ :user, :file_sources ], wiki: [ :last_wiki_history], poll: [ :current_user_voting ] )
      .find(params[:id])
    @current_issue = Issue.with_deleted.find(@current_post.issue_id)
    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]
  end
end
