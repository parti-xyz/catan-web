class IssuePushNotificationPreference < ApplicationRecord
  extend Enumerize
  enumerize :value, in: [:highlight, :detail, :nothing], predicates: true, scope: true

  belongs_to :user
  belongs_to :issue

  validates :user, uniqueness: { scope: :issue_id }, presence: true

  def enable?(message)
    IssuePushNotificationPreference.default_enable?(message, self.value)
  end

  def self.default_enable?(message, value = 'highlight')
    case value
    when 'nothing'
      return false
    when 'highlight'
      return message.highlight?
    else
      return true
    end
  end
end
