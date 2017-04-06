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

  def perform_mentions_async
    return if self.try(:issue).try(:blind_user?, self.user)
    MentionJob.perform_async(self.class.model_name, self.id)
  end

  def perform_mentions_now
    return if self.try(:issue).try(:blind_user?, self.user)

    previous_mentioned_users = self.mentioned_users.to_a
    # Transaction을 걸지 않습니다
    set_mentions
    mention_mail_limit = 500
    send_mention_emails(previous_mentioned_users) if self.mentions.count <= mention_mail_limit
    MessageService.new(self).call(previous_mentioned_users: previous_mentioned_users)
  end

  private

  def set_mentions
    pervious = self.mentions.destroy_all
    scan_users.map do |mentioned_user|
      self.mentions.build(user: mentioned_user)
    end
    self.save
  end

  def send_mention_emails(previous_mentioned_users)
    return if self.try(:issue).try(:blind_user?, self.user)

    self.mentions.each do |mention|
      mentioned_user = mention.user
      unless previous_mentioned_users.include? mentioned_user
        MentionMailer.notify(self.user.id, mentioned_user.id, self.id, self.class.model_name.to_s).deliver_later
      end
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
