class MessageConfiguration::IssueObservation < ApplicationRecord
  include MessageObservationConfigurable

  belongs_to :user
  belongs_to :issue

  validates :user, uniqueness: { scope: [ :issue_id ] }

  def self.of(user, issue)
    user.issue_observations.find_or_initialize_by(user_id: user.id, issue_id: issue.id) if user.present? && issue.present?
  end

  def parent
    MessageConfiguration::GroupObservation.of(user, issue.group)
  end
end
