class MessageService
  attr_accessor :source

  def initialize(source)
    @source = source
  end

  def call
    case @source.class.to_s
    when Mention.to_s
      send_message(@source.user, @source.mentionable)
    when Upvote.to_s
      send_message(@source.comment.user, @source)
    when Comment.to_s
      @source.post.messagable_users.each do |user|
        next if user == @source.user
        send_message(user, @source)
      end
    end
  end

  private

  def send_message(user, messagable)
    user.messages.find_or_create_by(messagable: messagable, user: user)
  end
end
