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

      previous_message_user_ids = @source.messages.select(:user_id).map(&:user_id)

      mentioned_users = @source.mentions.map(&:user)
      mentioned_users.reject!{ |user| user == @source.user }
      mentioned_users.reject!{ |user| previous_message_user_ids.include?(user.id) }
      mentioned_users.uniq!

      send_messages(
        sender: @source.user, users: mentioned_users,
        messagable: @source, action: :mention)

      messagable_users = @source.post.messagable_users.to_a
      messagable_users.reject!{ |user| mentioned_users.map(&:id).include?(user.id) }
      messagable_users.reject!{ |user| user == @source.user }
      messagable_users.reject!{ |user| previous_message_user_ids.include?(user.id) }
      messagable_users.uniq!

      send_messages(
        sender: @source.user, users: messagable_users,
        messagable: @source)

      if @action == :create
        detail_messagable_users = @source.issue.detail_messagable_users
        detail_messagable_users = detail_messagable_users.where.not(id: @source.user)
        detail_messagable_users = detail_messagable_users.where.not(id: mentioned_users)
        detail_messagable_users = detail_messagable_users.where.not(id: messagable_users)
        detail_messagable_users = detail_messagable_users.where.not(id: previous_message_user_ids)
        send_messages(
          sender: @source.user, users: detail_messagable_users,
          messagable: @source, action: @action)
      end
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
        messagable_users += @source.issue.compact_messagable_users.to_a
        messagable_users.reject!{ |user| user == @sender }
        messagable_users.uniq!
        send_messages(
          sender: @sender, users: messagable_users,
          messagable: @source, action: @action, action_params: options)
      else
        return if @source.issue.blind_user? @source.user

        previous_message_user_ids = @source.messages.select(:user_id).map(&:user_id)

        mentioned_users = []
        mentioned_users += @source.mentions.map(&:user)
        mentioned_users.reject!{ |user| user == @source.user }
        mentioned_users.reject!{ |user| previous_message_user_ids.include?(user.id) }
        mentioned_users.uniq!
        send_messages(
          sender: @source.user, users: mentioned_users,
          action: :mention,
          messagable: @source)

        if @action == :create
          compact_messagable_users = @source.issue.compact_messagable_users
          compact_messagable_users = compact_messagable_users.where.not(id: @source.user)
          compact_messagable_users = compact_messagable_users.where.not(id: messagable_users)
          compact_messagable_users = compact_messagable_users.where.not(id: previous_message_user_ids)
          send_messages(
            sender: @source.user, users: compact_messagable_users,
            messagable: @source, action: :create)
        end
      end
    when Issue
      if @action == :create
        users = @source.group.issue_create_messagable_users.where.not(id: @sender.id)
        send_messages(
          sender: @sender, users: users, messagable: @source,
          action: :create)
      elsif @source.previous_changes["title"].present?
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
    when Event
      return if @source.post.blank?
      roll_call = @options[:roll_call]
      return if roll_call.blank?

      if %i(invite rsvp_schedule rsvp_location).include? @action
        send_messages(
          sender: @sender, users: [roll_call.user],
          messagable: @source,
          action: @action)
      elsif %i(accept reject hold).include? @action
        return if roll_call.inviter.blank?
        send_messages(
          sender: @sender, users: [roll_call.inviter],
          messagable: @source,
          action: @action)
      end
    end
  end

  private

  def send_messages(sender:, users:, messagable:, action: nil, action_params: nil)
    users.each do |user|
      row = { messagable: messagable, sender: sender, user: user, action: action, action_params: action_params.try(:to_json) }
      message = Message.create(row)
      FcmJob.perform_async(message.id) if message.fcm_pushable?
    end
  end
end

