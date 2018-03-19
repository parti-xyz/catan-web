class UpvotesController < ApplicationController
  before_action :authenticate_user!, except: [:users]
  load_and_authorize_resource :comment
  load_and_authorize_resource :post
  load_and_authorize_resource :upvote, through: [:comment, :post], shallow: true

  def create
    @upvote.user = current_user
    @upvote.save
    @upvote.upvotable.reload

    respond_to do |format|
      format.js
    end
  end

  def cancel
    @upvotable = (@comment || @post)
    @upvote = @upvotable.upvotes.find_by user: current_user
    @upvote.try(:destroy)
    @upvotable.reload

    respond_to do |format|
      format.js
    end
  end

  def users
    @upvotable = (@comment || @post)
    render layout: false
  end
end
