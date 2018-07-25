class Member < ApplicationRecord
  include UniqueSoftDeletable
  acts_as_unique_paranoid

  belongs_to :user
  belongs_to :joinable, counter_cache: true, polymorphic: true
  has_many :messages, as: :messagable, dependent: :destroy
  belongs_to :admit_user, optional: true

  validates :user, presence: true
  validates :joinable, presence: true, on: :update
  validates :user, uniqueness: {scope: [:joinable_id, :joinable_type]}

  scope :latest, -> { after(1.day.ago) }
  scope :recent, -> { order(created_at: :desc).order(id: :desc) }
  scope :previous_of_recent, ->(member) {
    base = recent
    base = base.where('members.created_at <= ?', member.created_at) if member.present?
    base = base.where('id < ?', member.id) if member.present?
    base
  }
  scope :for_issues, -> { where(joinable_type: 'Issue') }
  scope :of_group, -> (group) {
    where(joinable_type: 'Issue', joinable_id: Issue.of_group(group))
    .or(where(joinable_type: 'Group', joinable_id: group.id))
  }

  scoped_search relation: :user, on: [:nickname]
  scoped_search relation: :user, on: [:nickname, :email], profile: :admin

  def issue
    joinable if joinable_type == 'Issue'
  end

  def issue_for_message
    issue
  end

  def group_for_message
    joinable if joinable_type == 'Group'
  end

  def self.messagable_group_method
    :of_group
  end
end
