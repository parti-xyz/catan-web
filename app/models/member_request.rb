class MemberRequest < ActiveRecord::Base
  include UniqueSoftDeletable
  acts_as_unique_paranoid

  belongs_to :user
  belongs_to :joinable, polymorphic: true
  has_many :messages, as: :messagable

  validates :user, presence: true
  validates :joinable, presence: true
  validates :user, uniqueness: {scope: [:joinable_id, :joinable_type]}
  scope :recent, -> { order(id: :desc) }

  def issue_for_message
    joinable if joinable_type == 'Issue'
  end

  def group_for_message
    joinable if joinable_type == 'Group'
  end
end
