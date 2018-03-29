class MessageService
  attr_accessor :source

  def initialize(source, sender: nil, action: nil)
    @source = source
    @sender = sender
    @action = action
  end

  def call(options = {})
    @options = options
    case @source
    when Upvote
      send_messages(
        sender: @source.user, users: [@source.upvotable.user],
        messagable: @source)
    when Comment
      return if @source.issue.blind_user? @source.user
      messagable_users = []
      messagable_users += @source.mentions.map(&:user)
      messagable_users += @source.post.messagable_users.to_a
      messagable_users.reject!{ |user| user == @source.user }
      messagable_users.reject!{ |user| @source.messages.select(:user_id).map(&:user_id).include?(user.id) }
      messagable_users.uniq!

      send_messages(
        sender: @source.user, users: messagable_users,
        messagable: @source)
    when Post
      if @action == :pinned
        users = @source.issue.member_users.where.not(id: @sender)
        send_messages(
          sender: @sender, users: users,
          messagable: @source, action: @action)
      elsif @action == :decision
        return if @source.issue.blind_user? @source.user

        messagable_users = []
        messagable_users += @source.mentions.map(&:user)
        messagable_users += @source.messagable_users.to_a
        messagable_users.reject!{ |user| user == @sender }
        messagable_users.uniq!
        send_messages(
          sender: @sender, users: messagable_users,
          messagable: @source, action: @action, action_params: options)
      else
        return if @source.issue.blind_user? @source.user

        messagable_users = []
        messagable_users += @source.mentions.map(&:user)
        messagable_users.reject!{ |user| user == @source.user }
        messagable_users.reject!{ |user| @source.messages.select(:user_id).map(&:user_id).include?(user.id) }
        messagable_users.uniq!
        send_messages(
          sender: @source.user, users: messagable_users,
          messagable: @source)
      end
    when Issue
      if @source.previous_changes["title"].present?
        users = @source.member_users.where.not(id: @sender.id)
        send_messages(
          sender: @sender, users: users, messagable: @source,
          action: :edit_title, action_params: { previous_title: @source.previous_changes["title"][0] })
      end
    when Member
      if @action == :ban
        send_messages(
          sender: @sender, users: [@source.user],
          messagable: @source,
          action: @action)
      elsif @action == :admit
        send_messages(
          sender: @sender, users: [@source.user],
          messagable: @source,
          action: @action)
      elsif @action == :force_default
        send_messages(
          sender: @sender, users: [@source.user],
          messagable: @source,
          action: @action)
      elsif @action == :new_organizer
        send_messages(
          sender: @sender, users: [@source.user],
          messagable: @source,
          action: @action)

        if (@options[:old_organizer_members] || []).any?
          send_messages(
            sender: @sender,
            users: @options[:old_organizer_members].reject{ |member| member.user == @sender }.map(&:user),
            messagable: @source,
            action: :welcome_organizer,
            action_params: {
              new_organizer_user_id: @source.user.id,
              new_organizer_user_nickname: @source.user.nickname
            }
          )
        end
      else
        users = @source.joinable.organizer_members.map &:user
        send_messages(
          sender: @source.user, users: users,
          messagable: @source, action: :create)
      end
    when Invitation
      send_messages(
        sender: @source.user, users: [@source.recipient],
        messagable: @source)
    when MemberRequest
      if %i(accept cancel).include? @action
        send_messages(
          sender: @sender, users: [@source.user],
          messagable: @source,
          action: @action)
      else
        users = @source.joinable.organizer_members.map &:user
        send_messages(
          sender: @source.user, users: users,
          messagable: @source,
          action: @action)
      end
    when Option
      users = @source.survey.post.messagable_users.to_a.reject{ |user| user == @source.user }
      send_messages(
        sender: @source.user, users: users,
        messagable: @source)
    when Survey
      return if @source.post.blank?
      users = @source.post.messagable_users.to_a
      send_messages(
        sender: @source.post.user, users: users,
        messagable: @source, action: @action)
    end
  end

  private

  def send_messages(sender:, users:, messagable:, action: nil, action_params: nil)
    users.each do |user|
      row = { messagable: messagable, sender: sender, user: user, action: action, action_params: action_params.try(:to_json) }
      message = Message.create(row)
      FcmJob.perform_async(message.id)
    end
  end
end

