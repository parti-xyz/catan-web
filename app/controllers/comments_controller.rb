class CommentsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :post
  load_and_authorize_resource :comment, through: :post, shallow: true

  def create
    set_choice
    @comment.user = current_user
    @comment.save
    @comments_count = @comment.post.comments_count
    respond_to do |format|
      format.js
      format.html { redirect_to_origin }
    end
  end

  def update
    unless params[:cancel]
      ActiveRecord::Base.transaction do
        @comment.assign_attributes(comment_params)
        unless @comment.save
          if @comment.errors.any?
            errors_to_flash(@comment)
            @comment.reload
          else
            return head(:internal_server_error)
          end
        end
      end
    end
  end

  def destroy
    @comment.destroy!
  end

  private

  def redirect_to_origin
    redirect_to @comment.post.specific.specific_origin
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def set_choice
    if @comment.post.specific.respond_to? :vote_by
      @vote = @comment.post.specific.vote_by current_user
      @comment.choice = @vote.try(:choice)
    end
  end

end
