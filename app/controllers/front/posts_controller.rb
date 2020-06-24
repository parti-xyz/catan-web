class Front::PostsController < Front::BaseController
  def show
    @current_post = Post.includes(:issue, :user, :survey, :current_user_upvotes, :last_stroked_user, :file_sources, comments: [ :user, :file_sources, :current_user_upvotes ], wiki: [ :last_wiki_history ], poll: [ :current_user_voting ] )
      .find(params[:id])

    @current_issue = Issue.includes(:folders, :current_user_issue_reader, :posts_pinned, organizer_members: [:user]).find(@current_post.issue_id)
    render_403 and return if @current_issue&.private_blocked?(current_user)

    @current_folder = @current_post.folder if @current_post.folder&.id&.to_s == params[:folder_id]

    if user_signed_in?
      @post_reader = @current_post.read!(@current_user)
      @current_issue.read!(@current_user)

      updated_at_previous = @post_reader.updated_at_previous_change&.first
      if updated_at_previous.present?
        @updated_comments = @current_post.comments.to_a.select do |comment|
          comment.user != current_user && comment.created_at > updated_at_previous
        end.sort_by do |comment|
          comment.created_at
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

        @recent_comments = [] if @recent_comments&.count == sorted_comments&.count
      end
    end

    session[:front_last_visited_post_id] = @current_post.id
    @scroll_persistence_id_ext = "post-#{@current_post.id}"

    if @current_post.stroked_post_users.empty?
      StrokedPostUserJob.perform_async(@current_post.id)
    end

    @supplementary_locals = prepare_channel_supplementary(@current_issue)
    @supplementary_locals[:default_force] = 'hide' if @updated_comments&.any? || @recent_comments&.any?
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

    @supplementary_locals = prepare_channel_supplementary(@current_issue)
  end

  def edit_folder
  end
end
