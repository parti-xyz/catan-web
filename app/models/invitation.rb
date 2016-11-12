class Invitation < ActiveRecord::Base
  belongs_to :user
  belongs_to :recipient, class_name: User
  belongs_to :issue
  has_many :messages, as: :messagable, dependent: :destroy

  validates :user, uniqueness: { scope: :recipient_id }, presence: true
  validates :recipient, presence: true
  validates :issue, presence: true
end
