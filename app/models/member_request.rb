class MemberRequest < ApplicationRecord
  include UniqueSoftDeletable
  acts_as_unique_paranoid
  include Messagable

  belongs_to :user
  belongs_to :joinable, polymorphic: true

  validates :user, presence: true
  validates :joinable, presence: true
  validates :user, uniqueness: {scope: [:joinable_id, :joinable_type]}
  scope :recent, -> { order(id: :desc) }
  scope :of_group, -> (group) {
    where(joinable_type: 'Issue', joinable_id: Issue.of_group(group))
    .or(where(joinable_type: 'Group', joinable_id: group.id))
  }

  def issue
    joinable if joinable_type == 'Issue'
  end

  def group
    joinable if joinable_type == 'Group'
  end

  def issue_for_message
    issue
  end

  def group_for_message
    group || issue&.group
  end

  def self.of_group_for_message(group)
    self.of_group(group)
  end
end
