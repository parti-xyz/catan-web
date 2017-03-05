class MessageService
  attr_accessor :source

  def initialize(source, sender: nil, action: nil)
    @source = source
    @sender = sender
    @action = action
  end

  def call(options = {})
    @options = options
    case @source.class.to_s
    when Upvote.to_s
      send_messages(
        sender: @source.user, users: [@source.upvotable.user],
        messagable: @source)
    when Comment.to_s
      return if @source.issue.blind_user? @source.user

      previous_mentioned_users = @options[:previous_mentioned_users] || []

      @source.mentions.each do |mention|
        next if previous_mentioned_users.include?(mention.user)
        send_messages(
          sender: mention.mentionable.user, users: [mention.user],
          messagable: mention.mentionable)
      end

      users = @source.post.messagable_users.reject{ |user| user == @source.user }
      users = users - @source.messages.map(&:user)
      send_messages(
        sender: @source.user, users: users,
        messagable: @source)
    when Post.to_s
      return if @source.issue.blind_user? @source.user

      previous_mentioned_users = @options[:previous_mentioned_users] || []

      @source.mentions.each do |mention|
        next if previous_mentioned_users.include?(mention.user)
        send_messages(
          sender: mention.mentionable.user, users: [mention.user],
          messagable: mention.mentionable)
      end
    when Issue.to_s
      if @source.previous_changes["title"].present?
        users = @source.member_users.where.not(id: @sender.id)
        send_messages(
          sender: @sender, users: users, messagable: @source,
          action: :edit_title, action_params: { previous_title: @source.previous_changes["title"][0] })
      end
    when Member.to_s
      users = @source.joinable.makers.map &:user
      send_messages(
        sender: @source.user, users: users,
        messagable: @source, action: :create)
    when Invitation.to_s
      send_messages(
        sender: @source.user, users: [@source.recipient],
        messagable: @source)
    when MemberRequest.to_s
      if @source.deleted?
        send_messages(
          sender: @sender, users: [@source.user],
          messagable: @source,
          action: @action)
      else
        users = @source.joinable.makers.map &:user
        send_messages(
          sender: @source.user, users: users,
          messagable: @source,
          action: :request)
      end
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

