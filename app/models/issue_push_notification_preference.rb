class IssuePushNotificationPreference < ApplicationRecord
  extend Enumerize
  enumerize :value, in: [:highlight, :compact, :detail, :nothing], predicates: true, scope: true

  # :nothing
  # highlight 동일하게 메시지는 쌓임
  # 다만 푸쉬는 나가지 않음

  belongs_to :user
  belongs_to :issue

  scope :not_detail_or_compact_value, ->{ where.not(value: %w(detail compact)) }
  scope :not_detail_value, ->{ where.not(value: 'detail') }

  validates :user, uniqueness: { scope: :issue_id }, presence: true

  def self.pushable_notification?(someone, message)
    return if message.messagable.issue_for_message.blank?
    issue_push_notification_preference = someone.issue_push_notification_preferences.find_by(issue: message.messagable.issue_for_message)
    return true if issue_push_notification_preference.blank?
    return issue_push_notification_preference.value != :nothing
  end
end
