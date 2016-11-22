class MessageService
  attr_accessor :source

  def initialize(source, sender: nil)
    @source = source
    @sender = sender
  end

  def call
    case @source.class.to_s
    when Mention.to_s
      send_messages(
        sender: @source.mentionable.user, users: [@source.user],
        messagable: @source.mentionable)
    when Upvote.to_s
      send_messages(
        sender: @source.user, users: [@source.upvotable.user],
        messagable: @source)
    when Comment.to_s
      return if @source.issue.blind_user? @source.user
      users = @source.post.messagable_users.reject{ |user| user == @source.user }
      send_messages(
        sender: @source.user, users: users,
        messagable: @source)
    when Issue.to_s
      if @source.previous_changes["title"].present?
        users = @source.member_users.where.not(id: @sender.id)
        send_messages(
          sender: @sender, users: users, messagable: @source,
          action: :edit_title, action_params: { previous_title: @source.previous_changes["title"][0] })
      end
    when Member.to_s
      users = @source.issue.makers.map &:user
      send_messages(
        sender: @source.user, users: users,
        messagable: @source, action: :create)
    when Invitation.to_s
      send_messages(
        sender: @source.user, users: [@source.recipient],
        messagable: @source)
    end
  end

  private

  def send_messages(sender:, users:, messagable:, action: nil, action_params: nil)
    data = users.map do |user|
      {messagable: messagable, sender: sender, user: user, action: action, action_params: action_params.try(:to_json)}
    end
    messages = Message.create(data)
    send_fcm(messages)
  end

  def send_fcm(messages)
    messages.each do |message|
      FcmJob.perform_async(message.id)
    end
  end
end

