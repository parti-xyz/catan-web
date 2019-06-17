class GroupPushNotificationPreference < ApplicationRecord
  belongs_to :user
  belongs_to :group

  validates :user, uniqueness: { scope: :group_id }, presence: true
end
