class SendMessage < ActiveInteraction::Base
  include AfterCommitEverywhere

  interface :source
  object :sender, class: User
  symbol :action
  hash :options, default: nil

  validates :source, presence: true
  validates :sender, presence: true
  validates :action, presence: true

  def execute
    return if source.issue_for_message&.blind_user?(sender) || source.issue_for_message&.blind_user?(sender)

    receivers = User.where.not(id: sender.id)
    action_params = {}

    case action
    when :upvote
      receivers = receivers.where(id: source.upvotable.user_id)
    when :mention
      receivers = receivers.where.not(id: source.user_id)

      mentions_user_ids = source.mentions.select(:user_id)
      receivers = receivers.where(id: mentions_user_ids)

      previous_message_user_ids = source.messages.select(:user_id)
      receivers = receivers.where.not(id: previous_message_user_ids)
    when :create_comment, :create_post
      mentions_user_ids = source.mentions.select(:user_id)
      receivers = receivers.where.not(id: mentions_user_ids)

      previous_message_user_ids = source.messages.select(:user_id)
      receivers = receivers.where.not(id: previous_message_user_ids)
    when :update_comment, :update_post
      # receivers = User.none
      return
    when :pin_post, :create_issue
      # receivers = receivers
    when :update_issue_title
      # receivers = receivers
      action_params = { previous_title: source.previous_changes['title'][0] }
    when :ban_issue_member,
         :ban_group_member,
         :admit_issue_member,
         :admit_group_member,
         :assign_issue_organizer,
         :assign_group_organizer,
         :force_default_issue
      receivers = receivers.where(id: source.user_id)
    when :create_issue_organizer,
         :create_group_organizer
      receivers = receivers.where(id: (options&.fetch(:old_organizer_members){}.presence || source.joinable.organizer_members.select(:user_id)))
      receivers = receivers.where.not(id: source.user_id)
      action_params = {
        new_organizer_user_id: source.user.id,
        new_organizer_user_nickname: source.user.nickname
      }
    when :create_issue_member,
         :create_group_member
      receivers = receivers.where(id: source.joinable.organizer_members.select(:user_id))
    when :accept_issue_member_request,
         :accept_group_member_request,
         :reject_issue_member_request,
         :reject_group_member_request
      receivers = receivers.where(id: source.user_id)
    when :create_issue_member_request,
         :create_group_member_request
      receivers = receivers.where(id: source.joinable.organizer_members.select(:user_id))
    when :closed_survey
      return if source.post.blank?
      # receivers = receivers
    when :create_announcement
      receivers = receivers.where(id: source.smart_need_to_notice_members.select(:user_id))
    else
      error = StandardError.new("BAD MESSAGE ACTION : #{action}")
      error.set_backtrace(caller)
      ExceptionNotifier.notify_exception(errors)
      return
    end

    send_messages(receivers, action_params)
  end

  private

  def send_messages(receivers, action_params = nil)
    Rails.logger.debug("action ---------------- #{action}")
    bulk_session = SecureRandom.hex(16)

    receivers.observing_message(source, action, MessageObservationConfigurable.all_subscribing_payoffs).find_in_batches(batch_size: 100).each do |users|
      ActiveRecord::Base.transaction do
        messages = []
        users.each do |user|
          messages << Message.new(messagable: source, sender: sender, user: user, action: action, action_params: action_params.try(:to_json), bulk_session: bulk_session)
        end
        Message.import messages, on_duplicate_key_ignore: true

        after_commit do
          Message.where(bulk_session: bulk_session).where(user_id: User.observing_message(source, action, MessageObservationConfigurable.all_app_push_payoffs)).each_with_index do |message, index|
            FcmJob.perform_at((2 * index).seconds.from_now, message.id)
          end

          Message.where(bulk_session: bulk_session).update_all(bulk_session: nil)
        end
      end
    end
  end
end

