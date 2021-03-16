class Invitation < ApplicationRecord
  include Messagable

  attr_accessor :recipient_code

  belongs_to :user
  belongs_to :recipient, class_name: "User", optional: true
  belongs_to :joinable, polymorphic: true

  validates :recipient, uniqueness: { scope: [:joinable_id, :joinable_type] }, if: -> { recipient.present? }
  validates :joinable, presence: true
  validates :user, presence: true
  validates :recipient_email,
    presence: true,
    format: { with: Devise.email_regexp },
    uniqueness: { scope: [:joinable_id, :joinable_type] }, if: -> { recipient_email.present? }
  validate :validate_not_member
  validate :validate_recipient

  scope :of_group, -> (group) {
    where(joinable_type: 'Issue', joinable_id: Issue.of_group(group))
      .or(where(joinable_type: 'Group', joinable_id: group.id))
  }

  before_save :friendly_token
  before_validation :setup_recipient_data_from_recipient_code

  def issue
    joinable if joinable_type == 'Issue'
  end

  def sender_of_message(_)
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

  def self.of_group_for_message(group)
    of_group(group)
  end

  def not_member?
    !joinable.members.where(user: User.where(email: recipient_email)).exists?
  end

  private

  def friendly_token(length = 20)
    # To calculate real characters, we must perform this operation.
    # See SecureRandom.urlsafe_base64
    rlength = (length * 3) / 4
    self.token = SecureRandom.urlsafe_base64(rlength).tr('lIO0', 'sxyz')
  end

  def setup_recipient_data_from_recipient_code
    if email_recipient_code?
      self.recipient_email = recipient_code
    else
      user = User.find_by(nickname: recipient_code)
      self.recipient = user
      self.recipient_email = user&.email
    end
  end

  def validate_recipient
    return if email_recipient_code?

    if recipient.blank?
      errors.add(:recipient_code, "#{recipient_code}이란 닉네임을 가진 계정이 없습니다.")
      return
    end

    if recipient_email.blank?
      errors.add(:recipient_code, "#{recipient_code} 계정에 이메일 정보가 없습니다. 이메일을 직접 넣어 주세요.")
    end
  end

  def email_recipient_code?
    recipient_code&.match(/@/)
  end

  def validate_not_member
    return if not_member?

    errors.add(:recipient_code, "이미 가입한 멤버입니다.")
  end
end
