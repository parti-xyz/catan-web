class Invitation < ActiveRecord::Base
  belongs_to :user
  belongs_to :recipient, class_name: User
  belongs_to :joinable, polymorphic: true
  has_many :messages, as: :messagable, dependent: :destroy

  validates :recipient, uniqueness: { scope: [:joinable_id, :joinable_type] }, if: 'recipient.present?'
  validates :joinable, presence: true
  validates :user, presence: true
  scope :of_group, -> (group) {
    where.any_of(
      Invitation.where(joinable_type: 'Issue', joinable_id: Issue.of_group(group)),
      Invitation.where(joinable_type: 'Group', joinable_id: group.id)
    )
  }

  def issue
    joinable if joinable_type == 'Issue'
  end

  def sender_of_message(message)
    user
  end

  def issue_for_message
    issue
  end

  def group_for_message
    joinable if joinable_type == 'Group'
  end

  def recipient_email
    read_attribute(:recipient_email) || recipient.try(:email)
  end

  def self.messagable_group_method
    :of_group
  end
end
