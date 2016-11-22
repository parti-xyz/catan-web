class MergedIssue < ActiveRecord::Base
  belongs_to :issue
  belongs_to :user

  validates :source_id, uniqueness: true
end
