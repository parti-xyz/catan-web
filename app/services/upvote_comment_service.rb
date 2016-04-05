class UpvoteCommentService

  attr_accessor :issue
  attr_accessor :current_user

  def initialize(comment:, current_user:)
    @comment = comment
    @current_user = current_user
  end

  def call
    upvote = @comment.upvotes.build(user: @current_user)
    upvote.save
    upvote
  end
end
