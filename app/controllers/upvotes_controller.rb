class UpvotesController < ApplicationController
  before_action :authenticate_user!, except: [:users]
  load_and_authorize_resource :comment
  load_and_authorize_resource :post
  load_and_authorize_resource :upvote, through: [:comment, :post], shallow: true

  def create
    @upvote.user = current_user
    @upvote.save
    @upvote.upvotable.reload

    if helpers.explict_front_namespace?
      @post ||= @comment&.post
      redirect_to front_post_url(@post, folder_id: (params[:folder_id] if @post.folder_id&.to_s == params[:folder_id])), turbolinks: :true
    else
      respond_to do |format|
        format.js
      end
    end
  end

  def cancel
    @upvotable = (@comment || @post)
    @upvote = @upvotable.upvotes.find_by user: current_user
    @upvote.try(:destroy)
    @upvotable.reload

    if helpers.explict_front_namespace?
      @post ||= @comment&.post
      redirect_to front_post_url(@post, folder_id: (params[:folder_id] if @post.folder_id&.to_s == params[:folder_id])), turbolinks: :true
    else
      respond_to do |format|
        format.js
      end
    end
  end

  def users
    @upvotable = (@comment || @post)

    if helpers.explict_front_namespace?
      render(partial: 'front/posts/show/upvotings/users', locals: { upvotable: @upvotable })
    else
      render layout: false
    end
  end
end
