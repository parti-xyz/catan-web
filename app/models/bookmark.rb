class Bookmark < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue

  validates :user, uniqueness: { scope: :issue_id }, presence: true
  validates :issue, presence: true
end
