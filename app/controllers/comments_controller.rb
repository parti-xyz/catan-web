class CommentsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :post
  load_and_authorize_resource :comment, through: :post, shallow: true

  def create
    set_choice
    @comment.user = current_user
    if @comment.save
      @comment.perform_mentions_async
    end
    @comments_count = @comment.post.comments_count
    respond_to do |format|
      format.js
      format.html { redirect_to_origin }
    end
  end

  def update
    unless params[:cancel]
      @comment.assign_attributes(comment_params)
      if @comment.save
        @comment.perform_mentions_async
      else
        if @comment.errors.any?
          errors_to_flash(@comment)
          @comment.reload
        else
          return head(:internal_server_error)
        end
      end
    end
  end

  def destroy
    @comment.destroy!
  end

  private

  def redirect_to_origin
    redirect_to @comment.post
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def set_choice
    @voting = @comment.post.voting_by current_user
    @comment.choice = @voting.try(:choice)
  end

end
