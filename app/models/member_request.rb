class MemberRequest < ActiveRecord::Base
  include UniqueSoftDeletable
  acts_as_unique_paranoid

  belongs_to :user
  belongs_to :issue
  has_many :messages, as: :messagable

  validates :user, presence: true
  validates :issue, presence: true
  validates :user, uniqueness: {scope: :issue}

  scope :recent, -> { order(id: :desc) }

  def issue_for_message
    issue
  end
end
