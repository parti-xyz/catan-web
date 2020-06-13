class IssueReader < ApplicationRecord
  belongs_to :user
  belongs_to :issue

  validates :user, uniqueness: { scope: :issue_id }, presence: true

  VALID_PERIOD = 1.month

  def self.valid_period last_stroked_at
    last_stroked_at > PostReader::VALID_PERIOD.ago
  end
end
