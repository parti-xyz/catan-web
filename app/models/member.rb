class Member < ApplicationRecord
  include UniqueSoftDeletable
  acts_as_unique_paranoid
  include Messagable

  belongs_to :user
  belongs_to :joinable, counter_cache: true, polymorphic: true
  belongs_to :admit_user, optional: true
  has_many :audiences, dependent: :destroy

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
  scope :read, -> { where.not(read_at: nil) }

  scoped_search relation: :user, on: [:nickname]
  scoped_search relation: :user, on: [:nickname, :email], profile: :admin

  after_create :init_group_push_notification_preference

  def issue
    joinable if joinable_type == 'Issue'
  end

  def group
    joinable if joinable_type == 'Group'
  end

  def post_for_message
    nil
  end

  def issue_for_message
    issue
  end

  def group_for_message
    group || issue&.group
  end

  # DEPRECATED
  def deprecated_unread_issue_by_last_stroked_at?(last_stroked_at)
    return false unless joinable_type == 'Issue'
    return false unless self.marked_read_at?
    return false if self.issue.last_stroked_at.blank?

    self.read_at < last_stroked_at
  end

  def unread_issue?
    self.deprecated_unread_issue_by_last_stroked_at?(self.issue.last_stroked_at)
  end

  def read_issue!
    return unless joinable_type == 'Issue'
    self.touch(:read_at)
  end

  def self.of_group_for_message(group)
    self.of_group(group)
  end

  def marked_read_at?
    self.read_at.present?
  end

  private

  def init_group_push_notification_preference
    if self.joinable_type == 'Group' and !self.joinable.open_square?
      if !joinable.group_push_notification_preferences.exists?(user: self.user)
        joinable.group_push_notification_preferences.create(user: self.user)
      end
    end
  end
end
