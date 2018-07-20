class MergedIssue < ApplicationRecord
  belongs_to :issue, optional: true
  belongs_to :user, optional: true

  validates :source_id, uniqueness: true
end
