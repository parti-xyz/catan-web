module Mentionable
  extend ActiveSupport::Concern
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers

  included do
    before_save :set_mentions
    after_commit :send_mention_emails
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

  def set_mentions
    return if self.try(:issue).try(:blind_user?, self.user)

    @pervious_user = []
    pervious = self.mentions.destroy_all
    @pervious_user = pervious.map &:user
    scan_users.map do |mentioned_user|
      self.mentions.build(user: mentioned_user)
    end

    if has_parti?
      push_to_slack(self)
    end
  end

  def send_mention_emails
    return if self.try(:issue).try(:blind_user?, self.user)
    return if @pervious_user.nil?

    self.mentions.each do |mention|
      mentioned_user = mention.user
      unless @pervious_user.include? mentioned_user
        MentionMailer.notify(self.user.id, mentioned_user.id, self.id, self.class.model_name.to_s).deliver_later
      end
    end
  end

  private

  def has_parti?
    scan_nicknames.include?('parti')
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
    result = (self.try(:issue).try(:member_users) || []).map(&:nickname) if result.include?('all') and self.try(:issue).try(:member?, self.user)
    result
  end

  def push_to_slack(comment)
    @webhook_url ||= ENV['MENTION_SLACK_WEBHOOK_URL']
    return if @webhook_url.blank?

    notifier = Slack::Notifier.new(@webhook_url, username: 'parti-catan')

    if comment.body.present?
      notifier.ping("@#{comment.user.nickname}님의 댓글 #{polymorphic_url(comment.post)}", attachments: [{ text: comment.body, color: "#36a64f" }])
    end
  end
end
