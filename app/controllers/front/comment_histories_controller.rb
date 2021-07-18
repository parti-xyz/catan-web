class Front::CommentHistoriesController < Front::BaseController
  def index
    @comment = Comment.find(params[:comment_id])
    @comment_histories = @comment.comment_histories.includes(:user).recent.significant.limit(10)

    render layout: nil
  end

  def show
    @comment_history = CommentHistory.includes(:comment, :user).find(params[:id])

    render layout: nil
  end
end