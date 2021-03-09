class MessageConfiguration::IssueObservation < ApplicationRecord
  include MessageObservationConfigurable

  belongs_to :user
  belongs_to :issue

  validates :user, uniqueness: { scope: [ :issue_id ] }

  def self.of(user, issue)
    return if user.blank? || issue.blank?

    find_or_initialize_by(user_id: user.id, issue_id: issue.id)
  end

  def parent
    MessageConfiguration::GroupObservation.of(user, issue.group)
  end
end
