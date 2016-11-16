class MessageService
  attr_accessor :source

  def initialize(source, sender: nil)
    @source = source
    @sender = sender
  end

  def call
    case @source.class.to_s
    when Mention.to_s
      send_message(sender: @source.mentionable.user, user: @source.user, messagable: @source.mentionable)
    when Upvote.to_s
      send_message(sender: @source.user, user: @source.upvotable.user, messagable: @source)
    when Comment.to_s
      return if @source.issue.blind_user? @source.user
      @source.post.messagable_users.each do |user|
        next if user == @source.user
        send_message(sender: @source.user, user: user, messagable: @source)
      end
    when Issue.to_s
      if @source.previous_changes["title"].present?
        @source.member_users.each do |user|
          next if user == @sender
          send_message(sender: @sender, user: user, messagable: @source,
            action: :edit_title, action_params: { previous_title: @source.previous_changes["title"][0] })
        end
      end
    when Member.to_s
      @source.issue.makers.each do |maker|
        send_message(sender: @source.user, user: maker.user, messagable: @source, action: :create)
      end
    when Invitation.to_s
      send_message(sender: @source.user, user: @source.recipient, messagable: @source)
    end
  end

  private

  def send_message(sender:, user:, messagable:, action: nil, action_params: nil)
    user.messages.find_or_create_by(messagable: messagable, sender: sender, action: action, action_params: action_params.try(:to_json))
  end

end
