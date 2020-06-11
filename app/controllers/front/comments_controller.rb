class Front::CommentsController < Front::BaseController
  def edit
    @current_comment = Comment.includes(:user, :file_sources, post: [ issue: [ :folders ]])
      .find(params[:id])
    authorize! :update, @current_comment

    @current_folder = @current_comment.post.issue.folders.to_a.find{ |f| f.id == params[:folder_id].to_i } if params[:folder_id].present?

    render partial: 'front/posts/show/comment/form', locals: { current_comment: @current_comment, current_post: @current_comment.post, current_folder: @current_folder }, layout: nil
  end
end