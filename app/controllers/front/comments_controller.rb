class Front::CommentsController < Front::BaseController
  def edit
    @current_comment = Comment.includes(:user, :file_sources, post: [ issue: [ :folders ]])
      .find(params[:id])
    authorize! :update, @current_comment

    if @current_comment.issue.blank? or private_blocked?(@current_comment.issue)
      render_404 and return
    end

    unless @current_comment.issue.commentable? current_user
      render_403 and return
    end

    @current_folder = @current_comment.post.issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?

    render partial: 'front/posts/show/comment/form', locals: { current_comment: @current_comment, current_post: @current_comment.post, current_folder: @current_folder }, layout: nil
  end

  private

  def private_blocked?(issue)
    return true if issue.blank?
    issue.private_blocked?(current_user)
  end
end