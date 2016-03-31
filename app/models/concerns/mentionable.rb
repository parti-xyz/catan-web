module Mentionable
  extend ActiveSupport::Concern

  included do
    after_save :set_mentions
    has_many :mentions, as: :mentionable
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
    pervious = self.mentions.destroy_all
    pervious_user = pervious.map &:user
    scan_users.each do |mentioned_user|
      mention = self.mentions.create(user: mentioned_user)
      unless pervious_user.include? mentioned_user
        MentionMailer.send(self.class.to_s.underscore, self.user.id, mentioned_user.id, self.id).deliver_later
        MessageService.new(mention).call
      end
    end
  end

  private

  def scan_users
    (self.mentionable_fields || []).map do |field|
      parse(field)
    end.flatten.compact.uniq
  end

  private

  PATTERN = /(?:^|\s)@([\w]+)/
  PATTERN_WITH_AT = /(?:^|\s)(@[\w]+)/
  HTML_PATTERN_WITH_AT = /(?:^|\s|>)(@[\w]+)/

  def parse(field)
    return [] if try(field).blank?
    result = begin
      send(field).scan(PATTERN).flatten
    end

    users = result.uniq.map { |nickname| User.find_by_nickname(nickname) }.compact
    users.reject{ |u| u == try(:user) }
  end
end
