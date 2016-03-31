class MessageService
  attr_accessor :source

  def initialize(source)
    @source = source
  end

  def call
    case @source.class.to_s
    when Mention.to_s
      send_message(@source.user)
    when Upvote.to_s
      unless @source.comment.upvotes.includes(:messages).where(messages: {user: @source.user}).exists?
        send_message(@source.comment.user)
      end
    when Comment.to_s
      @source.post.messablable_users.each do |user|
        next if user == @source.user
        send_message(user)
      end
    end
  end

  private

  def send_message(user)
    user.messages.create(messagable: @source)
  end
end
