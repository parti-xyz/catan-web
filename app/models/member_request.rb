class MemberRequest < ApplicationRecord
  include UniqueSoftDeletable
  acts_as_unique_paranoid

  belongs_to :user
  belongs_to :joinable, polymorphic: true
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, presence: true
  validates :joinable, presence: true
  validates :user, uniqueness: {scope: [:joinable_id, :joinable_type]}
  scope :recent, -> { order(id: :desc) }
  scope :of_group, -> (group) {
    where(joinable_type: 'Issue', joinable_id: Issue.of_group(group))
    .or(where(joinable_type: 'Group', joinable_id: group.id))
  }

  def issue_for_message
    joinable if joinable_type == 'Issue'
  end

  def group_for_message
    joinable if joinable_type == 'Group'
  end

  def self.messagable_group_method
    :of_group
  end
end
