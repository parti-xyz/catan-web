module Mentionable
  extend ActiveSupport::Concern
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers

  included do
    has_many :mentions, as: :mentionable, dependent: :destroy
    has_many :mentioned_users, through: :mentions, source: :user
    cattr_accessor(:mentionable_fields)
  end

  class_methods do
    def mentionable(*args)
      self.mentionable_fields ||= []
      self.mentionable_fields += args
      self.mentionable_fields.uniq.compact
    end
  end

  def perform_messages_with_mentions_async(action)
    return if self.try(:issue).try(:blind_user?, self.user)
    MentionJob.perform_async(self.class.model_name, self.id, action)
  end

  def perform_messages_with_mentions_now(action)
    return if self.try(:issue).try(:blind_user?, self.user)

    # Transaction을 걸지 않습니다
    set_mentions
    mention_mail_limit = 500
    send_mention_emails if self.mentions.count <= mention_mail_limit
    MessageService.new(self, action: action.to_sym).call()
  end

  private

  def set_mentions
    pervious = self.mentions.destroy_all
    scan_users.map do |mentioned_user|
      self.mentions.build(user: mentioned_user)
      self.messages.where(user: mentioned_user).update_all(action: :mention)
    end
    self.save
  end

  def send_mention_emails
    return if self.try(:issue).try(:blind_user?, self.user)

    mailing_users = []
    mailing_users += self.mentions.map(&:user)
    mailing_users.reject!{ |user| user == self.user }
    mailing_users.reject!{ |user| self.messages.select(:user_id).map(&:user_id).include?(user.id) }
    mailing_users.uniq!

    mailing_users.each do |mentioned_user|
      MentionMailer.notify(self.user.id, mentioned_user.id, self.id, self.class.model_name.to_s).deliver_later
    end
  end

  def scan_users
    users = scan_nicknames.map { |nickname| User.find_by_nickname(nickname) }.compact
    users.reject{ |u| u == try(:user) }
  end

  def scan_nicknames
    @scan_nicknames ||= (self.mentionable_fields || []).map do |field|
      parse(field)
    end.flatten.compact.uniq
  end

  def parse(field)
    return [] if try(field).blank?
    result = begin
      ApplicationController.helpers.strip_tags(send(field)).scan(User::AT_NICKNAME_REGEX).flatten
    end
    result = result.uniq

    member_users = self.try(:issue).try(:member_users) || []
    result = member_users.map(&:nickname) if result.include?('all') and self.try(:issue).try(:member?, self.user)
    result
  end
end
