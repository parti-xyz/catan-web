class UpvotesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :comment
  load_and_authorize_resource :post
  load_and_authorize_resource :upvote, through: [:comment, :post], shallow: true

  def create
    @upvote.user = current_user
    @upvote.save

    respond_to do |format|
      format.js
    end
  end

  def cancel
    @upvotable = (@comment || @post)
    @upvote = @upvotable.upvotes.find_by user: current_user
    @upvote.try(:destroy)

    respond_to do |format|
      format.js
    end
  end
end
